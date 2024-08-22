package br.com.suamusica.player

import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.PowerManager
import android.support.v4.media.session.PlaybackStateCompat
import android.util.Log
import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.common.MediaMetadata.PICTURE_TYPE_FRONT_COVER
import androidx.media3.common.PlaybackException
import androidx.media3.common.PlaybackParameters
import androidx.media3.common.Player
import androidx.media3.common.Player.DISCONTINUITY_REASON_SEEK
import androidx.media3.common.Timeline
import androidx.media3.common.Tracks
import androidx.media3.common.util.UnstableApi
import androidx.media3.common.util.Util
import androidx.media3.datasource.DataSource
import androidx.media3.datasource.DataSourceBitmapLoader
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.datasource.FileDataSource
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.hls.HlsMediaSource
import androidx.media3.exoplayer.source.ProgressiveMediaSource
import androidx.media3.session.CacheBitmapLoader
import androidx.media3.session.MediaController
import androidx.media3.session.MediaSession
import androidx.media3.session.MediaSessionService
import br.com.suamusica.player.media.parser.SMHlsPlaylistParserFactory
import com.bumptech.glide.Glide
import com.bumptech.glide.load.engine.DiskCacheStrategy
import com.bumptech.glide.request.FutureTarget
import com.bumptech.glide.request.RequestOptions
import com.google.common.util.concurrent.ListenableFuture
import kotlinx.coroutines.DelicateCoroutinesApi
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.ByteArrayOutputStream
import java.io.File
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean

@UnstableApi
class MediaService : MediaSessionService() {
    private val TAG = "MediaService"
    private val userAgent =
        "SuaMusica/player (Linux; Android ${Build.VERSION.SDK_INT}; ${Build.BRAND}/${Build.MODEL})"
    private var packageValidator: PackageValidator? = null
    private var media: Media? = null
    private var isForegroundService = false
    private var wifiLock: WifiManager.WifiLock? = null
    private var wakeLock: PowerManager.WakeLock? = null
    var mediaSession: MediaSession? = null
    private var mediaController: ListenableFuture<MediaController>? = null

    private val uAmpAudioAttributes =
        AudioAttributes.Builder().setContentType(C.AUDIO_CONTENT_TYPE_MUSIC).setUsage(C.USAGE_MEDIA)
            .build()

    private var player: ExoPlayer? = null

    private var progressTracker: ProgressTracker? = null

    private var previousState: Int = -1

    private lateinit var dataSourceBitmapLoader: DataSourceBitmapLoader

    companion object {
        private val glideOptions = RequestOptions().fallback(R.drawable.default_art)
            .diskCacheStrategy(DiskCacheStrategy.AUTOMATIC).timeout(5000)

        private const val NOTIFICATION_LARGE_ICON_SIZE = 500 // px
        private const val LOCAL_COVER_PNG = "../app_flutter/covers/0.png" // px

        @OptIn(DelicateCoroutinesApi::class)
        fun getArts(context: Context, artUri: String?, callback: (Bitmap) -> Unit) {
            GlobalScope.launch(Dispatchers.IO) {
                Log.i("getArts", " artUri: $artUri")
                val glider = Glide.with(context).applyDefaultRequestOptions(glideOptions).asBitmap()
                val file = File(context.filesDir, LOCAL_COVER_PNG)
                lateinit var bitmap: Bitmap
                val futureTarget: FutureTarget<Bitmap>? = when {
                    !artUri.isNullOrBlank() -> glider.load(artUri)
                        .submit(NOTIFICATION_LARGE_ICON_SIZE, NOTIFICATION_LARGE_ICON_SIZE)

                    file.exists() -> glider.load(Uri.fromFile(file))
                        .submit(NOTIFICATION_LARGE_ICON_SIZE, NOTIFICATION_LARGE_ICON_SIZE)

                    else -> null
                }

                if (futureTarget != null) {
                    bitmap = try {
                        futureTarget.get()
                    } catch (e: Exception) {
                        Log.i("getArts", "ART EXCP: $e")
                        if (file.exists()) {
                            BitmapFactory.decodeFile(file.absolutePath)
                        } else {
                            BitmapFactory.decodeResource(context.resources, R.drawable.default_art)
                        }
                    }
                }
                withContext(Dispatchers.Main) {
                    callback(bitmap)
                }
            }
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "onStartCommand")
        super.onStartCommand(intent, flags, startId)
        return Service.START_STICKY

    }

    override fun onCreate() {
        super.onCreate()
        packageValidator = PackageValidator(applicationContext, R.xml.allowed_media_browser_callers)
        wifiLock =
            (applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager).createWifiLock(
                WifiManager.WIFI_MODE_FULL_HIGH_PERF, "suamusica:wifiLock"
            )
        wakeLock =
            (applicationContext.getSystemService(Context.POWER_SERVICE) as PowerManager).newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK or PowerManager.ON_AFTER_RELEASE,
                "suamusica:wakeLock"
            )
        wifiLock?.setReferenceCounted(false)
        wakeLock?.setReferenceCounted(false)

        player = ExoPlayer.Builder(this).build().apply {
            setAudioAttributes(uAmpAudioAttributes, true)
            addListener(playerEventListener())
            // setWakeMode(C.WAKE_MODE_NETWORK)
            setHandleAudioBecomingNoisy(true)
        }

        dataSourceBitmapLoader =
            DataSourceBitmapLoader(applicationContext)
        player?.let {
            mediaSession = MediaSession.Builder(this, it)
                .setBitmapLoader(CacheBitmapLoader(dataSourceBitmapLoader))
                .setCallback(MediaButtonEventHandler(this))
                .build()
        }
    }

    override fun onGetSession(
        controllerInfo: MediaSession.ControllerInfo
    ): MediaSession? = mediaSession

    override fun onTaskRemoved(rootIntent: Intent?) {
        Log.d(TAG, "onTaskRemoved")
        super.onTaskRemoved(rootIntent)

        /**
         * By stopping playback, the player will transition to [Player.STATE_IDLE]. This will
         * cause a state change in the MediaSession, and (most importantly) call
         * [MediaControllerCallback.onPlaybackStateChanged]. Because the playback state will
         * be reported as [PlaybackStateCompat.STATE_NONE], the service will first remove
         * itself as a foreground service, and will then call [stopSelf].
         */
        player?.stop()
        stopService()
    }

    override fun onDestroy() {
        removeNotification()
        Log.d(TAG, "onDestroy")
        releaseLock()
        player?.release()
        stopSelf()

        mediaSession?.run {
            releaseAndPerformAndDisableTracking()
            Log.d("MusicService", "onDestroy")
        }

        releasePossibleLeaks()
        super.onDestroy()

    }

    private fun releasePossibleLeaks() {
        player?.release()
        packageValidator = null
        mediaSession = null
        mediaController = null
        wifiLock = null
        wakeLock = null

    }

    private fun acquireLock(duration: Long) {
        wifiLock?.acquire()
        wakeLock?.acquire(duration)
    }

    private fun releaseLock() {
        try {
            if (wifiLock?.isHeld == true) wifiLock?.release()
            if (wakeLock?.isHeld == true) wakeLock?.release()
        } catch (e: Exception) {
            Log.e("MusicService", e.message, e)
        }
    }

    fun prepare(cookie: String, media: Media) {
        this.media = media
        val dataSourceFactory = DefaultHttpDataSource.Factory()
        dataSourceFactory.setReadTimeoutMs(15 * 1000)
        dataSourceFactory.setConnectTimeoutMs(10 * 1000)
        dataSourceFactory.setUserAgent(userAgent)
        dataSourceFactory.setAllowCrossProtocolRedirects(true)
        dataSourceFactory.setDefaultRequestProperties(mapOf("Cookie" to cookie))
        val metadata = buildMetaData(media)
        val url = media.url
        Log.i(TAG, "Player: URL: $url")

        val uri = if (url.startsWith("/")) Uri.fromFile(File(url)) else Uri.parse(url)
        val mediaItem = MediaItem.Builder().setUri(uri).setMediaMetadata(metadata).build()
        @C.ContentType val type = Util.inferContentType(uri)
        Log.i(TAG, "Player: Type: $type HLS: ${C.CONTENT_TYPE_HLS}")
        val source = when (type) {
            C.CONTENT_TYPE_HLS -> HlsMediaSource.Factory(dataSourceFactory)
                .setPlaylistParserFactory(SMHlsPlaylistParserFactory())
                .setAllowChunklessPreparation(true).createMediaSource(mediaItem)

            C.CONTENT_TYPE_OTHER -> {
                Log.i(TAG, "Player: URI: $uri")
                val factory: DataSource.Factory =
                    if (uri.scheme != null && uri.scheme?.startsWith("http") == true) {
                        dataSourceFactory
                    } else {
                        FileDataSource.Factory()
                    }

                ProgressiveMediaSource.Factory(factory).createMediaSource(mediaItem)
            }

            else -> {
                throw IllegalStateException("Unsupported type: $type")
            }
        }
        player?.pause()
        player?.prepare(source)
    }

    private fun buildMetaData(media: Media): MediaMetadata {
        val metadataBuilder = MediaMetadata.Builder()

        if (media.isFavorite != null) {
            mediaSession?.sessionExtras?.putBoolean(
                PlayerPlugin.IS_FAVORITE_ARGUMENT,
                media.isFavorite
            )
        }
        val stream = ByteArrayOutputStream()

        val art = try {
            dataSourceBitmapLoader.loadBitmap(Uri.parse(media.bigCoverUrl!!))
                .get(5000, TimeUnit.MILLISECONDS)
        } catch (e: Exception) {
            Log.d("Player", "TESTE1 catch")
            var bitmapFallback: Bitmap? = null
            getArts(applicationContext, media.bigCoverUrl) { bitmap ->
                bitmapFallback = bitmap
            }
            bitmapFallback
        }

        art?.compress(Bitmap.CompressFormat.PNG, 95, stream)
        metadataBuilder.apply {
            setAlbumTitle(media.name)
            setArtist(media.author)
            setArtworkData(stream.toByteArray(), PICTURE_TYPE_FRONT_COVER)
            setArtist(media.author)
            setTitle(media.name)
            setDisplayTitle(media.name)
        }
        val metadata = metadataBuilder.build()
        return metadata
    }

    //    }
    fun play() {
        performAndEnableTracking {
            player?.play()
        }
    }

    fun removeNotification() {
        player?.removeMediaItem(0);
    }

    fun seek(position: Long, playWhenReady: Boolean) {
        player?.seekTo(position)
        player?.playWhenReady = playWhenReady
    }

    fun pause() {
        performAndDisableTracking {
            player?.pause()
        }
    }

    fun stop() {
        performAndDisableTracking {
            player?.stop()
        }
    }

    fun togglePlayPause() {
        performAndDisableTracking {
            if (player?.isPlaying == true) {
                player?.pause()
            } else {
                player?.play()
            }
        }
    }

    fun releaseAndPerformAndDisableTracking() {
        performAndDisableTracking {
            player?.stop()
        }
    }

//    private fun removeNowPlayingNotification() {
//        Log.d(TAG, "removeNowPlayingNotification")
//        Thread(Runnable {
//            notificationManager?.cancel(NOW_PLAYING_NOTIFICATION)
//        }).start()
//
//    }


    private fun notifyPositionChange() {
        var position = player?.currentPosition ?: 0L
        val duration = player?.duration ?: 0L
        position = if (position > duration) duration else position

        if (duration > 0) {
            val extra = Bundle()
            extra.putString("type", "position")
            extra.putLong("position", position)
            extra.putLong("duration", duration)
            mediaSession?.setSessionExtras(extra)
        }
    }

    private fun startTrackingProgress() {
        if (progressTracker != null) {
            return
        }
        this.progressTracker = ProgressTracker(Handler())
    }

    private fun stopTrackingProgress() {
        progressTracker?.stopTracking()
        progressTracker = null
    }

    private fun stopTrackingProgressAndPerformTask(callable: () -> Unit) {
        if (progressTracker != null) {
            progressTracker!!.stopTracking(callable)
        } else {
            callable()
        }
        progressTracker = null
    }

    private fun performAndEnableTracking(callable: () -> Unit) {
        callable()
        startTrackingProgress()
    }

    private fun performAndDisableTracking(callable: () -> Unit) {
        callable()
        stopTrackingProgress()
    }

    private fun playerEventListener(): Player.Listener {
        return object : Player.Listener {
            override fun onTimelineChanged(timeline: Timeline, reason: Int) {
                Log.i(TAG, "onTimelineChanged: timeline: $timeline reason: $reason")
            }

            override fun onTracksChanged(tracks: Tracks) {
                Log.i(TAG, "onTracksChanged: ")
            }

            override fun onPositionDiscontinuity(
                oldPosition: Player.PositionInfo,
                newPosition: Player.PositionInfo,
                reason: Int
            ) {
                Log.i(TAG, "onPositionDiscontinuity: $reason")
                if (reason == DISCONTINUITY_REASON_SEEK) {
                    val bundle = Bundle()
                    bundle.putString("type", "seek-end")
                    mediaSession?.setSessionExtras(bundle)
                }
            }

            override fun onIsPlayingChanged(isPlaying: Boolean) {
                super.onIsPlayingChanged(isPlaying)
                if (isPlaying) {
                    val duration = player?.duration ?: 0L
                    acquireLock(
                        if (duration > 1L) duration + TimeUnit.MINUTES.toMillis(2) else TimeUnit.MINUTES.toMillis(
                            3
                        )
                    )
                } else
                    releaseLock()
            }

            override fun onPlaybackStateChanged(playbackState: Int) {
                super.onPlaybackStateChanged(playbackState)
                if (playbackState == Player.STATE_READY) {
                    if (previousState == -1) {
                        // when we define that the track shall not "playWhenReady"
                        // no position info is sent
                        // therefore, we need to "emulate" the first position notification
                        // by sending it directly
                        notifyPositionChange()
                    } else {
                        stopTrackingProgressAndPerformTask {}
                    }
                }
               else if(playbackState == Player.STATE_ENDED) {
                    stopTrackingProgressAndPerformTask {}
                }
                previousState = playbackState
            }

            override fun onRepeatModeChanged(repeatMode: Int) {
                Log.i(TAG, "onRepeatModeChanged: $repeatMode")
            }

            override fun onShuffleModeEnabledChanged(shuffleModeEnabled: Boolean) {
                Log.i(TAG, "onShuffleModeEnabledChanged: $shuffleModeEnabled")
            }

            override fun onPlayerError(error: PlaybackException) {
                Log.e(TAG, "onPLayerError: ${error.message}", error)
                val bundle = Bundle()
                bundle.putString("type", "error")
                bundle.putString(
                    "error",
                    if (error.cause.toString()
                            .contains("Permission denied")
                    ) "Permission denied" else error.message
                )
                mediaSession?.setSessionExtras(bundle)
            }

            override fun onPlaybackParametersChanged(playbackParameters: PlaybackParameters) {
                Log.i(TAG, "onPlaybackParametersChanged: $playbackParameters")
            }
        }
    }

    private inner class ProgressTracker(val handler: Handler) : Runnable {
        private val shutdownRequest = AtomicBoolean(false)
        private var shutdownTask: (() -> Unit)? = null

        init {
            handler.post(this)
        }

        override fun run() {
            notifyPositionChange()

            if (!shutdownRequest.get()) {
                handler.postDelayed(this, 800 /* ms */)
            } else {
                shutdownTask?.let {
                    it()
                }
            }
        }

        fun stopTracking() {
            shutdownRequest.set(true)
        }

        fun stopTracking(callable: () -> Unit) {
            shutdownTask = callable
            stopTracking()
        }
    }

    private fun stopService() {
        if (isForegroundService) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                stopForeground(STOP_FOREGROUND_DETACH)
            } else {
                stopForeground(false)
            }
            isForegroundService = false
            stopSelf()
            Log.i(TAG, "Stopping Service")
        }
    }
}

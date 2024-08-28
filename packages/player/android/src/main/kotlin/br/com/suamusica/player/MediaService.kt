package br.com.suamusica.player

import android.app.ActivityManager
import android.app.PendingIntent
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
import androidx.media3.session.CommandButton
import androidx.media3.session.DefaultMediaNotificationProvider
import androidx.media3.session.DefaultMediaNotificationProvider.DEFAULT_NOTIFICATION_ID
import androidx.media3.session.MediaController
import androidx.media3.session.MediaNotification
import androidx.media3.session.MediaSession
import androidx.media3.session.MediaSessionService
import androidx.media3.session.SessionCommand
import androidx.media3.session.SessionResult
import br.com.suamusica.player.media.parser.SMHlsPlaylistParserFactory
import com.google.common.collect.ImmutableList
import com.google.common.util.concurrent.ListenableFuture
import java.io.ByteArrayOutputStream
import java.io.File
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean

    const val NOW_PLAYING_CHANNEL: String = "br.com.suamusica.media.NOW_PLAYING"
    const val NOW_PLAYING_NOTIFICATION: Int = 0xb339

@UnstableApi
class MediaService : MediaSessionService() {
    private val TAG = "MediaService"
    private val userAgent =
        "SuaMusica/player (Linux; Android ${Build.VERSION.SDK_INT}; ${Build.BRAND}/${Build.MODEL})"

    //    private var packageValidator: PackageValidator? = null
    private var media: Media? = null
    private var isForegroundService = false

    //    private var wifiLock: WifiManager.WifiLock? = null
//    private var wakeLock: PowerManager.WakeLock? = null
    lateinit var mediaSession: MediaSession
    private var mediaController: ListenableFuture<MediaController>? = null

    private val uAmpAudioAttributes =
        AudioAttributes.Builder().setContentType(C.AUDIO_CONTENT_TYPE_MUSIC).setUsage(C.USAGE_MEDIA)
            .build()

    private var player: ExoPlayer? = null

    private var progressTracker: ProgressTracker? = null

    private var previousState: Int = -1

    private lateinit var dataSourceBitmapLoader: DataSourceBitmapLoader
    private lateinit var mediaButtonEventHandler: MediaButtonEventHandler
    private var customMedia3Notification: MediaNotification? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "onStartCommand")
        super.onStartCommand(intent, flags, startId)
        return Service.START_STICKY
    }

    private fun getPendingIntent(): PendingIntent {
        val notifyIntent = Intent("SUA_MUSICA_FLUTTER_NOTIFICATION_CLICK").apply {
            addCategory(Intent.CATEGORY_APP_MUSIC)
            flags =
                Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }

        return PendingIntent.getActivity(
            applicationContext,
            0,
            notifyIntent,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT else PendingIntent.FLAG_UPDATE_CURRENT
        )
    }

    override fun onCreate() {
        super.onCreate()
        mediaButtonEventHandler = MediaButtonEventHandler(this)
//        packageValidator = PackageValidator(applicationContext, R.xml.allowed_media_browser_callers)
//        wifiLock =
//            (applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager).createWifiLock(
//                WifiManager.WIFI_MODE_FULL_HIGH_PERF, "suamusica:wifiLock"
//            )
//        wakeLock =
//            (applicationContext.getSystemService(Context.POWER_SERVICE) as PowerManager).newWakeLock(
//                PowerManager.PARTIAL_WAKE_LOCK or PowerManager.ON_AFTER_RELEASE,
//                "suamusica:wakeLock"
//            )
//        wifiLock?.setReferenceCounted(false)
//        wakeLock?.setReferenceCounted(false)

        player = ExoPlayer.Builder(this).build().apply {
            setAudioAttributes(uAmpAudioAttributes, true)
            addListener(playerEventListener())
            setWakeMode(C.WAKE_MODE_NETWORK)
            setHandleAudioBecomingNoisy(true)
        }

        dataSourceBitmapLoader =
            DataSourceBitmapLoader(applicationContext)

        Log.d(TAG, "MEDIA3 - handleCustomCommand ${Build.VERSION_CODES.TIRAMISU}")
        player?.let {
            mediaSession = MediaSession.Builder(this, it)
                .setBitmapLoader(CacheBitmapLoader(dataSourceBitmapLoader))
                .setCallback(mediaButtonEventHandler)
                .setSessionActivity(getPendingIntent())
                .setId("SM_NOW_PLAYING")
                .build()
            this@MediaService.setMediaNotificationProvider(object : MediaNotification.Provider {

                override fun createNotification(
                    mediaSession: MediaSession,
                    customLayout: ImmutableList<CommandButton>,
                    actionFactory: MediaNotification.ActionFactory,
                    onNotificationChangedCallback: MediaNotification.Provider.Callback
                ): MediaNotification {
                    Log.d(TAG, "#MEDIA3# - createNotification | ${mediaSession.id}")
                    val defaultMediaNotificationProvider =
                        DefaultMediaNotificationProvider(applicationContext,
//                        DefaultMediaNotificationProvider(
//                            applicationContext,
//                            { R.string.notification_id },
//                            NOW_PLAYING_CHANNEL,
//                            R.string.notification_channel
                        ).apply {
                                setSmallIcon(R.drawable.ic_notification)
                            }

                    customMedia3Notification =
                        defaultMediaNotificationProvider.createNotification(
                            mediaSession,
                            mediaSession.customLayout,
                            actionFactory,
                            onNotificationChangedCallback,
                        )

                    return MediaNotification(
                        NOW_PLAYING_NOTIFICATION,
                        customMedia3Notification!!.notification
                    )
                }

                override fun handleCustomCommand(
                    session: MediaSession,
                    action: String,
                    extras: Bundle
                ): Boolean {
                    Log.d(TAG, "#MEDIA3# - handleCustomCommand $action")
                    return false
                }
            })
        }
    }

    override fun onGetSession(
        controllerInfo: MediaSession.ControllerInfo
    ): MediaSession = mediaSession

    override fun onTaskRemoved(rootIntent: Intent?) {
//        val player = mediaSession?.player!!
//        val a = !player.playWhenReady
//                || player.mediaItemCount == 0
//                || player.playbackState == Player.STATE_ENDED
//        Log.d(TAG, "#MEDIA3# - onTaskRemoved $a")
//        if (a) {
//            // Stop the service if not playing, continue playing in the background
//            // otherwise.
//            stopSelf()
//        }
        isServiceRunning()
    }

    override fun onDestroy() {
        mediaSession?.run {
            releaseAndPerformAndDisableTracking()
            player.release()
            release()
            mediaSession.release()
        }
        releaseLock()
        releasePossibleLeaks()
        stopSelf()
        super.onDestroy()
    }

    private fun releasePossibleLeaks() {
        player?.release()
//        packageValidator = null
        mediaSession.release()
        mediaController = null
//        wifiLock = null
//        wakeLock = null
    }

    private fun acquireLock(duration: Long) {
//        wifiLock?.acquire()
//        wakeLock?.acquire(duration)
    }


    private fun isServiceRunning(): Boolean {
        val manager = getSystemService(ACTIVITY_SERVICE) as ActivityManager
        for (service in manager.getRunningServices(Int.MAX_VALUE)) {
            if ("br.com.suamusica.player.MediaService" == service.service.className) {
                return true
            }
        }
        return false
    }

    fun shouldStartService() {
//        Log.e(TAG, "#MEDIA3# shouldStartService $isForegroundService | ${customMedia3Notification == null}")
//        val intent = Intent(applicationContext, this@MediaService.javaClass)
//        if (!isForegroundService) {
//            if (Build.VERSION.SDK_INT >= 26) {
//                applicationContext.startForegroundService(intent)
////                setForegroundServiceBehavior()
////                startService(intent)
//            } else {
//                applicationContext.startService(intent)
//            }
//            if(customMedia3Notification!=null){
//            startForeground(NOW_PLAYING_NOTIFICATION, customMedia3Notification!!.notification)
//            }
//            isForegroundService = true
//        }
        val a = isServiceRunning()
        Log.e(TAG, "#MEDIA3# isServiceRunning $a")
    }

    private fun releaseLock() {
//        try {
//            if (wifiLock?.isHeld == true) wifiLock?.release()
//            if (wakeLock?.isHeld == true) wakeLock?.release()
//        } catch (e: Exception) {
//            Log.e("MusicService", e.message, e)
//        }
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
        player?.setMediaSource(source)
//        player?.addMediaSource(source)
        player?.prepare()
    }

    private fun buildMetaData(media: Media): MediaMetadata {
        val metadataBuilder = MediaMetadata.Builder()

        if (media.isFavorite != null) {
            mediaSession.sessionExtras.putBoolean(
                PlayerPlugin.IS_FAVORITE_ARGUMENT,
                media.isFavorite
            )
        }
        val stream = ByteArrayOutputStream()

        val art = try {
            dataSourceBitmapLoader.loadBitmap(Uri.parse(media.bigCoverUrl!!))
                .get(5000, TimeUnit.MILLISECONDS)
        } catch (e: Exception) {
            BitmapFactory.decodeResource(resources, R.drawable.default_art)
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

    fun play() {
        performAndEnableTracking {
            player?.play()
        }
    }

    //    fun adsPlaying() {
//        val oldItem = player!!.currentMediaItem!!
//        val newItem = oldItem
//            .buildUpon().setMediaMetadata(
//                oldItem.mediaMetadata.buildUpon()
//                    .setTitle("Propaganda")
//                    .setDescription("Propaganda")
//                    .build()
//            )
//            .build()
//        player!!.replaceMediaItem(0, newItem)
//        player!!.prepare()
//    }
    fun removeNotification() {
//         player?.stop()
//        shouldStartService()
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
        if (player?.isPlaying == true) {
            pause()
        } else {
            play()
        }
    }

    private fun releaseAndPerformAndDisableTracking() {
        performAndDisableTracking {
            player?.stop()
        }
    }


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
                    shouldStartService()
                }
//                    shouldStartService()
//                    val duration = player?.duration ?: 0L
//                    acquireLock(
//                        if (duration > 1L) duration + TimeUnit.MINUTES.toMillis(2) else TimeUnit.MINUTES.toMillis(
//                            3
//                        )
//                    )
//                } else {
//                    stopService()
//                    releaseLock()
//                }
            }

            //
//            override fun onPlaybackStateChanged(playbackState: Int) {
//                super.onPlaybackStateChanged(playbackState)
//                if (playbackState == Player.STATE_READY) {
//                    if (previousState == -1) {
//                        // when we define that the track shall not "playWhenReady"
//                        // no position info is sent
//                        // therefore, we need to "emulate" the first position notification
//                        // by sending it directly
//                        notifyPositionChange()
//                    } else {
//                        stopTrackingProgressAndPerformTask {}
//                    }
//                } else if (playbackState == Player.STATE_ENDED) {
//                    stopTrackingProgressAndPerformTask {}
//                }
//                previousState = playbackState
//            }
            override fun onPlayerStateChanged(playWhenReady: Boolean, playbackState: Int) {
                isServiceRunning()
                Log.i(
                    TAG,
                    "onPlayerStateChanged: playWhenReady: $playWhenReady playbackState: $playbackState currentPlaybackState: ${player?.playbackState} ServiceRunning: ${isServiceRunning()}"
                )
                if (playWhenReady) {
                    val duration = player?.duration ?: 0L
                    acquireLock(
                        if (duration > 1L) duration + TimeUnit.MINUTES.toMillis(2) else TimeUnit.MINUTES.toMillis(
                            3
                        )
                    )
                } else {
//                    releaseLock()
                }

                if (playWhenReady && playbackState == ExoPlayer.STATE_READY) {
                    //
                } else {
                    if (player?.playerError != null) {
                        //
                    } else {
                        when (playbackState) {
                            ExoPlayer.STATE_IDLE -> { // 1
                                //
                            }


                            ExoPlayer.STATE_BUFFERING -> { // 2
                                //
                            }

                            ExoPlayer.STATE_READY -> { // 3
                                val status =
                                    if (playWhenReady) PlayerState.PLAYING else PlayerState.PAUSED
                                if (previousState == -1) {
                                    // when we define that the track shall not "playWhenReady"
                                    // no position info is sent
                                    // therefore, we need to "emulate" the first position notification
                                    // by sending it directly
                                    notifyPositionChange()
                                } else {
                                    if (status == PlayerState.PAUSED) {
                                        stopTrackingProgressAndPerformTask {
                                            //
                                        }
                                    } else {
                                        //
                                    }

                                }
                            }

                            ExoPlayer.STATE_ENDED -> { // 4
                                stopTrackingProgressAndPerformTask {
                                    //
                                }
                            }
                        }
                    }
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

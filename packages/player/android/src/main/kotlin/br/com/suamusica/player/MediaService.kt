package br.com.suamusica.player

import android.annotation.SuppressLint
import android.app.Notification
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import android.net.Uri
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.PowerManager
import android.support.v4.media.MediaMetadataCompat
import android.support.v4.media.session.MediaControllerCompat
import android.support.v4.media.session.MediaSessionCompat
import android.support.v4.media.session.PlaybackStateCompat
import android.util.Log
import androidx.core.content.ContextCompat
import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.common.MediaMetadata.PICTURE_TYPE_FRONT_COVER
import androidx.media3.common.PlaybackException
import androidx.media3.common.PlaybackParameters
import androidx.media3.common.Player
import androidx.media3.common.Player.Commands
import androidx.media3.common.Player.DISCONTINUITY_REASON_SEEK
import androidx.media3.common.Timeline
import androidx.media3.common.Tracks
import androidx.media3.common.util.NotificationUtil
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
import androidx.media3.session.MediaController
import androidx.media3.session.MediaLibraryService
import androidx.media3.session.MediaNotification
import androidx.media3.session.MediaSession
import androidx.media3.session.MediaSessionService
import androidx.media3.session.SessionCommand
import androidx.media3.ui.PlayerNotificationManager
import br.com.suamusica.player.media.parser.SMHlsPlaylistParserFactory
import com.bumptech.glide.Glide
import com.bumptech.glide.load.engine.DiskCacheStrategy
import com.bumptech.glide.request.FutureTarget
import com.bumptech.glide.request.RequestOptions
import com.google.common.collect.ImmutableList
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
class MediaService : MediaSessionService(),  MediaLibraryService.MediaLibrarySession.Callback {
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

    private val BROWSABLE_ROOT = "/"
    private val EMPTY_ROOT = "@empty@"
    private lateinit var notificationBuilder: NotificationBuilder
    private lateinit var dataSourceBitmapLoader: DataSourceBitmapLoader
    private lateinit var defaultMediaNotificationProvider: DefaultMediaNotificationProvider
    private lateinit var actionFactory: MediaNotification.ActionFactory

    companion object {
        private val glideOptions = RequestOptions().fallback(R.drawable.default_art)
            .diskCacheStrategy(DiskCacheStrategy.AUTOMATIC).timeout(5000)

        private const val NOTIFICATION_LARGE_ICON_SIZE = 500 // px
        private const val LOCAL_COVER_PNG = "../app_flutter/covers/0.png" // px

        @kotlin.OptIn(DelicateCoroutinesApi::class)
        fun getArts(context: Context, artUri: String?, callback: (Bitmap?) -> Unit) {
            GlobalScope.launch(Dispatchers.IO) {
                Log.i("getArts", " artUri: $artUri")
                val glider = Glide.with(context).applyDefaultRequestOptions(glideOptions).asBitmap()
                val file = File(context.filesDir, LOCAL_COVER_PNG)
                var bitmap: Bitmap? = null
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
                            null
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

//        val sessionActivityPendingIntent =
//            this.packageManager?.getLaunchIntentForPackage(this.packageName)?.let { sessionIntent ->
//                PendingIntent.getActivity(this, 0, sessionIntent, PendingIntent.FLAG_IMMUTABLE)
//            }
//        val mediaButtonReceiver = ComponentName(this, MediaButtonReceiver::class.java)
//        mediaSession = mediaSession?.let { it }
//            ?: MediaSessionCompat(this, TAG, mediaButtonReceiver, null)
//                .apply {
//                    setSessionActivity(sessionActivityPendingIntent)
//                    isActive = true
//                }
//        mediaSession?.setFlags(MediaSessionCompat.FLAG_HANDLES_QUEUE_COMMANDS)
        player = ExoPlayer.Builder(this).build().apply {
            setAudioAttributes(uAmpAudioAttributes, true)
            addListener(playerEventListener())
            // setWakeMode(C.WAKE_MODE_NETWORK)
            setHandleAudioBecomingNoisy(true)
        }
        notificationBuilder = NotificationBuilder(applicationContext)

        dataSourceBitmapLoader =
            DataSourceBitmapLoader(applicationContext)
        player?.let {
            mediaSession = MediaSession.Builder(this, it)
//                .setCustomLayout(
//                    ImmutableList.of(
//                        CommandButton.Builder()
//                            .setDisplayName("Save to favorites")
//                            .setIconResId(R.drawable.ic_favorite_notification_player)
//                            .setSessionCommand(SessionCommand("favoritar", Bundle()))
//
//                            .build(),
//                        CommandButton.Builder()
//                            .setDisplayName("previous")
//                            .setIconResId(R.drawable.ic_prev_notification_player)
//                            .setSessionCommand(SessionCommand("previous", Bundle.EMPTY))
//                            .build(),
//                        CommandButton.Builder()
//                            .setDisplayName("next")
//                            .setIconResId(R.drawable.ic_next_notification_player)
//                            .setSessionCommand(SessionCommand("next", Bundle.EMPTY))
//                            .build(),
//
//                    ),
//                )
                .setBitmapLoader(CacheBitmapLoader(dataSourceBitmapLoader))
                .setCallback(MediaButtonEventHandler(this))
                .build()


//            this@MediaService.setMediaNotificationProvider(object : MediaNotification.Provider {
//                override fun createNotification(
//                    mediaSession: MediaSession,
//                    customLayout: ImmutableList<CommandButton>,
//                    actionFactory: MediaNotification.ActionFactory,
//                    onNotificationChangedCallback: MediaNotification.Provider.Callback
//                ): MediaNotification {
//
//                    val media3NotificationManual =
//                        DefaultMediaNotificationProvider(applicationContext)
//                    val media3NotificationManualNot = media3NotificationManual.createNotification(
//                        mediaSession,
//                        customLayout,
//                        actionFactory,
//                        onNotificationChangedCallback,
//                    )
//                    val oldNotification = notificationBuilder.buildNotification(
//                        mediaSession,
//                        media,
//                        onGoing = true,
//                        isPlayingExternal = false,
//                        isFavorite = false,
//                        mediaDuration = mediaSession.player.duration,
//                        art = null
//                    )
////                    return MediaNotification(NOW_PLAYING_NOTIFICATION, buildNotification())
//                    return media3NotificationManualNot
//                }
//
//
//                override fun handleCustomCommand(
//                    session: MediaSession, action: String, extras: Bundle
//                ): Boolean {
//                    Log.d(TAG, "TESTE1 - handleCustomCommand3 $action")
//                    if (action == "play") {
//                        PlayerSingleton.play()
//                    }
//                    if (action == "pause") {
//                        PlayerSingleton.pause()
//                    }
//                    if (action == "previous") {
//                        PlayerSingleton.previous()
//                    }
//                    if (action == "next") {
//                        PlayerSingleton.next()
//                    }
//                    if (action == "seek") {
//                        seek(extras.getLong("position"), extras.getBoolean("playWhenReady"))
//                    }
//                    if (action == "favoritar") {
//                        Log.d(
//                            "Player",
//                            "TESTE1 Favoritar: ${extras.getBoolean(PlayerPlugin.IS_FAVORITE_ARGUMENT)} | ${session.player.mediaMetadata.extras}"
//                        )
//                        val shouldFavorite =
//                            session.player.mediaMetadata.extras?.getBoolean(PlayerPlugin.IS_FAVORITE_ARGUMENT)
//                                ?: false
//                        PlayerSingleton.favorite(!shouldFavorite)
//                        session.player.mediaMetadata.extras?.putBoolean(
//                            PlayerPlugin.IS_FAVORITE_ARGUMENT,
//                            !shouldFavorite
//                        )
//                        buildSetCustomLayout(session, !shouldFavorite, this@MediaService)
//                    }
//                    return true
//                }
//            })
        }


//        mediaSession?.let { mediaSession ->
//            val sessionToken = mediaSession.sessionToken
//            // we must connect the service to the media session
//            this.sessionToken = sessionToken
//
//            val mediaControllerCallback = MediaControllerCallback()
//
//            mediaController = MediaControllerCompat(this, sessionToken).also { mediaController ->
//                mediaController.registerCallback(mediaControllerCallback)
//
//                mediaSessionConnector = MediaSessionConnector(mediaSession).also { connector ->
//                    connector.setPlayer(player)
//                    connector.setPlaybackPreparer(MusicPlayerPlaybackPreparer(this))
//                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
//                        if (Build.MANUFACTURER.equals("samsung", ignoreCase = true)) {
//                            connector.setCustomActionProviders(
//                                FavoriteModeActionProvider(applicationContext),
//                                NextActionProvider(),
//                                PreviousActionProvider(),
//                            )
//                        } else {
//                            connector.setCustomActionProviders(
//                                FavoriteModeActionProvider(applicationContext),
//                                PreviousActionProvider(),
//                                NextActionProvider(),
//                            )
//                        }
//                    }
//                    connector.setMediaButtonEventHandler(MediaButtonEventHandler())
//                    connector.setEnabledPlaybackActions(
//                        PlaybackStateCompat.ACTION_PLAY
//                                or PlaybackStateCompat.ACTION_PAUSE
//                                or PlaybackStateCompat.ACTION_REWIND
//                                or PlaybackStateCompat.ACTION_FAST_FORWARD
//                                or PlaybackStateCompat.ACTION_SEEK_TO
//                    )
//                }
//            }
//        }
    }

    override fun onGetSession(
        controllerInfo: MediaSession.ControllerInfo
    ): MediaSession? = mediaSession


    @OptIn(UnstableApi::class)
    private fun buildNotification() {
        val notificationManager =
            PlayerNotificationManager.Builder(applicationContext, 111, NOW_PLAYING_CHANNEL)
                .setChannelImportance(NotificationUtil.IMPORTANCE_HIGH)
                .setSmallIconResourceId(R.drawable.ic_notification)
                .setPauseActionIconResourceId(R.drawable.ic_pause_notification_player)
                .setPlayActionIconResourceId(R.drawable.ic_play_notification_player)
                .setChannelDescriptionResourceId(R.string.app_name)
                .setChannelNameResourceId(R.string.app_name)
                .build()

        notificationManager.apply {
            this.setUseRewindAction(false)
            this.setUseFastForwardAction(false)
            this.setUsePreviousAction(false)
            this.setUseNextAction(false)
            this.setUsePlayPauseActions(true)
            this.setUseFastForwardActionInCompactView(true)
            this.setPlayer(player)
            this.setColor(Color.RED)
            this.setColorized(true)
        }
    }
    override fun onTaskRemoved(rootIntent: Intent) {
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
        Log.d(TAG, "onDestroy")
//        mediaController?.unregisterCallback(mediaControllerCallback)
        releaseLock()
//        mediaSessionConnector?.setPlayer(null)
        player?.release()
        stopSelf()

        mediaSession?.run {
            player.release()
            release()
            mediaSession = null
        }

        releasePossibleLeaks()
        super.onDestroy()

    }

    private fun releasePossibleLeaks() {
        player?.release()
        packageValidator = null
        mediaSession = null
        mediaController = null
//        mediaSessionConnector = null
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

//    override fun onGetRoot(
//        clientPackageName: String,
//        clientUid: Int,
//        rootHints: Bundle?
//    ): BrowserRoot? {
//        val isKnowCaller = packageValidator?.isKnownCaller(clientPackageName, clientUid) ?: false
//
//        return if (isKnowCaller) {
//            BrowserRoot(BROWSABLE_ROOT, null)
//        } else {
//            BrowserRoot(EMPTY_ROOT, null)
//        }
//    }
//
//    override fun onLoadChildren(
//        parentId: String,
//        result: Result<MutableList<MediaBrowserCompat.MediaItem>>
//    ) {
//        result.sendResult(mutableListOf())
//    }

    fun prepare(cookie: String, media: Media) {
        this.media = media
        val dataSourceFactory = DefaultHttpDataSource.Factory()
        dataSourceFactory.setReadTimeoutMs(15 * 1000)
        dataSourceFactory.setConnectTimeoutMs(10 * 1000)
        dataSourceFactory.setUserAgent(userAgent)
        dataSourceFactory.setAllowCrossProtocolRedirects(true)
        dataSourceFactory.setDefaultRequestProperties(mapOf("Cookie" to cookie))
        // Metadata Build
        val metadataBuilder = MediaMetadata.Builder()
        val bundle = Bundle()
        bundle.putBoolean(PlayerPlugin.IS_FAVORITE_ARGUMENT, media.isFavorite ?: false)
        bundle.putString(PlayerPlugin.URL_ARGUMENT, media.url ?: "")
        val art = try {
            dataSourceBitmapLoader.loadBitmap(Uri.parse(media.bigCoverUrl!!))
                .get(5000, TimeUnit.MILLISECONDS)
        } catch (e: Exception) {
            Log.d("Player", "TESTE1 catch")
            BitmapFactory.decodeResource(resources, R.drawable.default_art)
        }
        val stream = ByteArrayOutputStream()
        art.compress(Bitmap.CompressFormat.PNG, 95, stream)
        metadataBuilder.apply {
            setAlbumTitle(media.name)
            setArtist(media.author)
            setArtworkData(stream.toByteArray(), PICTURE_TYPE_FRONT_COVER)
//            setArtworkUri(Uri.parse(media.bigCoverUrl))

            setArtist(media.author)
            setTitle(media.name)
            setDisplayTitle(media.name)
            setExtras(bundle)
        }
        val metadata = metadataBuilder.build()
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
        player?.play()
        Log.d("Player", "sendNotification")
    }

    //    }
    fun play() {
        performAndEnableTracking {
            player?.play()
        }
    }

    fun adsPlaying() {
        Log.i(TAG, "TESTE2 - adsPlaying")
        getArts(applicationContext, null) { bitmap ->
            this.media = Media("Propaganda", "", "", "", null, null)
            val metadataBuilder = MediaMetadata.Builder()
            metadataBuilder.apply {
                setArtist("Propaganda")
                setTitle("Propaganda")
                setDisplayTitle("Propaganda")
            }
            val url =
                player?.mediaMetadata?.extras?.getString(PlayerPlugin.URL_ARGUMENT) ?: ""
            val uri = if (url.startsWith("/")) Uri.fromFile(File(url)) else Uri.parse(url)
            val adsMedia =
                MediaItem.Builder().setMediaMetadata(metadataBuilder.build()).setUri(uri).build()

            player?.replaceMediaItem(0, adsMedia)
//            shouldStartService(it)
            }
        }



    fun setFavorite(favorite: Boolean?) {
        media?.let {
            this.media = Media(it.name, it.author, it.url, it.coverUrl, it.bigCoverUrl, favorite)
            sendNotification(this.media!!, null)
        }
    }

    fun sendNotification(media: Media, isPlayingExternal: Boolean?) {
        getArts(applicationContext, media.bigCoverUrl ?: media.coverUrl) { bitmap ->
            mediaSession?.let {
                val onGoing: Boolean = if (isPlayingExternal == null) {
                    val state = player?.playbackState ?: PlaybackStateCompat.STATE_NONE
                    state == PlaybackStateCompat.STATE_PLAYING || state == PlaybackStateCompat.STATE_BUFFERING
                } else {
                    isPlayingExternal
                }
                this.media = media


//                val notification = notificationBuilder?.buildNotification(
//                    it,
//                    media,
//                    onGoing,
//                    isPlayingExternal,
//                    media.isFavorite,
//                    player?.duration, bitmap
//                )
//                notification?.let {
//                    notificationManager?.notify(NOW_PLAYING_NOTIFICATION, notification)
//                }
            }
        }
    }

//    fun removeNotification() {
//        removeNowPlayingNotification();
//    }

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

    fun release() {
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

            override fun onLoadingChanged(isLoading: Boolean) {
                Log.i(TAG, "onLoadingChanged: isLoading: $isLoading")
            }

            override fun onPlayerStateChanged(playWhenReady: Boolean, playbackState: Int) {
                Log.i(
                    TAG,
                    "onPlayerStateChanged: playWhenReady: $playWhenReady playbackState: $playbackState currentPlaybackState: ${player?.playbackState}"
                )
                if (playWhenReady) {
                    val duration = player?.duration ?: 0L
                    acquireLock(
                        if (duration > 1L) duration + TimeUnit.MINUTES.toMillis(2) else TimeUnit.MINUTES.toMillis(
                            3
                        )
                    )
                } else releaseLock()

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

            override fun onPositionDiscontinuity(reason: Int) {
                Log.i(TAG, "onPositionDiscontinuity: $reason")
                if (reason == DISCONTINUITY_REASON_SEEK) {
                    val bundle = Bundle()
                    bundle.putString("type", "seek-end")
                    mediaSession?.setSessionExtras(bundle)
                }

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

//    fun shouldStartService() {
//        if (!isForegroundService) {
//            Log.i(TAG, "Starting Service")
//            try {
//                ContextCompat.startForegroundService(
//                    applicationContext, Intent(applicationContext, this@MediaService.javaClass)
//                )
//                startForeground(NOW_PLAYING_NOTIFICATION, notification)
//            } catch (e: Exception) {
//                startForeground(NOW_PLAYING_NOTIFICATION, notification)
//                ContextCompat.startForegroundService(
//                    applicationContext, Intent(applicationContext, this@MediaService.javaClass)
//                )
//            }
//            isForegroundService = true
//
//        }
//    }

    fun stopService() {
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

    private inner class MediaControllerCallback : MediaControllerCompat.Callback() {
        override fun onMetadataChanged(metadata: MediaMetadataCompat?) {
//            Log.d(
//                TAG, "onMetadataChanged: title: ${metadata?.title} duration: ${metadata?.duration}"
//            )
        }

        override fun onPlaybackStateChanged(state: PlaybackStateCompat?) {
            Log.d(TAG, "onPlaybackStateChanged1 state: $state")
            updateNotification(state!!)
        }

        override fun onQueueChanged(queue: MutableList<MediaSessionCompat.QueueItem>?) {
            Log.d(TAG, "onQueueChanged queue: $queue")
        }

        @SuppressLint("WakelockTimeout")
        private fun updateNotification(state: PlaybackStateCompat) {
            Log.d(TAG, "TESTE1 updateNotification")
            if (mediaSession == null) {
                return
            }
            getArts(applicationContext, media?.bigCoverUrl ?: media?.coverUrl) { bitmap ->
                val updatedState = state.state
                val onGoing =
                    updatedState == PlaybackStateCompat.STATE_PLAYING || updatedState == PlaybackStateCompat.STATE_BUFFERING
                // Skip building a notification when state is "none".
//                val notification = if (updatedState != PlaybackStateCompat.STATE_NONE) {
//                    buildNotification(updatedState, onGoing, bitmap)
//                } else {
//                    null
//                }
                Log.d(TAG, "!!! updateNotification state: $updatedState $onGoing")

                when (updatedState) {
                    PlaybackStateCompat.STATE_BUFFERING, PlaybackStateCompat.STATE_PLAYING -> {
                        Log.i(TAG, "updateNotification: STATE_BUFFERING or STATE_PLAYING")
                        /**
                         * This may look strange, but the documentation for [Service.startForeground]
                         * notes that "calling this method does *not* put the service in the started
                         * state itself, even though the name sounds like it."
                         */
//                        if (notification != null) {
//                            notificationManager?.notify(NOW_PLAYING_NOTIFICATION, notification)
//                            shouldStartService(notification)
//                        }
                    }

                    else -> {
                        if (isForegroundService) {
                            // If playback has ended, also stop the service.
                            if (updatedState == PlaybackStateCompat.STATE_NONE && Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
                                stopService()
                            }
//                            if (notification != null) {
//                                notificationManager?.notify(
//                                    NOW_PLAYING_NOTIFICATION,
//                                    notification
//                                )
//                            } else
//                                removeNowPlayingNotification()
                        }
                    }
                }
            }
        }
    }
}

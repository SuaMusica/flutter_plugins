package br.com.suamusica.player

import android.annotation.SuppressLint
import android.app.Notification
import android.app.PendingIntent
import android.app.Service
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.net.Uri
import android.net.wifi.WifiManager
import android.os.*
import android.support.v4.media.MediaBrowserCompat
import android.support.v4.media.MediaDescriptionCompat
import android.support.v4.media.MediaMetadataCompat
import android.support.v4.media.session.MediaControllerCompat
import android.support.v4.media.session.MediaSessionCompat
import android.support.v4.media.session.PlaybackStateCompat
import android.util.Log
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import androidx.media.session.MediaButtonReceiver
import br.com.suamusica.player.media.parser.SMHlsPlaylistParserFactory
import com.google.android.exoplayer2.*
import com.google.android.exoplayer2.audio.AudioAttributes
import com.google.android.exoplayer2.ext.mediasession.MediaSessionConnector
import com.google.android.exoplayer2.ext.mediasession.TimelineQueueNavigator
import com.google.android.exoplayer2.source.ProgressiveMediaSource
import com.google.android.exoplayer2.source.hls.HlsMediaSource
import com.google.android.exoplayer2.upstream.DataSource
import com.google.android.exoplayer2.upstream.DefaultHttpDataSource
import com.google.android.exoplayer2.upstream.FileDataSource
import com.google.android.exoplayer2.util.Util
import java.io.File
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean

class MediaService : androidx.media.MediaBrowserServiceCompat() {
    private val TAG = "MediaService"
    private val userAgent =
        "SuaMusica/player (Linux; Android ${Build.VERSION.SDK_INT}; ${Build.BRAND}/${Build.MODEL})"
    private var packageValidator: PackageValidator? = null

    private var mediaSession: MediaSessionCompat? = null
    private var mediaController: MediaControllerCompat? = null
    private var mediaSessionConnector: MediaSessionConnector? = null

    private var media: Media? = null

    private var notificationBuilder: NotificationBuilder? = null
    private var notificationManager: NotificationManagerCompat? = null
    private var isForegroundService = false
    private var wifiLock: WifiManager.WifiLock? = null
    private var wakeLock: PowerManager.WakeLock? = null

    private val uAmpAudioAttributes = AudioAttributes.Builder()
        .setContentType(C.AUDIO_CONTENT_TYPE_MUSIC)
        .setUsage(C.USAGE_MEDIA)
        .build()

    private var player: ExoPlayer? = null

    private var progressTracker: ProgressTracker? = null

    private var previousState: Int = -1

    private val BROWSABLE_ROOT = "/"
    private val EMPTY_ROOT = "@empty@"

    enum class MessageType {
        STATE_CHANGE,
        POSITION_CHANGE,
        NEXT,
        PREVIOUS
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "onStartCommand")
        return Service.START_STICKY

    }

    override fun onCreate() {
        super.onCreate()
        packageValidator = PackageValidator(applicationContext, R.xml.allowed_media_browser_callers)
        notificationBuilder = NotificationBuilder(this)
        notificationManager = NotificationManagerCompat.from(this)
        wifiLock = (applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager)
            .createWifiLock(WifiManager.WIFI_MODE_FULL_HIGH_PERF, "suamusica:wifiLock")
        wakeLock = (applicationContext.getSystemService(Context.POWER_SERVICE) as PowerManager)
            .newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK or PowerManager.ON_AFTER_RELEASE,
                "suamusica:wakeLock"
            )
        wifiLock?.setReferenceCounted(false)
        wakeLock?.setReferenceCounted(false)

        val sessionActivityPendingIntent =
            this.packageManager?.getLaunchIntentForPackage(this.packageName)?.let { sessionIntent ->
                PendingIntent.getActivity(this, 0, sessionIntent, PendingIntent.FLAG_IMMUTABLE)
            }

        val mediaButtonReceiver = ComponentName(this, MediaButtonReceiver::class.java)
        mediaSession = mediaSession?.let { it }
            ?: MediaSessionCompat(this, TAG, mediaButtonReceiver, null)
                .apply {
                    setSessionActivity(sessionActivityPendingIntent)
                    isActive = true
                }

        mediaSession?.setFlags(MediaSessionCompat.FLAG_HANDLES_QUEUE_COMMANDS)

        player = ExoPlayer.Builder(this).build().apply {
            setAudioAttributes(uAmpAudioAttributes, true)
            addListener(playerEventListener())
            // setWakeMode(C.WAKE_MODE_NETWORK)
            setHandleAudioBecomingNoisy(true)
        }
        mediaSession?.let { mediaSession ->
            val sessionToken = mediaSession.sessionToken
            // we must connect the service to the media session
            this.sessionToken = sessionToken

            val mediaControllerCallback = MediaControllerCallback()

            mediaController = MediaControllerCompat(this, sessionToken).also { mediaController ->
                mediaController.registerCallback(mediaControllerCallback)

                mediaSessionConnector = MediaSessionConnector(mediaSession).also { connector ->
                    connector.setPlayer(player)
                    connector.setPlaybackPreparer(MusicPlayerPlaybackPreparer(this))
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        connector.setCustomActionProviders(
                            FavoriteModeActionProvider(applicationContext),
                            PreviousActionProvider(),
                            NextActionProvider(),
                        )
                    } else {
                        connector.setMediaButtonEventHandler(MediaButtonEventHandler())
                        connector.setEnabledPlaybackActions(
                            PlaybackStateCompat.ACTION_PLAY
                                    or PlaybackStateCompat.ACTION_PAUSE
                                    or PlaybackStateCompat.ACTION_REWIND
                                    or PlaybackStateCompat.ACTION_FAST_FORWARD
                        )
                    }
                }
            }
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
        player?.stop(true)
        stopService()
    }

    override fun onDestroy() {
        removeNotification()
        Log.d(TAG, "onDestroy")
//        mediaController?.unregisterCallback(mediaControllerCallback)
        releaseLock()
        mediaSessionConnector?.setPlayer(null)
        player?.release()
        stopSelf()

        mediaSession?.run {
            isActive = false
            release()
            Log.d("MusicService", "onDestroy(isActive: $isActive)")
        }

        releasePossibleLeaks()
        super.onDestroy()

    }

    private fun releasePossibleLeaks() {
        player?.release()
        notificationManager = null
        notificationBuilder = null
        packageValidator = null
        mediaSession = null
        mediaController = null
        mediaSessionConnector = null
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

    override fun onGetRoot(
        clientPackageName: String,
        clientUid: Int,
        rootHints: Bundle?
    ): BrowserRoot? {
        val isKnowCaller = packageValidator?.isKnownCaller(clientPackageName, clientUid) ?: false

        return if (isKnowCaller) {
            BrowserRoot(BROWSABLE_ROOT, null)
        } else {
            BrowserRoot(EMPTY_ROOT, null)
        }
    }

    override fun onLoadChildren(
        parentId: String,
        result: Result<MutableList<MediaBrowserCompat.MediaItem>>
    ) {
        result.sendResult(mutableListOf())
    }

    fun prepare(cookie: String, media: Media) {
        this.media = media

        val dataSourceFactory = DefaultHttpDataSource.Factory()
        dataSourceFactory.setReadTimeoutMs(15 * 1000)
        dataSourceFactory.setConnectTimeoutMs(10 * 1000)
        dataSourceFactory.setUserAgent(userAgent)
        dataSourceFactory.setAllowCrossProtocolRedirects(true)
        dataSourceFactory.setDefaultRequestProperties(mapOf("Cookie" to cookie))

        // Metadata Build
        val metadataBuilder = MediaMetadataCompat.Builder()
        val art = NotificationBuilder.getArt(this, media.coverUrl)
        metadataBuilder.apply {
            album = media.author
            albumArt = art
            title = media.name
            displayTitle = media.name
            putString(MediaMetadataCompat.METADATA_KEY_ARTIST, media.author)
            putString(MediaMetadataCompat.METADATA_KEY_DISPLAY_SUBTITLE, media.name)
            putBitmap(MediaMetadataCompat.METADATA_KEY_ART, art)
            putBitmap(MediaMetadataCompat.METADATA_KEY_DISPLAY_ICON, art)
        }
        val metadata = metadataBuilder.build()
        mediaSession?.setMetadata(metadata)
        mediaSessionConnector?.setMediaMetadataProvider {
            return@setMediaMetadataProvider metadata
        }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            val timelineQueueNavigator = object : TimelineQueueNavigator(mediaSession!!) {
                override fun getSupportedQueueNavigatorActions(player: Player): Long {
                    return PlaybackStateCompat.ACTION_SKIP_TO_PREVIOUS or
                            PlaybackStateCompat.ACTION_SKIP_TO_NEXT or
                            PlaybackStateCompat.ACTION_SEEK_TO
                }

                override fun getMediaDescription(
                    player: Player,
                    windowIndex: Int
                ): MediaDescriptionCompat {
                    player.let {
                        return MediaDescriptionCompat.Builder().apply {
                            setTitle(media.author)
                            setSubtitle(media.name)
                            setIconUri(Uri.parse(media.coverUrl))
                        }.build()
                    }
                }
            }
            mediaSessionConnector?.setQueueNavigator(timelineQueueNavigator)
        }
        val url = media.url
        Log.i(TAG, "Player: URL: $url")

        val uri = if (url.startsWith("/")) Uri.fromFile(File(url)) else Uri.parse(url)

        @C.ContentType val type = Util.inferContentType(uri)
        Log.i(TAG, "Player: Type: $type HLS: ${C.TYPE_HLS}")
        val source = when (type) {
            C.TYPE_HLS -> HlsMediaSource.Factory(dataSourceFactory)
                .setPlaylistParserFactory(SMHlsPlaylistParserFactory())
                .setAllowChunklessPreparation(true)
                .createMediaSource(MediaItem.fromUri(uri))
            C.TYPE_OTHER -> {
                Log.i(TAG, "Player: URI: $uri")
                val factory: DataSource.Factory =
                    if (uri.scheme != null && uri.scheme?.startsWith("http") == true) {
                        dataSourceFactory
                    } else {
                        FileDataSource.Factory()
                    }

                ProgressiveMediaSource.Factory(factory).createMediaSource(MediaItem.fromUri(uri))
            }
            else -> {
                throw IllegalStateException("Unsupported type: $type")
            }
        }
        player?.pause()
        player?.prepare(source)
    }

    fun play() {
        performAndEnableTracking {
            player?.play()
        }
    }

    fun sendCommand(type: String) {
        val extra = Bundle()
        extra.putString("type", type)
        mediaSession?.setExtras(extra)

    }

    fun setFavorite(favorite: Boolean?) {
        media?.let {
            this.media = Media(it.name, it.author, it.url, it.coverUrl, favorite)
            sendNotification(this.media!!, null)
        }
    }

    fun sendNotification(media: Media, isPlayingExternal: Boolean?) {
        mediaSession?.let {
            var onGoing: Boolean
            onGoing = if (isPlayingExternal == null) {
                val state = player?.playbackState ?: PlaybackStateCompat.STATE_NONE
                state == PlaybackStateCompat.STATE_PLAYING || state == PlaybackStateCompat.STATE_BUFFERING
            } else {
                isPlayingExternal
            }
            this.media = media
            val notification = notificationBuilder?.buildNotification(
                it,
                media,
                onGoing,
                isPlayingExternal,
                media.isFavorite,
                player?.duration
            )
            notification?.let {
                notificationManager?.notify(NOW_PLAYING_NOTIFICATION, notification)
            }
        }
    }

    fun removeNotification() {
        removeNowPlayingNotification();
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

    fun release() {
        performAndDisableTracking {
            player?.stop()
        }
    }

    private fun removeNowPlayingNotification() {
        Log.d(TAG, "removeNowPlayingNotification")
        Thread(Runnable {
            notificationManager?.cancel(NOW_PLAYING_NOTIFICATION)
        }).start()

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
            mediaSession?.setExtras(extra)
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

    private fun buildNotification(updatedState: Int, onGoing: Boolean): Notification? {
        return if (updatedState != PlaybackStateCompat.STATE_NONE) {
            mediaSession?.let {
                notificationBuilder?.buildNotification(
                    it,
                    media!!,
                    onGoing,
                    null,
                    media!!.isFavorite,
                    player?.duration
                )
            }
        } else {
            null
        }
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
                } else
                    releaseLock()

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
                bundle.putString("error", error.message)
                mediaSession?.setExtras(bundle)
            }

            override fun onPositionDiscontinuity(reason: Int) {
                Log.i(TAG, "onPositionDiscontinuity: $reason")
            }

            override fun onPlaybackParametersChanged(playbackParameters: PlaybackParameters) {
                Log.i(TAG, "onPlaybackParametersChanged: $playbackParameters")
            }

            override fun onSeekProcessed() {
                Log.i(TAG, "onSeekProcessed")
                val bundle = Bundle()
                bundle.putString("type", "seek-end")
                mediaSession?.setExtras(bundle)
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

    fun shouldStartService(notification: Notification) {
        if (!isForegroundService) {
            Log.i(TAG, "Starting Service")
            try {
                ContextCompat.startForegroundService(
                    applicationContext,
                    Intent(applicationContext, this@MediaService.javaClass)
                )
                startForeground(NOW_PLAYING_NOTIFICATION, notification)
            }  catch (e: Exception) {
                startForeground(NOW_PLAYING_NOTIFICATION, notification)
                ContextCompat.startForegroundService(
                    applicationContext,
                    Intent(applicationContext, this@MediaService.javaClass)
                )
            }
            isForegroundService = true

        }
    }
    fun stopService(){
        if(isForegroundService){
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
            Log.d(
                TAG,
                "onMetadataChanged: title: ${metadata?.title} duration: ${metadata?.duration}"
            )
        }

        override fun onPlaybackStateChanged(state: PlaybackStateCompat?) {
            Log.d(TAG, "onPlaybackStateChanged state: $state")
            updateNotification(state!!)
        }

        override fun onQueueChanged(queue: MutableList<MediaSessionCompat.QueueItem>?) {
            Log.d(TAG, "onQueueChanged queue: $queue")
        }

        @SuppressLint("WakelockTimeout")
        private fun updateNotification(state: PlaybackStateCompat) {
            val updatedState = state.state
            if (mediaController?.metadata == null || mediaSession == null) {
                return
            }

            val onGoing =
                updatedState == PlaybackStateCompat.STATE_PLAYING || updatedState == PlaybackStateCompat.STATE_BUFFERING

            // Skip building a notification when state is "none".
            val notification = if (updatedState != PlaybackStateCompat.STATE_NONE) {
                buildNotification(updatedState, onGoing)
            } else {
                null
            }
            Log.d(TAG, "!!! updateNotification state: $updatedState $onGoing")

            when (updatedState) {
                PlaybackStateCompat.STATE_BUFFERING,
                PlaybackStateCompat.STATE_PLAYING -> {
                    Log.i(TAG, "updateNotification: STATE_BUFFERING or STATE_PLAYING")
                    /**
                     * This may look strange, but the documentation for [Service.startForeground]
                     * notes that "calling this method does *not* put the service in the started
                     * state itself, even though the name sounds like it."
                     */
                    if (notification != null) {
                        notificationManager?.notify(NOW_PLAYING_NOTIFICATION, notification)
                        shouldStartService(notification)
                    }
                }
                else -> {
                    if (isForegroundService) {
                        // If playback has ended, also stop the service.
                        if (updatedState == PlaybackStateCompat.STATE_NONE && Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
                            stopService()
                        }
                        if (notification != null) {
                            notificationManager?.notify(NOW_PLAYING_NOTIFICATION, notification)
                        } else
                            removeNowPlayingNotification()
                    }
                }
            }
        }
    }
}
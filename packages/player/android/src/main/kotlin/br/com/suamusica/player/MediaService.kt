package br.com.suamusica.player

import android.annotation.SuppressLint
import android.app.Notification
import android.app.PendingIntent
import android.app.Service
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.AsyncTask
import android.os.Bundle
import android.os.Handler
import androidx.core.content.ContextCompat
import android.support.v4.media.MediaBrowserCompat
import android.support.v4.media.MediaDescriptionCompat
import android.support.v4.media.MediaMetadataCompat
import android.support.v4.media.session.MediaControllerCompat
import android.support.v4.media.session.MediaSessionCompat
import android.support.v4.media.session.PlaybackStateCompat
import android.util.Log
import androidx.core.app.NotificationManagerCompat
import androidx.media.session.MediaButtonReceiver
import br.com.suamusica.player.media.parser.SMHlsPlaylistParserFactory
import com.google.android.exoplayer2.*
import com.google.android.exoplayer2.audio.AudioAttributes
import com.google.android.exoplayer2.ext.mediasession.MediaSessionConnector
import com.google.android.exoplayer2.ext.mediasession.TimelineQueueNavigator
import com.google.android.exoplayer2.source.ProgressiveMediaSource
import com.google.android.exoplayer2.source.TrackGroupArray
import com.google.android.exoplayer2.source.hls.HlsMediaSource
import com.google.android.exoplayer2.trackselection.TrackSelectionArray
import com.google.android.exoplayer2.upstream.DataSource
import com.google.android.exoplayer2.upstream.DefaultDataSourceFactory
import com.google.android.exoplayer2.upstream.DefaultHttpDataSourceFactory
import com.google.android.exoplayer2.upstream.FileDataSource
import com.google.android.exoplayer2.util.Util
import java.util.concurrent.atomic.AtomicBoolean

class MediaService : androidx.media.MediaBrowserServiceCompat() {
    private val TAG = "Player"

    private var packageValidator: PackageValidator? = null

    private var mediaSession: MediaSessionCompat? = null
    private var mediaController: MediaControllerCompat? = null
    private var mediaSessionConnector: MediaSessionConnector? = null

    private var media: Media? = null

    private var notificationBuilder: NotificationBuilder? = null
    private var notificationManager: NotificationManagerCompat? = null
    private var isForegroundService = false

    private val uAmpAudioAttributes = AudioAttributes.Builder()
            .setContentType(C.CONTENT_TYPE_MUSIC)
            .setUsage(C.USAGE_MEDIA)
            .build()

    private var player: SimpleExoPlayer? = null

    private var progressTracker: ProgressTracker? = null

    private var previousState: Int = -1

    /*



     */


    private val BROWSABLE_ROOT = "/"
    private val EMPTY_ROOT = "@empty@"

    enum class MessageType {
        STATE_CHANGE,
        POSITION_CHANGE,
        NEXT,
        PREVIOUS
    }

    override fun onCreate() {
        super.onCreate()
        packageValidator = PackageValidator(applicationContext, R.xml.allowed_media_browser_callers)
        notificationBuilder = NotificationBuilder(this)
        notificationManager = NotificationManagerCompat.from(this)

        val sessionActivityPendingIntent =
                this.packageManager?.getLaunchIntentForPackage(this.packageName)?.let { sessionIntent ->
                    PendingIntent.getActivity(this, 0, sessionIntent, 0)
                }

        val mediaButtonReceiver = ComponentName(this, MediaButtonReceiver::class.java)
        mediaSession = mediaSession?.let { it }
                ?: MediaSessionCompat(this, TAG, mediaButtonReceiver, null)
                        .apply {
                            setSessionActivity(sessionActivityPendingIntent)
                            isActive = true
                        }

        mediaSession?.setFlags(MediaSessionCompat.FLAG_HANDLES_MEDIA_BUTTONS
                or MediaSessionCompat.FLAG_HANDLES_TRANSPORT_CONTROLS
                or MediaSessionCompat.FLAG_HANDLES_QUEUE_COMMANDS)

        player = SimpleExoPlayer.Builder(this).build().apply {
            setAudioAttributes(uAmpAudioAttributes, true)
            addListener(playerEventListener())
            setWakeMode(C.WAKE_MODE_NETWORK)
            setHandleAudioBecomingNoisy(true)
        }

        mediaSession?.let { mediaSession ->
            val sessionToken = mediaSession.sessionToken

            // we must connect the service to the media session
            this.sessionToken = sessionToken

            val mediaControllerCallback = MediaControllerCallback()

            mediaController = MediaControllerCompat(this, sessionToken).also { mediaController ->
                mediaController.registerCallback(mediaControllerCallback)

                val playbackPreparer = MusicPlayerPlaybackPreparer(
                        this,
                        player!!,
                        mediaController,
                        mediaSession
                )

                mediaSessionConnector = MediaSessionConnector(mediaSession).also { connector ->
                    connector.setPlayer(player)
                    connector.setPlaybackPreparer(playbackPreparer)
                }
            }
        }
    }

    override fun onGetRoot(clientPackageName: String, clientUid: Int, rootHints: Bundle?): BrowserRoot? {
        val isKnowCaller = packageValidator?.isKnownCaller(clientPackageName, clientUid) ?: false

        return if (isKnowCaller) {
            BrowserRoot(BROWSABLE_ROOT, null)
        } else {
            BrowserRoot(EMPTY_ROOT, null)
        }
    }

    override fun onLoadChildren(parentId: String, result: Result<MutableList<MediaBrowserCompat.MediaItem>>) {
        result.sendResult(mutableListOf())
    }

    fun prepare(cookie: String, media: Media) {
        this.media = media
        val defaultHttpDataSourceFactory = DefaultHttpDataSourceFactory("mp.next")
        defaultHttpDataSourceFactory.defaultRequestProperties.set("Cookie", cookie)
        val dataSourceFactory = DefaultDataSourceFactory(this, null, defaultHttpDataSourceFactory)

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

        val timelineQueueNavigator = object : TimelineQueueNavigator(mediaSession!!) {
            override fun getSupportedQueueNavigatorActions(player: Player): Long {
                var actions: Long = 0
                actions = actions or PlaybackStateCompat.ACTION_SKIP_TO_QUEUE_ITEM
                actions = actions or PlaybackStateCompat.ACTION_SKIP_TO_PREVIOUS
                actions = actions or PlaybackStateCompat.ACTION_SKIP_TO_NEXT
                return actions
            }

            override fun getMediaDescription(player: Player, windowIndex: Int): MediaDescriptionCompat {
                player.let {
                    return MediaDescriptionCompat.Builder().apply {
                        setTitle(media.author)
                        setSubtitle(media.name)
                        setIconUri(Uri.parse(media.coverUrl))
                    }.build()
                }
            }

            override fun onSkipToNext(player: com.google.android.exoplayer2.Player, controlDispatcher: ControlDispatcher) {
                sendCommand("next")
            }

            override fun onSkipToPrevious(player: com.google.android.exoplayer2.Player, controlDispatcher: ControlDispatcher) {
                sendCommand("previous")
            }

        }
        mediaSessionConnector?.setQueueNavigator(timelineQueueNavigator)

        val url = media.url
        Log.i(TAG, "Player: URL: $url")
        val uri = Uri.parse(url)

        @C.ContentType val type = Util.inferContentType(uri)
        Log.i(TAG, "Player: Type: $type HLS: ${C.TYPE_HLS}")
        val source = when (type) {
            C.TYPE_HLS -> HlsMediaSource.Factory(dataSourceFactory)
                    .setPlaylistParserFactory(SMHlsPlaylistParserFactory())
                    .setAllowChunklessPreparation(true)
                    .createMediaSource(uri)
            C.TYPE_OTHER -> {
                val factory: DataSource.Factory =
                        if (uri.scheme != null && uri.scheme?.startsWith("http") == true) {
                            dataSourceFactory
                        } else {
                            FileDataSource.Factory()
                        }

                ProgressiveMediaSource.Factory(factory)
                        .createMediaSource(uri)
            }
            else -> {
                throw IllegalStateException("Unsupported type: $type")
            }
        }
        player?.playWhenReady = false
        player?.prepare(source)
    }

    fun play() {
        performAndEnableTracking {
            player?.playWhenReady = true
        }
    }

    fun sendCommand(type: String) {
        val extra = Bundle()
        extra.putString("type", type)
        mediaSession?.setExtras(extra)

    }

    fun sendNotification(media: Media) {
        mediaSession?.let {
            val state = player?.playbackState ?: PlaybackStateCompat.STATE_NONE
            val onGoing = state == PlaybackStateCompat.STATE_PLAYING || state == PlaybackStateCompat.STATE_BUFFERING
            val notification = notificationBuilder?.buildNotification(it, media, onGoing)
            notification?.let {
                notificationManager?.notify(NOW_PLAYING_NOTIFICATION, notification)
            }
        }
    }

    fun removeNotification() {
        removeNowPlayingNotification();
    }

    fun seek(position: Long) {
        player?.seekTo(position)
        player?.playWhenReady = true
    }

    fun pause() {
        performAndDisableTracking {
            player?.playWhenReady = false
        }
    }

    fun stop() {
        performAndDisableTracking {
            player?.playWhenReady = false
        }
    }

    fun release() {
        performAndDisableTracking {
            player?.playWhenReady = false
        }
    }

    private fun removeNowPlayingNotification() {
        Log.d(TAG, "removeNowPlayingNotification")
        AsyncTask.execute {
            notificationManager?.cancel(NOW_PLAYING_NOTIFICATION)
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
            mediaSession?.let { notificationBuilder?.buildNotification(it, media!!, onGoing) }
        } else {
            null
        }
    }

    private fun playerEventListener(): Player.EventListener {
        return object : Player.EventListener {
            override fun onTimelineChanged(timeline: Timeline, manifest: Any?, reason: Int) {
                Log.i(TAG, "onTimelineChanged: timeline: $timeline manifest: $manifest reason: $reason")
            }

            override fun onTracksChanged(trackGroups: TrackGroupArray, trackSelections: TrackSelectionArray) {
                Log.i(TAG, "onTimelineChanged: trackGroups: $trackGroups trackSelections: $trackSelections")
            }

            override fun onLoadingChanged(isLoading: Boolean) {
                Log.i(TAG, "onLoadingChanged: isLoading: $isLoading")
            }

            override fun onPlayerStateChanged(playWhenReady: Boolean, playbackState: Int) {
                Log.i(TAG, "onPlayerStateChanged: playWhenReady: $playWhenReady playbackState: $playbackState currentPlaybackState: ${player?.getPlaybackState()}")

                if (playWhenReady && playbackState == ExoPlayer.STATE_READY) {
                    //
                } else {
                    if (player?.playbackError != null) {
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
                                val status = if (playWhenReady) PlayerState.PLAYING else PlayerState.PAUSED
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

            override fun onPlayerError(error: ExoPlaybackException) {
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

    private inner class MediaControllerCallback : MediaControllerCompat.Callback() {
        override fun onMetadataChanged(metadata: MediaMetadataCompat?) {
            Log.d(
                    TAG,
                    "onMetadataChanged: title: ${metadata?.title} duration: ${metadata?.duration}"
            )
        }

        override fun onPlaybackStateChanged(state: PlaybackStateCompat?) {
            Log.d(TAG, "onPlaybackStateChanged state: $state")
            AsyncTask.execute {
                updateNotification(state!!)
            }
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

            val onGoing = updatedState == PlaybackStateCompat.STATE_PLAYING || updatedState == PlaybackStateCompat.STATE_BUFFERING

            // Skip building a notification when state is "none".
            val notification = buildNotification(updatedState, onGoing)

            when (updatedState) {
                PlaybackStateCompat.STATE_NONE,
                PlaybackStateCompat.STATE_STOPPED -> {
                    Log.i(TAG, "updateNotification: STATE_NONE or STATE_STOPPED")
                    removeNowPlayingNotification()
                    if (isForegroundService) {
                        stopSelf()
                        stopForeground(true)
                        isForegroundService = false
                    }
                }
                PlaybackStateCompat.STATE_PAUSED -> {
                    Log.i(TAG, "updateNotification: STATE_PAUSED")
                    notificationManager?.notify(NOW_PLAYING_NOTIFICATION, buildNotification(updatedState, onGoing)!!)
                }
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
                        if (!isForegroundService) {
                            ContextCompat.startForegroundService(
                                    applicationContext,
                                    Intent(applicationContext, this@MediaService.javaClass)
                            )
                            startForeground(NOW_PLAYING_NOTIFICATION, notification)

                            isForegroundService = true
                        }
                    }
                }
                else -> {
                    Log.i(TAG, "updateNotification: ELSE")
                    if (isForegroundService) {
                        stopForeground(true)

                        isForegroundService = false

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
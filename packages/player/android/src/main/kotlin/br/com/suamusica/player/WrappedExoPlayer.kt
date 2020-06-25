package br.com.suamusica.player

import android.annotation.SuppressLint
import android.app.Notification
import android.app.PendingIntent
import android.app.Service
import android.content.ComponentName
import android.content.Context
import android.net.Uri
import android.os.*
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
import com.google.android.exoplayer2.C.WAKE_MODE_NETWORK
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
import com.google.android.exoplayer2.Player as ExoPlayer

class WrappedExoPlayer (
        override val context: Context,
        private val messenger: Messenger,
        val handler: Handler
) : Player {
    override var volume = 1.0
    override val duration: Long
        get() = player.duration
    override val currentPosition: Long
        get() = player.currentPosition
    override var releaseMode = ReleaseMode.RELEASE
    override var stayAwake: Boolean = false

    var media: Media? = null

    val TAG = "Player"

    private val mediaControllerCallback = MediaControllerCallback()

    // Build a PendingIntent that can be used to launch the UI.
    val sessionActivityPendingIntent =
        context.packageManager?.getLaunchIntentForPackage(context.packageName)?.let { sessionIntent ->
            PendingIntent.getActivity(this.context, 0, sessionIntent, 0)
        }
    val notificationBuilder = NotificationBuilder(context)
    val notificationManager = NotificationManagerCompat.from(context)
    private var mediaSession: MediaSessionCompat? = null
    private var mediaController: MediaControllerCompat? = null
    private var mediaSessionConnector: MediaSessionConnector? = null

    private val uAmpAudioAttributes = AudioAttributes.Builder()
        .setContentType(C.CONTENT_TYPE_MUSIC)
        .setUsage(C.USAGE_MEDIA)
        .build()

    private var progressTracker: ProgressTracker? = null

    private var previousState: Int = -1

    val player = SimpleExoPlayer.Builder(context).build().apply {
        setAudioAttributes(uAmpAudioAttributes, true)
        addListener(playerEventListener())
        setWakeMode(WAKE_MODE_NETWORK)
        setHandleAudioBecomingNoisy(true)
    }

    init {
        // Create a new MediaSession.
        val mediaButtonReceiver = ComponentName(context, MediaButtonReceiver::class.java)
        mediaSession = mediaSession?.let { it } ?: MediaSessionCompat(this.context, TAG, mediaButtonReceiver, null)
            .apply {
                setSessionActivity(sessionActivityPendingIntent)
                isActive = true
                setCallback(MediaSessionCallback())
            }

        mediaSession?.setFlags(MediaSessionCompat.FLAG_HANDLES_MEDIA_BUTTONS
                or MediaSessionCompat.FLAG_HANDLES_TRANSPORT_CONTROLS
                or MediaSessionCompat.FLAG_HANDLES_QUEUE_COMMANDS)

        mediaSession?.let { mediaSession ->
            val sessionToken = mediaSession.sessionToken

            mediaController = MediaControllerCompat(this.context, sessionToken).also { mediaController ->
                mediaController.registerCallback(mediaControllerCallback)

                mediaSessionConnector = MediaSessionConnector(mediaSession).also { connector ->
                    // Produces DataSource instances through which media data is loaded.
                    connector.setPlayer(player)
                }
            }
        }
    }

    private fun playerEventListener(): com.google.android.exoplayer2.Player.EventListener {
        return object : com.google.android.exoplayer2.Player.EventListener {
            override fun onTimelineChanged(timeline: Timeline, manifest: Any?, reason: Int) {
                 Log.i(TAG, "onTimelineChanged: timeline: $timeline manifest: $manifest reason: $reason")
            }

            override fun onTracksChanged(trackGroups: TrackGroupArray, trackSelections: TrackSelectionArray) {
                 Log.i(TAG, "onTimelineChanged: trackGroups: $trackGroups trackSelections: $trackSelections")
            }

            override fun onLoadingChanged(isLoading: Boolean) {
                 Log.i(TAG, "onLoadingChanged: isLoading: $isLoading")
                if (isLoading) {
                    notifyPlayerStateChange(PlayerState.BUFFERING)
                }
            }

            override fun onPlayerStateChanged(playWhenReady: Boolean, playbackState: Int) {
                //TODO: Only emit Paused when user paused
                Log.i(TAG, "onPlayerStateChanged: playWhenReady: $playWhenReady playbackState: $playbackState currentPlaybackState: ${player.getPlaybackState()}")

                if (playWhenReady && playbackState == ExoPlayer.STATE_READY) {
                    notifyPlayerStateChange(PlayerState.PLAYING)
                } else {
                    if (player.playbackError != null) {
                        notifyPlayerStateChange(PlayerState.ERROR, player.playbackError.toString())
                    } else {
                        when (playbackState) {
                            ExoPlayer.STATE_IDLE -> { // 1
                                notifyPlayerStateChange(PlayerState.IDLE)
                            }
                            ExoPlayer.STATE_BUFFERING -> { // 2 
                                notifyPlayerStateChange(PlayerState.BUFFERING)
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
                                            notifyPlayerStateChange(status)
                                        }
                                    } else {
                                        notifyPlayerStateChange(status)
                                    }

                                }
                            }
                            ExoPlayer.STATE_ENDED -> { // 4
                                stopTrackingProgressAndPerformTask {
                                    notifyPlayerStateChange(PlayerState.COMPLETED)
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
                Log.e(TAG, "onPLayerError: ${error?.message}", error)

                notifyPlayerStateChange(PlayerState.ERROR, player.playbackError.toString())
            }

            override fun onPositionDiscontinuity(reason: Int) {
                Log.i(TAG, "onPositionDiscontinuity: $reason")
            }

            override fun onPlaybackParametersChanged(playbackParameters: PlaybackParameters) {
                Log.i(TAG, "onPlaybackParametersChanged: $playbackParameters")
            }

            override fun onSeekProcessed() {
                Log.i(TAG, "onSeekProcessed")
                notifyPlayerStateChange(PlayerState.SEEK_END)
            }
        }
    }

    override fun prepare(cookie: String, media: Media) {
        this.media = media
        val defaultHttpDataSourceFactory = DefaultHttpDataSourceFactory("mp.next")
        defaultHttpDataSourceFactory.defaultRequestProperties.set("Cookie", cookie)
        val dataSourceFactory = DefaultDataSourceFactory(context, null, defaultHttpDataSourceFactory)

        // Metadata Build
        val metadataBuilder = MediaMetadataCompat.Builder()
        val art = NotificationBuilder.getArt(context, media.coverUrl)
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
            override fun getSupportedQueueNavigatorActions(player: com.google.android.exoplayer2.Player): Long {
                var actions: Long = 0
                    actions = actions or PlaybackStateCompat.ACTION_SKIP_TO_QUEUE_ITEM
                    actions = actions or PlaybackStateCompat.ACTION_SKIP_TO_PREVIOUS
                    actions = actions or PlaybackStateCompat.ACTION_SKIP_TO_NEXT
                return actions
            }
            override fun getMediaDescription(player: com.google.android.exoplayer2.Player, windowIndex: Int): MediaDescriptionCompat {
                player.let {
                    return MediaDescriptionCompat.Builder().apply {
                        setTitle(media.author)
                        setSubtitle(media.name)
                        setIconUri(Uri.parse(media.coverUrl))
                    }.build()
                }
            }

            override fun onSkipToNext(player: com.google.android.exoplayer2.Player, controlDispatcher: ControlDispatcher) {
                next()
            }

            override fun onSkipToPrevious(player: com.google.android.exoplayer2.Player, controlDispatcher: ControlDispatcher) {
                previous()
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
        player.playWhenReady = false
        player.prepare(source)
        // we have to reset the previous state
        previousState = -1
    }

    override fun play() {
        performAndEnableTracking {
            player.playWhenReady = true
            sendNotification(true)
        }
    }

    override fun sendNotification() {
        sendNotification(false)
    }

    override fun removeNotification() {
        removeNowPlayingNotification();
    }

    override fun seek(position: Long) {
        performAndEnableTracking {
            player.seekTo(position)
            player.playWhenReady = true
        }
    }

    override fun pause() {
        Log.i("SMPlayer", "Notification: pause: 1")
        performAndDisableTracking {
            player.playWhenReady = false
            Log.i("SMPlayer", "Notification: pause: 2")
        }
        Log.i("SMPlayer", "Notification: pause: 3")
        sendNotification(false)
        Log.i("SMPlayer", "Notification: pause: 4")
    }

    override fun stop() {
        performAndDisableTracking {
            player.playWhenReady = false
            notifyPlayerStateChange(PlayerState.STOPPED)
        }
        sendNotification(false)
    }

    override fun next() {
        TODO()
//        val ret = channel?.invokeMethod("commandCenter.onNext", mapOf("playerId" to playerId))
    }

    override fun previous() {
        TODO()
//        channel?.invokeMethod("commandCenter.onPrevious", mapOf("playerId" to playerId))
    }

    override fun release() {
        performAndDisableTracking {
            player.playWhenReady = false
        }
    }

    private fun startTrackingProgress() {
        if (progressTracker != null) {
            return
        }
        this.progressTracker = ProgressTracker()
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

    private fun sendNotification(onGoing: Boolean) {
        AsyncTask.execute {
            mediaSession?.let { session ->
                media?.let { media ->
                    val notification = notificationBuilder.buildNotification(session, media, onGoing)
                    notification?.let {
                        notificationManager.notify(NOW_PLAYING_NOTIFICATION, it)
                    }
                }
            }
        }
    }

    private fun notifyPositionChange() {
        val currentPosition = if (player.currentPosition > player.duration) player.duration else player.currentPosition
        val duration = player.duration

        // Log.i(TAG, "notifyPositionChange: position: $currentPosition duration: $duration")

        if (duration > 0) {
            notifyPositionChange(currentPosition, duration)
        }
    }

    private fun notifyPositionChange(currentPosition: Long, duration: Long) {
        val msg = Message.obtain(null, MediaService.MessageType.POSITION_CHANGE.ordinal, 0, 0)
        msg.data = Bundle()
        msg.data.putLong("currentPosition", currentPosition)
        msg.data.putLong("duration", duration)
        messenger.send(msg)
    }

    private fun notifyPlayerStateChange(state: PlayerState, error: String? = null) {
        val msg = Message.obtain(null, MediaService.MessageType.STATE_CHANGE.ordinal, 0, 0)
        msg.data = Bundle()
        msg.data.putInt("state", state.ordinal)
        error?.let {
            msg.data.putString("error", it)
        }
        messenger.send(msg)
    }

    private fun removeNowPlayingNotification() {
        Log.d(TAG, "removeNowPlayingNotification")
        AsyncTask.execute {
            notificationManager?.cancel(NOW_PLAYING_NOTIFICATION)
        }
    }

    inner class ProgressTracker : Runnable {
        private val shutdownRequest = AtomicBoolean(false)
        private var shutdownTask: (() -> Unit)? = null

        init {
            handler.post(this)
        }

        override fun run() {
            notifyPositionChange()

            if (!shutdownRequest.get()) {
                handler.postDelayed(this, 400 /* ms */)
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
                "onMetadataChanged: metadata: $metadata"
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
                }
                PlaybackStateCompat.STATE_PAUSED -> {
                    Log.i(TAG, "updateNotification: STATE_PAUSED")
                    notificationManager.notify(NOW_PLAYING_NOTIFICATION, buildNotification(updatedState, onGoing)!!)
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
                        notificationManager.notify(NOW_PLAYING_NOTIFICATION, notification)
                    }
                }
                else -> {
                    Log.i(TAG, "updateNotification: ELSE")
                    if (notification != null) {
                        notificationManager?.notify(NOW_PLAYING_NOTIFICATION, notification)
                    } else
                        removeNowPlayingNotification()
                }
            }
        }

        private fun buildNotification(updatedState: Int, onGoing: Boolean): Notification? {
            return if (updatedState != PlaybackStateCompat.STATE_NONE) {
                mediaSession?.let { notificationBuilder.buildNotification(it, media!!, onGoing) }
            } else {
                null
            }
        }
    }
}
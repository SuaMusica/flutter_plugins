package br.com.suamusica.player

import br.com.suamusica.player.media.parser.SMHlsPlaylistParserFactory

import android.annotation.SuppressLint
import android.app.Notification
import android.app.PendingIntent
import android.app.Service
import android.content.ComponentName
import android.content.Context
import android.net.Uri
import android.net.wifi.WifiManager
import android.os.AsyncTask
import android.os.Handler
import android.os.PowerManager
import android.support.v4.media.MediaMetadataCompat
import android.support.v4.media.session.MediaControllerCompat
import android.support.v4.media.session.MediaSessionCompat
import android.support.v4.media.session.PlaybackStateCompat
import android.util.Log
import androidx.core.app.NotificationManagerCompat
import androidx.media.session.MediaButtonReceiver
import com.google.android.exoplayer2.C
import com.google.android.exoplayer2.ExoPlaybackException
import com.google.android.exoplayer2.PlaybackParameters
import com.google.android.exoplayer2.SimpleExoPlayer
import com.google.android.exoplayer2.Timeline
import com.google.android.exoplayer2.audio.AudioAttributes
import com.google.android.exoplayer2.ext.mediasession.MediaSessionConnector
import com.google.android.exoplayer2.source.ProgressiveMediaSource
import com.google.android.exoplayer2.source.TrackGroupArray
import com.google.android.exoplayer2.source.hls.HlsMediaSource
import com.google.android.exoplayer2.trackselection.TrackSelectionArray
import com.google.android.exoplayer2.upstream.DataSource
import com.google.android.exoplayer2.upstream.DefaultDataSourceFactory
import com.google.android.exoplayer2.upstream.DefaultHttpDataSourceFactory
import com.google.android.exoplayer2.upstream.FileDataSource
import com.google.android.exoplayer2.util.Util
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.atomic.AtomicBoolean
import com.google.android.exoplayer2.Player as ExoPlayer

class WrappedExoPlayer(
    val playerId: String,
    override val context: Context,
    val channel: MethodChannel,
    val plugin: Plugin,
    val handler: Handler,
    override val cookie: String
) : Player {
    val TAG = "Player"
    override var volume = 1.0
    override val duration: Long
        get() = player.duration
    override val currentPosition: Long
        get() = player.currentPosition
    override var releaseMode = ReleaseMode.RELEASE
    override var stayAwake: Boolean = false
    val channelManager = MethodChannelManager(channel)

    var media: Media? = null

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

    private var wifiLock: WifiManager.WifiLock? = null
    private var wakeLock: PowerManager.WakeLock? = null

    private val uAmpAudioAttributes = AudioAttributes.Builder()
        .setContentType(C.CONTENT_TYPE_MUSIC)
        .setUsage(C.USAGE_MEDIA)
        .build()

    private var progressTracker: ProgressTracker? = null

    private var previousState: Int = -1

    val player = SimpleExoPlayer.Builder(context).build().apply {
        setAudioAttributes(uAmpAudioAttributes, true)
        addListener(playerEventListener())
    }

    init {
        wifiLock = (context.getSystemService(Context.WIFI_SERVICE) as WifiManager)
            .createWifiLock(WifiManager.WIFI_MODE_FULL_HIGH_PERF, "wifiLock")
        wakeLock = (context.getSystemService(Context.POWER_SERVICE) as PowerManager)
            .newWakeLock(PowerManager.PARTIAL_WAKE_LOCK or PowerManager.ON_AFTER_RELEASE, "suamusica:wakeLock")
        wifiLock?.setReferenceCounted(false)
        wakeLock?.setReferenceCounted(false)

        // Metadata Build
        val metadataBuilder = MediaMetadataCompat.Builder()
        metadataBuilder.apply {
            album = media?.author
            title = media?.name
            displayTitle = media?.name
            albumArt = NotificationBuilder.getArt(context, media?.coverUrl)
        }
        val metadata = metadataBuilder.build()

        // Create a new MediaSession.
        val mediaButtonReceiver = ComponentName(context, MediaButtonReceiver::class.java)
        mediaSession = mediaSession?.let { it } ?: MediaSessionCompat(this.context, "Player", mediaButtonReceiver, null)
            .apply {
                setSessionActivity(sessionActivityPendingIntent)
                isActive = true
                setCallback(MediaSessionCallback())
                val metadataBuilder = MediaMetadataCompat.Builder()
                metadataBuilder.apply {
                    album = media?.author
                    title = media?.name
                    displayTitle = media?.name
                    albumArt = NotificationBuilder.getArt(context, media?.coverUrl)
                }
                setMetadata(metadata)
            }

        mediaSession?.setFlags(MediaSessionCompat.FLAG_HANDLES_MEDIA_BUTTONS or MediaSessionCompat.FLAG_HANDLES_TRANSPORT_CONTROLS)

        mediaSession?.let { mediaSession ->
            val sessionToken = mediaSession.sessionToken

            mediaController = MediaControllerCompat(this.context, sessionToken).also { mediaController ->
                mediaController.registerCallback(mediaControllerCallback)

                mediaSessionConnector = MediaSessionConnector(mediaSession).also { connector ->
                    // Produces DataSource instances through which media data is loaded.
                    connector.setPlayer(player)
                    connector.setMediaMetadataProvider {
                        return@setMediaMetadataProvider metadata
                    }
                }
            }
        }
    }

    private fun playerEventListener(): com.google.android.exoplayer2.Player.EventListener {
        return object : com.google.android.exoplayer2.Player.EventListener {
            override fun onTimelineChanged(timeline: Timeline, manifest: Any?, reason: Int) {
                 Log.i("Player", "onTimelineChanged: timeline: $timeline manifest: $manifest reason: $reason")
            }

            override fun onTracksChanged(trackGroups: TrackGroupArray, trackSelections: TrackSelectionArray) {
                 Log.i("Player", "onTimelineChanged: trackGroups: $trackGroups trackSelections: $trackSelections")
            }

            override fun onLoadingChanged(isLoading: Boolean) {
                 Log.i("Player", "onLoadingChanged: isLoading: $isLoading")
                if (isLoading) {
                    channelManager.notifyPlayerStateChange(playerId, PlayerState.BUFFERING)
                }
            }

            override fun onPlayerStateChanged(playWhenReady: Boolean, playbackState: Int) {
                //TODO: Only emit Paused when user paused
                Log.i("Player", "onPlayerStateChanged: playWhenReady: $playWhenReady playbackState: $playbackState currentPlaybackState: ${player.getPlaybackState()}")

                if (playWhenReady && playbackState == ExoPlayer.STATE_READY) {
                    channelManager.notifyPlayerStateChange(playerId, PlayerState.PLAYING)
                } else {
                    if (player.playbackError != null) {
                        channelManager.notifyPlayerStateChange(playerId, PlayerState.ERROR, player.playbackError.toString())
                    } else {
                        when (playbackState) {
                            ExoPlayer.STATE_IDLE -> { // 1
                                channelManager.notifyPlayerStateChange(playerId, PlayerState.IDLE)
                            }
                            ExoPlayer.STATE_BUFFERING -> { // 2 
                                channelManager.notifyPlayerStateChange(playerId, PlayerState.BUFFERING)
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
                                            channelManager.notifyPlayerStateChange(playerId, status)
                                        }
                                    } else {
                                        channelManager.notifyPlayerStateChange(playerId, status)
                                    }

                                }
                            }
                            ExoPlayer.STATE_ENDED -> { // 4
                                stopTrackingProgressAndPerformTask {
                                    channelManager.notifyPlayerStateChange(playerId, PlayerState.COMPLETED)
                                }
                            }
                        }
                    }
                }
                previousState = playbackState
            }

            override fun onRepeatModeChanged(repeatMode: Int) {
                Log.i("Player", "onRepeatModeChanged: $repeatMode")
            }

            override fun onShuffleModeEnabledChanged(shuffleModeEnabled: Boolean) {
                Log.i("Player", "onShuffleModeEnabledChanged: $shuffleModeEnabled")
            }

            override fun onPlayerError(error: ExoPlaybackException) {
                Log.e("Player", "onPLayerError: ${error?.message}", error)

                channelManager.notifyPlayerStateChange(playerId, PlayerState.ERROR, player.playbackError.toString())
            }

            override fun onPositionDiscontinuity(reason: Int) {
                Log.i("Player", "onPositionDiscontinuity: $reason")
            }

            override fun onPlaybackParametersChanged(playbackParameters: PlaybackParameters) {
                Log.i("Player", "onPlaybackParametersChanged: $playbackParameters")
            }

            override fun onSeekProcessed() {
                Log.i("Player", "onSeekProcessed")
                channelManager.notifyPlayerStateChange(playerId, PlayerState.SEEK_END)
            }
        }
    }

    override fun prepare(media: Media) {
        this.media = media
        val defaultHttpDataSourceFactory = DefaultHttpDataSourceFactory("mp.next")
        defaultHttpDataSourceFactory.defaultRequestProperties.set("Cookie", cookie)
        val dataSourceFactory = DefaultDataSourceFactory(context, null, defaultHttpDataSourceFactory)

        var url = media.url
        Log.i("Player", "Player: URL: $url")
        val uri = Uri.parse(url)

        val playerNotificationManager = NotificationBuilder.createPlayerNotificationManager(context, mediaSession!!, player, media)

        @C.ContentType val type = Util.inferContentType(uri)
        Log.i("Player", "Player: Type: $type HLS: ${C.TYPE_HLS}")
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
        player.prepare(source)
        // we have to reset the previus state
        previousState = -1
    }

    override fun play() {
        performAndEnableTracking {
            player.playWhenReady = true

            sendNotification(true)
        }
    }

    override fun removeNotification() {
        removeNowPlayingNotification();
    }

    override fun seek(position: Int) {
        performAndEnableTracking {
            player.seekTo(position.toLong())
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
            channelManager.notifyPlayerStateChange(playerId, PlayerState.STOPPED)
        }
        sendNotification(false)
    }

    override fun next() {
        Log.i("SMPlayer", "channel: $channel playerId: $playerId")
        val ret = channel?.invokeMethod("commandCenter.onNext", mapOf("playerId" to playerId))
        Log.i("SMPlayer", "channel: $channel playerId: $playerId ret: $ret")
    }

    override fun previous() {
        channel?.invokeMethod("commandCenter.onPrevious", mapOf("playerId" to playerId))
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
            val notification = notificationBuilder.buildNotification(this.mediaSession!!, this.media!!, onGoing)
            notification?.let {
                notificationManager?.notify(NOW_PLAYING_NOTIFICATION, it)
            }
        }
    }

    private fun notifyPositionChange() {
        val currentPosition = if (player.currentPosition > player.duration) player.duration else player.currentPosition
        val duration = player.duration

        // Log.i("Player", "notifyPositionChange: position: $currentPosition duration: $duration")

        if (duration > 0) {
            channelManager.notifyPositionChange(playerId, currentPosition, duration)
        }
    }

    private fun removeNowPlayingNotification() {
        Log.d("Player", "removeNowPlayingNotification")
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
                "Player",
                "onMetadataChanged: metadata: $metadata"
            )
        }

        override fun onPlaybackStateChanged(state: PlaybackStateCompat?) {
            Log.d("Player", "onPlaybackStateChanged state: $state")
            AsyncTask.execute {
                updateNotification(state!!)
            }
        }

        override fun onQueueChanged(queue: MutableList<MediaSessionCompat.QueueItem>?) {
            Log.d("Player", "onQueueChanged queue: $queue")
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
                    Log.i("Player", "updateNotification: STATE_NONE or STATE_STOPPED")
                    removeNowPlayingNotification()
                }
                PlaybackStateCompat.STATE_PAUSED -> {
                    Log.i("Player", "updateNotification: STATE_PAUSED")
                    notificationManager.notify(NOW_PLAYING_NOTIFICATION, buildNotification(updatedState, onGoing)!!)
                }
                PlaybackStateCompat.STATE_BUFFERING,
                PlaybackStateCompat.STATE_PLAYING -> {
                    Log.i("Player", "updateNotification: STATE_BUFFERING or STATE_PLAYING")
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
                    Log.i("Player", "updateNotification: ELSE")
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
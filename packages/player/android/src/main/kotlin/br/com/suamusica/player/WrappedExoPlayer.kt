package br.com.suamusica.player

import android.content.Context
import android.net.Uri
import android.os.Handler
import android.util.Log
import com.google.android.exoplayer2.*
import com.google.android.exoplayer2.audio.AudioAttributes
import com.google.android.exoplayer2.source.ProgressiveMediaSource
import com.google.android.exoplayer2.source.TrackGroupArray
import com.google.android.exoplayer2.source.hls.HlsMediaSource
import com.google.android.exoplayer2.trackselection.TrackSelectionArray
import com.google.android.exoplayer2.upstream.DataSource
import com.google.android.exoplayer2.upstream.DefaultDataSourceFactory
import com.google.android.exoplayer2.upstream.DefaultHttpDataSourceFactory
import com.google.android.exoplayer2.upstream.FileDataSourceFactory
import com.google.android.exoplayer2.util.Util
import com.google.android.exoplayer2.Player as ExoPlayer
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.atomic.AtomicBoolean


class WrappedExoPlayer(val playerId: String,
                       override val context: Context,
                       val channel: MethodChannel,
                       val plugin: Plugin,
                       val handler: Handler,
                       override val cookie: String) : Player {
    override var volume = 1.0
    override val duration: Long
        get() = player.duration
    override val currentPosition: Long
        get() = player.currentPosition
    override var releaseMode = ReleaseMode.RELEASE
    override var stayAwake: Boolean = false
    val channelManager = MethodChannelManager(channel)

    private val uAmpAudioAttributes = AudioAttributes.Builder()
            .setContentType(C.CONTENT_TYPE_MUSIC)
            .setUsage(C.USAGE_MEDIA)
            .build()

    private var progressTracker: ProgressTracker? = null

    private var previousState: Int = -1

    private fun playerEventListener(): com.google.android.exoplayer2.Player.EventListener {
        return object : com.google.android.exoplayer2.Player.EventListener {
            override fun onTimelineChanged(timeline: Timeline?, manifest: Any?, reason: Int) {
                // Log.i("MusicService", "onTimelineChanged: timeline: $timeline manifest: $manifest reason: $reason")
            }

            override fun onTracksChanged(trackGroups: TrackGroupArray?, trackSelections: TrackSelectionArray?) {
                // Log.i("MusicService", "onTimelineChanged: trackGroups: $trackGroups trackSelections: $trackSelections")
            }

            override fun onLoadingChanged(isLoading: Boolean) {
                // Log.i("MusicService", "onLoadingChanged: isLoading: $isLoading")
                if (isLoading) {
                    channelManager.notifyPlayerStateChange(playerId, PlayerState.BUFFERING)
                }
            }

            override fun onPlayerStateChanged(playWhenReady: Boolean, playbackState: Int) {
                //TODO: Only emit Paused when user paused
                Log.i("MusicService", "onPlayerStateChanged: playWhenReady: $playWhenReady playbackState: $playbackState currentPlaybackState: ${player.getPlaybackState()}")

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
                                val status = if (playWhenReady == true) PlayerState.PLAYING else PlayerState.PAUSED
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
                // Log.i("MusicServiceMusicService", "onRepeatModeChanged: $repeatMode")
            }

            override fun onShuffleModeEnabledChanged(shuffleModeEnabled: Boolean) {
                // Log.i("MusicService", "onShuffleModeEnabledChanged: $shuffleModeEnabled")
            }

            override fun onPlayerError(error: ExoPlaybackException?) {
                // Log.e("MusicService", "onPLayerError: ${error?.message}", error)

                channelManager.notifyPlayerStateChange(playerId, PlayerState.ERROR, player.playbackError.toString())
            }

            override fun onPositionDiscontinuity(reason: Int) {
                // Log.i("MusicService", "onPositionDiscontinuity: $reason")
            }

            override fun onPlaybackParametersChanged(playbackParameters: PlaybackParameters?) {
                // Log.i("MusicService", "onPlaybackParametersChanged: $playbackParameters")
            }

            override fun onSeekProcessed() {
                // Log.i("MusicService", "onSeekProcessed")
            }
        }
    }

    val player = ExoPlayerFactory.newSimpleInstance(context).apply {
        setAudioAttributes(uAmpAudioAttributes, true)
        addListener(playerEventListener())
    }

    override fun prepare(url: String) {
        val defaultHttpDataSourceFactory = DefaultHttpDataSourceFactory("mp.next")
        defaultHttpDataSourceFactory.defaultRequestProperties.set("Cookie", cookie)
        val dataSourceFactory = DefaultDataSourceFactory(context, null, defaultHttpDataSourceFactory)

        val uri = Uri.parse(url)

        @C.ContentType val type = Util.inferContentType(uri)
        val source = when (type) {
            C.TYPE_HLS -> HlsMediaSource.Factory(dataSourceFactory)
                    .setAllowChunklessPreparation(true)
                    .createMediaSource(uri)
            C.TYPE_OTHER -> {
                val factory: DataSource.Factory =
                        if (uri.scheme != null && uri.scheme?.startsWith("http") == true) {
                            dataSourceFactory
                        } else {
                            FileDataSourceFactory()
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
        }
    }

    override fun seek(position: Int) {
        performAndEnableTracking {
            player.seekTo(position.toLong())
            player.playWhenReady = true
        }
    }

    override fun pause() {
        performAndDisableTracking {
            player.playWhenReady = false
        }
    }

    override fun stop() {
        performAndDisableTracking {
            player.playWhenReady = false
            channelManager.notifyPlayerStateChange(playerId, PlayerState.STOPPED)
        }
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

    private fun notifyPositionChange() {
        val currentPosition = if (player.currentPosition > player.duration) player.duration else player.currentPosition
        val duration = player.duration

        // Log.i("MusicService", "notifyPositionChange: position: $currentPosition duration: $duration")

        if (duration > 0) {
            channelManager.notifyPositionChange(playerId, currentPosition, duration)
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
}

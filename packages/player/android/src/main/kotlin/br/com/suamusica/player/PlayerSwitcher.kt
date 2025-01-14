import android.R
import android.content.Context
import android.os.Handler
import android.support.v4.media.session.PlaybackStateCompat
import androidx.core.content.res.ResourcesCompat
import androidx.media3.common.C
import androidx.media3.common.ForwardingPlayer
import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.source.MediaSource
import androidx.media3.exoplayer.source.ShuffleOrder
import br.com.suamusica.player.getAllMediaItems
import android.util.Log
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player.STATE_ENDED
import br.com.suamusica.player.MediaButtonEventHandler
import br.com.suamusica.player.PlayerSingleton
import br.com.suamusica.player.PlayerSingleton.playerChangeNotifier
import java.util.concurrent.atomic.AtomicBoolean
import android.os.Looper
import androidx.media3.cast.CastPlayer
import com.google.android.gms.cast.framework.media.RemoteMediaClient


@UnstableApi
class PlayerSwitcher(
    private var currentPlayer: Player,
    private var mediaButtonEventHandler: MediaButtonEventHandler,
) : ForwardingPlayer(currentPlayer) {
    private var playerEventListener: Player.Listener? = null
    private val TAG = "PlayerSwitcher"
    private var progressTracker: ProgressTracker? = null
    var remoteMediaClient: RemoteMediaClient? = null

    init {
        playerEventListener?.let { currentPlayer.removeListener(it) }
        setupPlayerListener()
    }

    fun setCurrentPlayer(newPlayer: Player, remoteMediaClient: RemoteMediaClient? = null) {
        if (this.currentPlayer === newPlayer) {
            return
        }
        this.remoteMediaClient = remoteMediaClient
        val playerState = savePlayerState()
        playerEventListener?.let { currentPlayer.removeListener(it) }
        stopAndClearCurrentPlayer()
        this.currentPlayer = newPlayer
        if (currentPlayer is CastPlayer) {
            restorePlayerState(playerState)
        }
        setupPlayerListener()
    }

    private data class PlayerState(
        val playbackPositionMs: Long = C.TIME_UNSET,
        val currentItemIndex: Int = C.INDEX_UNSET,
        val playWhenReady: Boolean = false,
        val mediaItems: List<MediaItem> = emptyList(),
    )

    private fun savePlayerState(): PlayerState {
        return PlayerState(
            playbackPositionMs = if (currentPlayer.playbackState != STATE_ENDED) currentPlayer.currentPosition else C.TIME_UNSET,
            currentItemIndex = currentPlayer.currentMediaItemIndex,
            playWhenReady = currentPlayer.playWhenReady,
            mediaItems = currentPlayer.getAllMediaItems()
        )
    }

    private fun stopAndClearCurrentPlayer() {
        currentPlayer.stop()
        if (currentPlayer is CastPlayer) {
            currentPlayer.clearMediaItems()
        }
    }

    private fun restorePlayerState(state: PlayerState) {
        currentPlayer.setMediaItems(
            state.mediaItems,
            state.currentItemIndex,
            state.playbackPositionMs
        )
        currentPlayer.playWhenReady = state.playWhenReady
        currentPlayer.prepare()
    }

    private fun setupPlayerListener() {
        playerEventListener = object : Player.Listener {
            override fun onPositionDiscontinuity(
                oldPosition: Player.PositionInfo,
                newPosition: Player.PositionInfo,
                reason: Int
            ) {
                if (reason == DISCONTINUITY_REASON_SEEK) {
                    playerChangeNotifier?.notifySeekEnd()
                }
            }

            override fun onIsPlayingChanged(isPlaying: Boolean) {
               super.onIsPlayingChanged(isPlaying)
                if(lastState != STATE_BUFFERING) {
                    playerChangeNotifier?.notifyPlaying(isPlaying)
                }
                    if (isPlaying) {
                        startTrackingProgress()
                    } else {
                        stopTrackingProgress()
                    }
            }

            override fun onMediaItemTransition(
                mediaItem: MediaItem?,
                reason: @Player.MediaItemTransitionReason Int
            ) {
                super.onMediaItemTransition(mediaItem, reason)
                Log.d(TAG, "#NATIVE LOGS ==> onMediaItemTransition reason: $reason")
                if ((currentPlayer.mediaItemCount ?: 0) > 0) {
                    playerChangeNotifier?.currentMediaIndex(
                        currentIndex(),
                        "onMediaItemTransition",
                    )
                }
                mediaButtonEventHandler.buildIcons()
                if (reason == Player.MEDIA_ITEM_TRANSITION_REASON_PLAYLIST_CHANGED || !PlayerSingleton.shouldNotifyTransition) {
                    return
                }
                playerChangeNotifier?.notifyItemTransition("onMediaItemTransition  reason: ${reason} | shouldNotifyTransition: ${PlayerSingleton.shouldNotifyTransition}")
                PlayerSingleton.shouldNotifyTransition = false
            }

            var lastState = PlaybackStateCompat.STATE_NONE - 1

            override fun onPlaybackStateChanged(playbackState: @Player.State Int) {
                super.onPlaybackStateChanged(playbackState)
                if (lastState != playbackState) {
                    lastState = playbackState
                    playerChangeNotifier?.notifyStateChange(playbackState)
                }

                if (playbackState == STATE_ENDED) {
                    stopTrackingProgressAndPerformTask {}
                }
                Log.d(TAG, "##onPlaybackStateChanged $playbackState")
            }

            override fun onPlayerErrorChanged(error: PlaybackException?) {
                super.onPlayerErrorChanged(error)
                Log.d(TAG, "##onPlayerErrorChanged ${error}")

            }

            override fun onPlayerError(error: PlaybackException) {
                Log.d(
                    "#NATIVE LOGS ==>",
                    "onPlayerError cause ${error.cause.toString()}"
                )

                playerChangeNotifier?.notifyError(
                    if (error.cause.toString()
                            .contains("Permission denied")
                    ) "Permission denied" else error.message
                )
            }

            override fun onRepeatModeChanged(repeatMode: @Player.RepeatMode Int) {
                super.onRepeatModeChanged(repeatMode)
                playerChangeNotifier?.onRepeatChanged(repeatMode)
            }
        }
        playerEventListener?.let { currentPlayer.addListener(it) }
    }

    private fun startTrackingProgress() {
        progressTracker?.stopTracking()
        progressTracker = ProgressTracker(Handler(Looper.getMainLooper()), this).apply {
            setOnPositionChangeListener { position, duration ->
                notifyPositionChange()
            }
            startTracking()
        }
    }

    fun currentIndex(): Int {
        val position = if (currentPlayer.shuffleModeEnabled) {
            PlayerSingleton.shuffledIndices.indexOf(
                currentPlayer.currentMediaItemIndex
            )
        } else {
            currentPlayer.currentMediaItemIndex
        }
        return position
    }

    private fun stopTrackingProgress() {
        progressTracker?.stopTracking()
        progressTracker = null
    }

    fun customShuffleModeEnabled(shuffleModeEnabled: Boolean) {
        when (currentPlayer) {
            is ExoPlayer -> {
                (currentPlayer as ExoPlayer).shuffleModeEnabled = shuffleModeEnabled
            }

            is CastPlayer -> {
                currentPlayer.shuffleModeEnabled = shuffleModeEnabled
            }
        }
    }

    fun setShuffleOrder(shuffleOrder: ShuffleOrder) {
        if (currentPlayer is ExoPlayer) {
            (currentPlayer as ExoPlayer).setShuffleOrder(shuffleOrder)
        }
    }

    fun addMediaSource(index: Int, mediaSource: MediaSource) {
        if (currentPlayer is ExoPlayer) {
            (currentPlayer as ExoPlayer).addMediaSource(index, mediaSource)
        }
    }

    fun addMediaSources(mediaSources: MutableList<MediaSource>) {
        if (currentPlayer is ExoPlayer) {
            (currentPlayer as ExoPlayer).addMediaSources(mediaSources)
        }
    }


    override fun getWrappedPlayer(): Player = currentPlayer

    private fun stopTrackingProgressAndPerformTask(callable: () -> Unit) {
        progressTracker?.stopTracking {
            callable()
        }
        progressTracker = null
    }

    private fun notifyPositionChange() {
        val position = currentPlayer.currentPosition.coerceAtMost(currentPlayer.duration ?: 0L)
        val duration = currentPlayer.duration ?: 0L
        playerChangeNotifier?.notifyPositionChange(position, duration)
    }
}


@UnstableApi
class ProgressTracker(
    private val handler: Handler,
    private val player: PlayerSwitcher,
    private val updateIntervalMs: Long = 500 // Intervalo configurável
) : Runnable {
    private val TAG = "ProgressTracker"
    private val isTracking = AtomicBoolean(false)
    private var shutdownTask: (() -> Unit)? = null
    private var onPositionChange: ((Long, Long) -> Unit)? = null

    fun startTracking() {
        if (isTracking.compareAndSet(false, true)) {
            handler.post(this)
        }
    }

    override fun run() {
        if (!isTracking.get()) return

        try {
            val position = player.wrappedPlayer.currentPosition
            val duration = player.wrappedPlayer.duration

            // Verifica se está próximo do fim
            if (duration > 0 && position >= duration - END_THRESHOLD_MS) {
                playerChangeNotifier?.notifyStateChange(STATE_ENDED)
                Log.d(TAG, "Track completing: position=$position, duration=$duration")
            }

            // Notifica mudança de posição
            onPositionChange?.invoke(position, duration)

            // Agenda próxima atualização
            if (isTracking.get()) {
                handler.postDelayed(this, updateIntervalMs)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error during progress tracking", e)
            stopTracking()
        }
    }

    fun stopTracking(onStopped: (() -> Unit)? = null) {
        if (isTracking.compareAndSet(true, false)) {
            handler.removeCallbacks(this)
            onStopped?.invoke()
        }
    }

    fun setOnPositionChangeListener(listener: ((Long, Long) -> Unit)?) {
        onPositionChange = listener
    }

    companion object {
        private const val END_THRESHOLD_MS = 800L
    }
}
package br.com.suamusica.player

import android.support.v4.media.session.PlaybackStateCompat
import android.util.Log

class PlayerChangeNotifier(private val channelManager: MethodChannelManager) {
    fun notifyStateChange(state: Int, error: String? = null) {
        val playerState = when (state) {
            PlaybackStateCompat.STATE_NONE -> PlayerState.IDLE
            PlaybackStateCompat.STATE_BUFFERING -> PlayerState.BUFFERING
            PlaybackStateCompat.STATE_PAUSED -> PlayerState.PAUSED
            PlaybackStateCompat.STATE_PLAYING -> PlayerState.PLAYING
            PlaybackStateCompat.STATE_ERROR -> PlayerState.ERROR
            PlaybackStateCompat.STATE_STOPPED -> PlayerState.COMPLETED
            else -> PlayerState.IDLE
        }
        Log.i("Player", "Notifying Player State change: $playerState")
        channelManager.notifyPlayerStateChange("sua-musica-player", playerState, error)
    }

    fun notifySeekEnd() {
        Log.i("Player", "Notifying Player State seek end")
        channelManager.notifyPlayerStateChange("sua-musica-player", PlayerState.SEEK_END)
    }

    fun notifyNext() {
        Log.i("Player", "Notifying Player Next")
        channelManager.notifyNext("sua-musica-player")
    }
    fun notifyPrevious() {
        Log.i("Player", "Notifying Player Previous")
        channelManager.notifyPrevious("sua-musica-player")
    }
    fun notifyItemTransition() {
        Log.i("Player", "notifyItemTransition")
        channelManager.notifyItemTransition("sua-musica-player")
    }
    fun sendCurrentQueue(queue:List<Media>, idSum:Int) {
        Log.i("Player", "Notifying Player Previous")
        channelManager.sendCurrentQueue(queue,idSum,"sua-musica-player")
    }
    fun currentMediaIndex(currentMediaIndex:Int) {
        Log.i("Player", "Notifying Player Previous")
        channelManager.currentMediaIndex("sua-musica-player", currentMediaIndex)
    }
    fun notifyPositionChange(position: Long, duration: Long) {
        Log.i("Player", "Notifying Player Position change: position: $position duration: $duration")
        channelManager.notifyPositionChange("sua-musica-player", position, duration)
    }
    fun onRepeatChanged(repeatMode: Int) {
        Log.i("Player", "Notifying Player onRepeatChanged: $repeatMode")
        channelManager.onRepeatChanged("sua-musica-player", repeatMode)
    }
    fun onShuffleModeEnabled(shuffleModeEnabled: Boolean) {
        Log.i("Player", "Notifying Player onRepeatChanged: $shuffleModeEnabled")
        channelManager.onShuffleModeEnabled("sua-musica-player", shuffleModeEnabled)
    }

}
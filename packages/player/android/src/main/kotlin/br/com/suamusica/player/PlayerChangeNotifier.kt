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
    fun notifyPositionChange(position: Long, duration: Long) {
        Log.i("Player", "Notifying Player Position change: position: $position duration: $duration")
        channelManager.notifyPositionChange("sua-musica-player", position, duration)
    }

}
package br.com.suamusica.player

import android.support.v4.media.session.PlaybackStateCompat
import android.util.Log

class PlayerStateChangeNotifier(private val channelManager: MethodChannelManager) {
    fun notify(state: Int) {
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
        channelManager.notifyPlayerStateChange("aa", playerState, null)
    }

}
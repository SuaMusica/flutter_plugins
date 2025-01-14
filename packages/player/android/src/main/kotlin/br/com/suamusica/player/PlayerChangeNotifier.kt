package br.com.suamusica.player

import android.support.v4.media.session.PlaybackStateCompat
import android.util.Log
import androidx.media3.common.Player
import androidx.media3.common.Player.*

class PlayerChangeNotifier(private val channelManager: MethodChannelManager) {
    fun notifyStateChange(state: @State Int) {
        val playerState = when (state) {
            STATE_IDLE -> PlayerState.IDLE
            STATE_BUFFERING -> PlayerState.BUFFERING
            STATE_ENDED -> PlayerState.COMPLETED
            STATE_READY -> PlayerState.STATE_READY
            else -> PlayerState.IDLE
        }
        Log.i("Player", "#NATIVE LOGS ==> Notifying Player State change: $playerState | $state")
        channelManager.notifyPlayerStateChange("sua-musica-player", playerState)
    }

    fun notifyPlaying(isPlaying:Boolean){
        channelManager.notifyPlayerStateChange("sua-musica-player", if(isPlaying) PlayerState.PLAYING else PlayerState.PAUSED)
    }

    fun notifyError(message: String? = null){
        Log.i("Player", "Notifying Error: $message")
        channelManager.notifyError("sua-musica-player", PlayerState.ERROR, message)
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
    fun notifyItemTransition(from:String) {
        Log.i("Player", "#NATIVE LOGS ==> notifyItemTransition | FROM: $from")
        channelManager.notifyItemTransition("sua-musica-player")
    }
    fun currentMediaIndex(currentMediaIndex: Int, from: String) {
        Log.i("Player", "#NATIVE LOGS ==> currentMediaIndex | FROM: $from | $currentMediaIndex")
        channelManager.currentMediaIndex("sua-musica-player", currentMediaIndex)
    }
    fun notifyPositionChange(position: Long, duration: Long) {
        // Log.i("Player", "Notifying Player Position change: position: $position duration: $duration")
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
package br.com.suamusica.player

import android.content.Context
import android.util.Log
import io.flutter.plugin.common.MethodChannel

object PlayerSingleton {
    var channel: MethodChannel? = null
    var mediaSessionConnection: MediaSessionConnection? = null
    var externalPlayback: Boolean? = false
    private const val TAG = "Player"
    var playerChangeNotifier: PlayerChangeNotifier? = null

    fun setChannel(c: MethodChannel, context: Context) {
        channel = c
        playerChangeNotifier =   PlayerChangeNotifier(MethodChannelManager(c))
        mediaSessionConnection = MediaSessionConnection(
            context,
            playerChangeNotifier!!
        )
    }

    fun play() {
        if (externalPlayback!!) {
            channel?.invokeMethod("externalPlayback.play", emptyMap<String, String>())
        } else {
            mediaSessionConnection?.play()
            channel?.invokeMethod("commandCenter.onPlay", emptyMap<String, String>())
        }
    }
//TODO(Lucas) verificar se pode retirar
//    fun togglePlayPause(){
//        mediaSessionConnection?.togglePlayPause()
//        channel?.invokeMethod("commandCenter.onTogglePlayPause", emptyMap<String, String>())
//    }
//    fun adsPlaying(){
//        mediaSessionConnection?.adsPlaying()
//    }
    fun pause() {
        if (externalPlayback!!) {
            channel?.invokeMethod("externalPlayback.pause", emptyMap<String, String>())
        } else {
            mediaSessionConnection?.pause()
            channel?.invokeMethod("commandCenter.onPause", emptyMap<String, String>())
        }
    }

    fun previous() {
        channel?.invokeMethod("commandCenter.onPrevious", emptyMap<String, String>())
    }

    fun next() {
        Log.d("Player", "#MEDIA3# - commandCenter NEXT")
        channel?.invokeMethod("commandCenter.onNext", emptyMap<String, String>())
    }

    fun stop() {
        mediaSessionConnection?.stop()
    }

    fun favorite(shouldFavorite: Boolean) {
        Log.d(TAG, "Should Favorite: $shouldFavorite")
        mediaSessionConnection?.favorite(shouldFavorite)
        val args = mutableMapOf<String, Any>()
        args[PlayerPlugin.FAVORITE] = shouldFavorite
        channel?.invokeMethod("commandCenter.onFavorite", args)
    }
}
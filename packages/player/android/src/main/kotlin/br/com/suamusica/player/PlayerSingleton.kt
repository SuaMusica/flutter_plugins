package br.com.suamusica.player

import android.content.Context
import android.util.Log
import io.flutter.plugin.common.MethodChannel

object PlayerSingleton {
    var channel: MethodChannel? = null
    var mediaSessionConnection: MediaSessionConnection? = null
    var externalPlayback: Boolean? = false
//    var lastFavorite: Boolean=false
    private const val TAG = "Player"

    fun setChannel(c: MethodChannel, context: Context) {
        channel = c
        mediaSessionConnection = MediaSessionConnection(
            context,
            PlayerChangeNotifier(MethodChannelManager(c))
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

    fun togglePlayPause(){
        mediaSessionConnection?.togglePlayPause()
        channel?.invokeMethod("commandCenter.onTogglePlayPause", emptyMap<String, String>())
    }
    fun adsPlaying(){
        mediaSessionConnection?.adsPlaying()
    }
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
        channel?.invokeMethod("commandCenter.onNext", emptyMap<String, String>())
    }

    fun stop() {
        mediaSessionConnection?.stop()
    }

    fun favorite(shouldFavorite: Boolean) {
        Log.d(TAG, "Should Favorite: $shouldFavorite")
//        lastFavorite = shouldFavorite
        mediaSessionConnection?.favorite(shouldFavorite)
        val args = mutableMapOf<String, Any>()
        args[FAVORITE] = shouldFavorite
        channel?.invokeMethod("commandCenter.onFavorite", args)
    }
}
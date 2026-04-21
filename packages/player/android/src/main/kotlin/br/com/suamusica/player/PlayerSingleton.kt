package br.com.suamusica.player

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodChannel

object PlayerSingleton {
    var channel: MethodChannel? = null
    var mediaSessionConnection: MediaSessionConnection? = null
    var externalPlayback: Boolean? = false
    var lastFavorite: Boolean=false
    private val mainHandler = Handler(Looper.getMainLooper())

    fun setChannel(c: MethodChannel, context: Context) {
        mediaSessionConnection?.dispose()
        channel = c
        mediaSessionConnection = MediaSessionConnection(
            context,
            PlayerChangeNotifier(MethodChannelManager(c))
        )
    }

    fun clearChannel() {
        mediaSessionConnection?.dispose()
        mediaSessionConnection = null
        channel = null
    }

    fun play() {
        if (externalPlayback!!) {
            invokeMethodOnMainThread("externalPlayback.play", emptyMap<String, String>())
        } else {
            mediaSessionConnection?.play()
            invokeMethodOnMainThread("commandCenter.onPlay", emptyMap<String, String>())
        }
    }

    fun togglePlayPause(){
        mediaSessionConnection?.togglePlayPause()
        invokeMethodOnMainThread("commandCenter.onTogglePlayPause", emptyMap<String, String>())
    }
    fun adsPlaying(){
        mediaSessionConnection?.adsPlaying()
    }
    fun pause() {
        if (externalPlayback!!) {
            invokeMethodOnMainThread("externalPlayback.pause", emptyMap<String, String>())
        } else {
            mediaSessionConnection?.pause()
            invokeMethodOnMainThread("commandCenter.onPause", emptyMap<String, String>())
        }
    }

    fun previous() {
        invokeMethodOnMainThread("commandCenter.onPrevious", emptyMap<String, String>())
    }

    fun next() {
        invokeMethodOnMainThread("commandCenter.onNext", emptyMap<String, String>())
    }

    fun stop() {
        mediaSessionConnection?.stop()
    }

    fun favorite(shouldFavorite: Boolean) {
        lastFavorite = shouldFavorite
        mediaSessionConnection?.favorite(shouldFavorite)
        val args = mutableMapOf<String, Any>()
        args[FAVORITE] = shouldFavorite
        invokeMethodOnMainThread("commandCenter.onFavorite", args)
    }

    private fun invokeMethodOnMainThread(method: String, args: Map<String, Any>) {
        val activeChannel = channel ?: return
        val invokeBlock = {
            activeChannel.invokeMethod(method, args)
        }
        if (Looper.myLooper() == Looper.getMainLooper()) {
            invokeBlock()
        } else {
            mainHandler.post(invokeBlock)
        }
    }
}
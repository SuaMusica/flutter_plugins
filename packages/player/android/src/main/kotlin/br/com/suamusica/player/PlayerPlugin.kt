package br.com.suamusica.player

import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler


class PlayerPlugin : MethodCallHandler, FlutterPlugin,ActivityAware {

    companion object {
        // Argument names
        const val NAME_ARGUMENT = "name"
        const val AUTHOR_ARGUMENT = "author"
        const val URL_ARGUMENT = "url"
        const val COVER_URL_ARGUMENT = "coverUrl"
        const val IS_PLAYING_ARGUMENT = "isPlaying"
        const val IS_FAVORITE_ARGUMENT = "isFavorite"
        const val POSITION_ARGUMENT = "position"
        const val LOAD_ONLY = "loadOnly"
        const val RELEASE_MODE_ARGUMENT = "releaseMode"
        private const val CHANNEL = "suamusica.com.br/player"

        // Method names
        const val LOAD_METHOD = "load"
        const val PLAY_METHOD = "play"
        const val RESUME_METHOD = "resume"
        const val PAUSE_METHOD = "pause"
        const val STOP_METHOD = "stop"
        const val RELEASE_METHOD = "release"
        const val SEEK_METHOD = "seek"
        const val REMOVE_NOTIFICATION_METHOD = "remove_notification"
        const val SET_VOLUME_METHOD = "setVolume"
        const val GET_DURATION_METHOD = "getDuration"
        const val GET_CURRENT_POSITION_METHOD = "getCurrentPosition"
        const val SET_RELEASE_MODE_METHOD = "setReleaseMode"
        const val CAN_PLAY = "can_play"
        const val SEND_NOTIFICATION = "send_notification"
        const val DISABLE_NOTIFICATION_COMMANDS = "disable_notification_commands"
        const val ENABLE_NOTIFICATION_COMMANDS = "enable_notification_commands"
        const val TAG = "Player"
        const val Ok = 1
        private var alreadyAttachedToActivity: Boolean = false
    }

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        Log.d(TAG, "onAttachedToEngine $alreadyAttachedToActivity")
        if (alreadyAttachedToActivity)
            return
        val channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL)
        val context = flutterPluginBinding.applicationContext
        channel.setMethodCallHandler(this)
        PlayerSingleton.setChannel(channel, context)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        Log.d(TAG, "onDetachedFromEngine")
        PlayerSingleton.channel?.setMethodCallHandler(null)
        PlayerSingleton.channel = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        Log.d(TAG, "onAttachedToActivity")
        alreadyAttachedToActivity = true
    }

    override fun onDetachedFromActivityForConfigChanges() {
        Log.d(TAG, "onDetachedFromActivityForConfigChanges")
    }
    override fun onReattachedToActivityForConfigChanges(p0: ActivityPluginBinding) {
        Log.d(TAG, "onReattachedToActivityForConfigChanges")
    }
    override fun onDetachedFromActivity() {
        Log.d(TAG, "onDetachedFromActivity")
    }
    override fun onMethodCall(call: MethodCall, response: MethodChannel.Result) {
        try {
            handleMethodCall(call, response)
        } catch (e: Exception) {
            Log.e(TAG, "Unexpected error!", e)
            response.error("Unexpected error!", e.message, e)
        }
    }

    private fun handleMethodCall(call: MethodCall, response: MethodChannel.Result) {
        val cookie = call.argument<String>("cookie")
        PlayerSingleton.externalPlayback = call.argument<Boolean>("externalplayback")
        Log.d(TAG, "method: ${call.method} cookie: $cookie externalPlayback: ${PlayerSingleton.externalPlayback}")
        when (call.method) {
            LOAD_METHOD -> {
                val name = call.argument<String>(NAME_ARGUMENT)!!
                val author = call.argument<String>(AUTHOR_ARGUMENT)!!
                val url = call.argument<String>(URL_ARGUMENT)!!
                val coverUrl = call.argument<String>(COVER_URL_ARGUMENT)!!
                val position = call.argument<Int>(POSITION_ARGUMENT)
                val isFavorite: Boolean? = call.argument<Boolean>(IS_FAVORITE_ARGUMENT)

                PlayerSingleton.mediaSessionConnection?.prepare(cookie!!, Media(name, author, url, coverUrl, isFavorite))
                position?.let {
                    PlayerSingleton.mediaSessionConnection?.seek(it.toLong(), false)
                }
                PlayerSingleton.mediaSessionConnection?.sendNotification(name, author, url, coverUrl, null, isFavorite)
                Log.d(TAG, "method: ${call.method} name: $name author: $author")
            }
            SEND_NOTIFICATION -> {
                val name = call.argument<String>(NAME_ARGUMENT)!!
                val author = call.argument<String>(AUTHOR_ARGUMENT)!!
                val url = call.argument<String>(URL_ARGUMENT)!!
                val coverUrl = call.argument<String>(COVER_URL_ARGUMENT)!!
                val isPlaying: Boolean? = call.argument<Boolean>(IS_PLAYING_ARGUMENT)
                val isFavorite: Boolean? = call.argument<Boolean>(IS_FAVORITE_ARGUMENT)
                PlayerSingleton.mediaSessionConnection?.sendNotification(name, author, url, coverUrl, isPlaying, isFavorite)
            }
            PLAY_METHOD -> {
                val name = call.argument<String>(NAME_ARGUMENT)!!
                val author = call.argument<String>(AUTHOR_ARGUMENT)!!
                val url = call.argument<String>(URL_ARGUMENT)!!
                val coverUrl = call.argument<String>(COVER_URL_ARGUMENT)!!
                val position = call.argument<Int>(POSITION_ARGUMENT)
                val loadOnly = call.argument<Boolean>(LOAD_ONLY)!!
                val isFavorite: Boolean? = call.argument<Boolean>(IS_FAVORITE_ARGUMENT)

                PlayerSingleton.mediaSessionConnection?.prepare(cookie!!, Media(name, author, url, coverUrl, isFavorite))
                Log.d(TAG, "before prepare: cookie: $cookie")
                position?.let {
                    PlayerSingleton.mediaSessionConnection?.seek(it.toLong(), true)
                }

                if (!loadOnly) {
                    PlayerSingleton.mediaSessionConnection?.play()
                }
            }
            RESUME_METHOD -> {
                PlayerSingleton.mediaSessionConnection?.play()
            }
            PAUSE_METHOD -> {
                PlayerSingleton.mediaSessionConnection?.pause()
            }
            STOP_METHOD -> {
                PlayerSingleton.mediaSessionConnection?.stop()
            }
            RELEASE_METHOD -> {
                PlayerSingleton.mediaSessionConnection?.release()
            }
            SEEK_METHOD -> {
                val position = call.argument<Long>(POSITION_ARGUMENT)!!
                PlayerSingleton.mediaSessionConnection?.seek(position, true)
            }
            REMOVE_NOTIFICATION_METHOD -> {
                PlayerSingleton.mediaSessionConnection?.removeNotification()
            }
            SET_VOLUME_METHOD -> {

            }
            GET_DURATION_METHOD -> {
                response.success(PlayerSingleton.mediaSessionConnection?.duration)
                return
            }
            GET_CURRENT_POSITION_METHOD -> {
                response.success(PlayerSingleton.mediaSessionConnection?.currentPosition)
                return
            }
            SET_RELEASE_MODE_METHOD -> {
                val releaseModeName = call.argument<String>(RELEASE_MODE_ARGUMENT)
                val releaseMode = ReleaseMode.valueOf(releaseModeName!!.substring("ReleaseMode.".length))
                PlayerSingleton.mediaSessionConnection?.releaseMode = releaseMode.ordinal
            }
            DISABLE_NOTIFICATION_COMMANDS -> {

            }
            ENABLE_NOTIFICATION_COMMANDS -> {
            }
            CAN_PLAY -> {
                // no operation required on Android
            }
            else -> {
                response.notImplemented()
                return
            }
        }
        response.success(Ok)
    }
}

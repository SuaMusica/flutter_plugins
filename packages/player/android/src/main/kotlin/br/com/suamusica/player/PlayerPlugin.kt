package br.com.suamusica.player

import android.content.ComponentName
import android.content.Context
import android.os.Handler
import android.os.Message
import android.util.Log
import androidx.annotation.NonNull
import br.com.suamusica.player.MediaService.MessageType.NEXT
import br.com.suamusica.player.MediaService.MessageType.PREVIOUS
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler

class PlayerPlugin : MethodCallHandler, FlutterPlugin {

    companion object {
        // Argument names
        const val NAME_ARGUMENT = "name"
        const val AUTHOR_ARGUMENT = "author"
        const val URL_ARGUMENT = "url"
        const val COVER_URL_ARGUMENT = "coverUrl"
        const val IS_PLAYING_ARGUMENT = "isPlaying"
        const val POSITION_ARGUMENT = "position"
        const val LOAD_ONLY = "loadOnly"
        const val RELEASE_MODE_ARGUMENT = "releaseMode"

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
        const val REMOVE_NOTIFICATION = "remove_notification"
        const val DISABLE_NOTIFICATION_COMMANDS = "disable_notification_commands"
        const val ENABLE_NOTIFICATION_COMMANDS = "enable_notification_commands"
        const val TAG = "Player"
        const val Ok = 1
        private var channel: MethodChannel? = null

        var mediaSessionConnection: MediaSessionConnection? = null

        private fun createAll(messenger: BinaryMessenger, context: Context) {
            if(channel == null){
                channel = MethodChannel(messenger, "smplayer")
                channel?.let {
                    it.setMethodCallHandler(PlayerPlugin())
                    mediaSessionConnection = MediaSessionConnection(context,
                            ComponentName(context, MediaService::class.java),
                            PlayerChangeNotifier(MethodChannelManager(it)))
                }
            }
        }

        @JvmStatic
        var externalPlayback: Boolean? = false

        @JvmStatic
        fun play() {
            if (externalPlayback!!) {
                channel?.invokeMethod("externalPlayback.play", emptyMap<String, String>())
            } else {
                mediaSessionConnection?.play()
            }
        }

        @JvmStatic
        fun pause() {
            if (externalPlayback!!) {
                channel?.invokeMethod("externalPlayback.pause", emptyMap<String, String>())
            } else {
                mediaSessionConnection?.pause()
            }
        }

        @JvmStatic
        fun previous() {
            channel?.invokeMethod("commandCenter.onPrevious", emptyMap<String, String>())
        }

        @JvmStatic
        fun next() {
            channel?.invokeMethod("commandCenter.onNext", emptyMap<String, String>())
        }

        @JvmStatic
        fun stop() {
            mediaSessionConnection?.stop()
        }
    }

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        Log.i(TAG, "onAttachedToEngine")
        createAll(flutterPluginBinding.binaryMessenger, flutterPluginBinding.applicationContext)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        Log.i(TAG, "onDetachedFromEngine")
        channel?.setMethodCallHandler(null)
        channel = null
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
        externalPlayback = call.argument<Boolean>("externalplayback")
        Log.i(TAG, "method: ${call.method} cookie: $cookie externalPlayback: $externalPlayback")
        when (call.method) {
            LOAD_METHOD -> {
                val name = call.argument<String>(NAME_ARGUMENT)!!
                val author = call.argument<String>(AUTHOR_ARGUMENT)!!
                val url = call.argument<String>(URL_ARGUMENT)!!
                val coverUrl = call.argument<String>(COVER_URL_ARGUMENT)!!
                val position = call.argument<Int>(POSITION_ARGUMENT)
                val loadOnly = call.argument<Boolean>(LOAD_ONLY)!!
                mediaSessionConnection?.prepare(cookie!!, Media(name, author, url, coverUrl))
                position?.let {
                    mediaSessionConnection?.seek(it.toLong(), false)
                }
                mediaSessionConnection?.sendNotification(name, author, url, coverUrl, null)
                Log.i(TAG, "method: ${call.method} name: $name author: $author")
            }
            SEND_NOTIFICATION -> {
                val name = call.argument<String>(NAME_ARGUMENT)!!
                val author = call.argument<String>(AUTHOR_ARGUMENT)!!
                val url = call.argument<String>(URL_ARGUMENT)!!
                val coverUrl = call.argument<String>(COVER_URL_ARGUMENT)!!
                var isPlaying: Boolean? = call.argument<Boolean>(IS_PLAYING_ARGUMENT) ?: null
                mediaSessionConnection?.sendNotification(name, author, url, coverUrl, isPlaying)
            }
            PLAY_METHOD -> {
                val name = call.argument<String>(NAME_ARGUMENT)!!
                val author = call.argument<String>(AUTHOR_ARGUMENT)!!
                val url = call.argument<String>(URL_ARGUMENT)!!
                val coverUrl = call.argument<String>(COVER_URL_ARGUMENT)!!
                val position = call.argument<Int>(POSITION_ARGUMENT)
                val loadOnly = call.argument<Boolean>(LOAD_ONLY)!!

                mediaSessionConnection?.prepare(cookie!!, Media(name, author, url, coverUrl))

                Log.i(TAG, "before prepare: cookie: $cookie")
                position?.let {
                    mediaSessionConnection?.seek(it.toLong(), true)
                }

                if (!loadOnly) {
                    mediaSessionConnection?.play()
                }
            }
            RESUME_METHOD -> {
                mediaSessionConnection?.play()
            }
            PAUSE_METHOD -> {
                mediaSessionConnection?.pause()
            }
            STOP_METHOD -> {
                mediaSessionConnection?.stop()
            }
            RELEASE_METHOD -> {
                mediaSessionConnection?.release()
            }
            SEEK_METHOD -> {
                val position = call.argument<Long>(POSITION_ARGUMENT)!!
                mediaSessionConnection?.seek(position, true)
            }
            REMOVE_NOTIFICATION_METHOD -> {
                mediaSessionConnection?.removeNotification();
            }
            SET_VOLUME_METHOD -> {

            }
            GET_DURATION_METHOD -> {
                response.success(mediaSessionConnection?.duration)
                return
            }
            GET_CURRENT_POSITION_METHOD -> {
                response.success(mediaSessionConnection?.currentPosition)
                return
            }
            SET_RELEASE_MODE_METHOD -> {
                val releaseModeName = call.argument<String>(RELEASE_MODE_ARGUMENT)
                val releaseMode = ReleaseMode.valueOf(releaseModeName!!.substring("ReleaseMode.".length))
                mediaSessionConnection?.releaseMode = releaseMode.ordinal
            }
            REMOVE_NOTIFICATION -> {
                // no operation required on Android
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

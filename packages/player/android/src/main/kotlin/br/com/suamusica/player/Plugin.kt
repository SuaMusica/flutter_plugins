package br.com.suamusica.player

import android.content.ComponentName
import android.content.Context
import android.os.Handler
import android.os.Message
import android.os.ResultReceiver
import android.util.Log
import br.com.suamusica.player.MediaService.MessageType.NEXT
import br.com.suamusica.player.MediaService.MessageType.PREVIOUS
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.PluginRegistry.Registrar

class Plugin private constructor(private val channel: MethodChannel, private val context: Context) : MethodCallHandler {
    companion object {
        // Argument names
        const val NAME_ARGUMENT = "name"
        const val AUTHOR_ARGUMENT = "author"
        const val URL_ARGUMENT = "url"
        const val COVER_URL_ARGUMENT = "coverUrl"
        const val POSITION_ARGUMENT = "position"
        const val LOAD_ONLY = "loadOnly"
        const val RELEASE_MODE_ARGUMENT = "releaseMode"

        // Method names
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

        @JvmStatic
        fun registerWith(registrar: Registrar) {
            Log.i(TAG, "registerWith: START")
            channel = MethodChannel(registrar.messenger(), "smplayer")
            channel?.setMethodCallHandler(Plugin(channel!!, registrar.context()))

            val context = registrar.context()

            createMediaSessionConnection(context)

            Log.i(TAG, "registerWith: END")
        }

        private fun createMediaSessionConnection(context: Context) {
            mediaSessionConnection = MediaSessionConnection(context,
                    ComponentName(context, MediaService::class.java),
                    PlayerChangeNotifier(MethodChannelManager(channel!!)))
        }

        @JvmStatic
        fun play() {
            mediaSessionConnection?.play()
        }

        @JvmStatic
        fun pause() {
            mediaSessionConnection?.pause()
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
        Log.i(TAG, "method: ${call.method} cookie: $cookie")
        when (call.method) {
            SEND_NOTIFICATION -> {
                val name = call.argument<String>(NAME_ARGUMENT)!!
                val author = call.argument<String>(AUTHOR_ARGUMENT)!!
                val url = call.argument<String>(URL_ARGUMENT)!!
                val coverUrl = call.argument<String>(COVER_URL_ARGUMENT)!!

                mediaSessionConnection?.sendNotification(name, author, url, coverUrl)
            }

            PLAY_METHOD -> {
                val name = call.argument<String>(NAME_ARGUMENT)!!
                val author = call.argument<String>(AUTHOR_ARGUMENT)!!
                val url = call.argument<String>(URL_ARGUMENT)!!
                val coverUrl = call.argument<String>(COVER_URL_ARGUMENT)!!
                val position = call.argument<Long>(POSITION_ARGUMENT)
                val loadOnly = call.argument<Boolean>(LOAD_ONLY)!!

                mediaSessionConnection?.prepare(cookie!!, Media(name, author, url, coverUrl))

                Log.i(TAG, "before prepare: cookie: $cookie")
                position?.let {
                    mediaSessionConnection?.seek(it)
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
                mediaSessionConnection?.seek(position)
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

    private class CallbackHandler : Handler() {
        override fun handleMessage(msg: Message) {
            Log.i(TAG, "Got msg: $msg")

            when (msg.what) {
                NEXT.ordinal -> {
                    channel?.invokeMethod("commandCenter.onNext", mapOf<String, String>())
                }
                PREVIOUS.ordinal -> {
                    channel?.invokeMethod("commandCenter.onPrevious", mapOf<String, String>())
                }
            }
            super.handleMessage(msg)
        }
    }
}

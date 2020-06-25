package br.com.suamusica.player

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.Handler
import android.os.IBinder
import android.os.Message
import android.os.Messenger
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.PluginRegistry.Registrar
import smplayer.IMediaService

class Plugin private constructor(private val channel: MethodChannel, private val context: Context) : MethodCallHandler {
    companion object {
        // Argument names
        const val PLAYER_ID_ARGUMENT = "playerId"
        const val DEFAULT_PLAYER_ID = "default"
        const val NAME_ARGUMENT = "name"
        const val AUTHOR_ARGUMENT = "author"
        const val URL_ARGUMENT = "url"
        const val COVER_URL_ARGUMENT = "coverUrl"
        const val VOLUME_ARGUMENT = "volume"
        const val POSITION_ARGUMENT = "position"
        const val STAY_AWAKE_ARGUMENT = "stayAwake"
        const val LOAD_ONLY = "loadOnly"
        const val RELEASE_MODE_ARGUMENT = "releaseMode"

        // Method names
        const val PLAY_METHOD = "play"
        const val RESUME_METHOD = "resume"
        const val PAUSE_METHOD = "pause"
        const val STOP_METHOD = "stop"
        const val RELEASE_METHOD = "release"
        const val SEEK_METHOD = "seek"
        const val PREPARE_AND_SEND_NOTIFICATION_METHOD = "prepare_and_send_notification"
        const val REMOVE_NOTIFICATION_METHOD = "remove_notification"
        const val SET_VOLUME_METHOD = "setVolume"
        const val GET_DURATION_METHOD = "getDuration"
        const val GET_CURRENT_POSITION_METHOD = "getCurrentPosition"
        const val SET_RELEASE_MODE_METHOD = "setReleaseMode"
        const val CAN_PLAY = "can_play"
        const val REMOVE_NOTIFICATION = "remove_notification"
        const val DISABLE_NOTIFICATION_COMMANDS = "disable_notification_commands"
        const val ENABLE_NOTIFICATION_COMMANDS = "enable_notification_commands"

        const val TAG = "Player"

        const val Ok = 1

        private var channel: MethodChannel? = null

        var musicService: IMediaService? = null
        var replyMessenger: Messenger? = null

        @JvmStatic
        fun registerWith(registrar: Registrar) {
            channel = MethodChannel(registrar.messenger(), "smplayer")
            channel?.setMethodCallHandler(Plugin(channel!!, registrar.context()))
            bindMediaService(registrar)
            channel?.let {
                createReplyMessenger(it)
            }
        }

        @JvmStatic
        fun play() {
            musicService?.play()
        }

        @JvmStatic
        fun pause() {
            musicService?.pause()
        }

        @JvmStatic
        fun previous() {
            musicService?.pause()
        }

        @JvmStatic
        fun stop() {
            musicService?.stop()
        }

        @JvmStatic
        fun next() {
            musicService?.pause()
        }

        private fun createReplyMessenger(channel: MethodChannel) {
            replyMessenger = Messenger(ReplyHandler(channel))
        }

        private class ReplyHandler(val channel: MethodChannel) : Handler() {
            override fun handleMessage(msg: Message) {
                when (msg.what) {
                    MediaService.MessageType.POSITION_CHANGE.ordinal -> {

                    }
                    MediaService.MessageType.STATE_CHANGE.ordinal -> {

                    }
                }
                Log.i(TAG, "Got a message: $msg")
            }
        }

        private fun bindMediaService(registrar: Registrar) {
            Intent(registrar.context(), MediaService::class.java).let { intent ->
                val musicServiceConnection = object : ServiceConnection {
                    // Called when the connection with the service is established
                    override fun onServiceConnected(className: ComponentName, service: IBinder) {
                        Log.i(TAG, "onServiceConnected")
                        musicService = IMediaService.Stub.asInterface(service)
                    }

                    // Called when the connection with the service disconnects unexpectedly
                    override fun onServiceDisconnected(className: ComponentName) {
                        Log.e("Player", "Service has unexpectedly disconnected")
                        musicService = null
                    }
                }
                registrar.context().bindService(intent, musicServiceConnection, Context.BIND_AUTO_CREATE)
            }
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
            PLAY_METHOD -> {
                val name = call.argument<String>(NAME_ARGUMENT)!!
                val author = call.argument<String>(AUTHOR_ARGUMENT)!!
                val url = call.argument<String>(URL_ARGUMENT)!!
                val coverUrl = call.argument<String>(COVER_URL_ARGUMENT)!!
                val position = call.argument<Long>(POSITION_ARGUMENT)
                val loadOnly = call.argument<Boolean>(LOAD_ONLY)!!

                musicService?.prepare(cookie, name, author, url, coverUrl)

                Log.i(TAG, "before prepare: cookie: $cookie")
                position?.let {
                    musicService?.seek(it)
                }

                if (!loadOnly) {
                    musicService?.play()
                }
            }
            RESUME_METHOD -> {
                musicService?.play()
            }
            PAUSE_METHOD -> {
                musicService?.pause()
            }
            STOP_METHOD -> {
                musicService?.stop()
            }
            RELEASE_METHOD -> {
                musicService?.release()
            }
            SEEK_METHOD -> {
                val position = call.argument<Long>(POSITION_ARGUMENT)!!
                musicService?.seek(position)
            }
            PREPARE_AND_SEND_NOTIFICATION_METHOD -> {
                val name = call.argument<String>(NAME_ARGUMENT)!!
                val author = call.argument<String>(AUTHOR_ARGUMENT)!!
                val url = call.argument<String>(URL_ARGUMENT)!!
                val coverUrl = call.argument<String>(COVER_URL_ARGUMENT)!!
                Log.i(TAG, "PREPARE_AND_SEND_NOTIFICATION_METHOD: before prepare: cookie: $cookie")
                musicService?.prepare(cookie, name, author, url, coverUrl)
                musicService?.sendNotification();
            }
            REMOVE_NOTIFICATION_METHOD -> {
                musicService?.removeNotification();
            }
            SET_VOLUME_METHOD -> {

            }
            GET_DURATION_METHOD -> {
                response.success(musicService?.duration)
                return
            }
            GET_CURRENT_POSITION_METHOD -> {
                response.success(musicService?.currentPosition)
                return
            }
            SET_RELEASE_MODE_METHOD -> {
                val releaseModeName = call.argument<String>(RELEASE_MODE_ARGUMENT)
                val releaseMode = ReleaseMode.valueOf(releaseModeName!!.substring("ReleaseMode.".length))
                musicService?.releaseMode = releaseMode.ordinal
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

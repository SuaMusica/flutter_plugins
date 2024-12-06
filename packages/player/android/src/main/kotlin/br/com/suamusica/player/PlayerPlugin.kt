package br.com.suamusica.player

import android.util.Log
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler


class PlayerPlugin : MethodCallHandler, FlutterPlugin, ActivityAware {

    companion object {
        // Argument names
        const val NAME_ARGUMENT = "name"
        const val AUTHOR_ARGUMENT = "author"
        const val URL_ARGUMENT = "url"
        const val COVER_URL_ARGUMENT = "coverUrl"
        const val BIG_COVER_URL_ARGUMENT = "bigCoverUrl"
        const val IS_PLAYING_ARGUMENT = "isPlaying"
        const val IS_FAVORITE_ARGUMENT = "isFavorite"
        const val FALLBACK_URL = "fallbackURL"
        const val ID_FAVORITE_ARGUMENT = "idFavorite"
        const val NEW_URI_ARGUMENT = "newUri"
        const val ID_URI_ARGUMENT = "idUri"
        const val POSITION_ARGUMENT = "position"
        const val TIME_POSITION_ARGUMENT = "timePosition"
        const val INDEXES_TO_REMOVE = "indexesToDelete"
        const val POSITIONS_LIST = "positionsList"
        const val LOAD_ONLY = "loadOnly"
        const val RELEASE_MODE_ARGUMENT = "releaseMode"
        private const val CHANNEL = "suamusica.com.br/player"
        const val FAVORITE: String = "favorite"

        // Method names
        const val PLAY_METHOD = "play"
        const val SET_REPEAT_MODE = "set_repeat_mode"
        const val ENQUEUE = "enqueue"
        const val REMOVE_ALL = "remove_all"
        const val REMOVE_IN = "remove_in"
        const val REORDER = "reorder"
        const val PLAY_FROM_QUEUE_METHOD = "playFromQueue"
        const val RESUME_METHOD = "resume"
        const val PAUSE_METHOD = "pause"
        const val NEXT_METHOD = "next"
        const val PREVIOUS_METHOD = "previous"
        const val TOGGLE_SHUFFLE = "toggle_shuffle"
        const val REPEAT_MODE = "repeat_mode"
        const val DISABLE_REPEAT_MODE = "disable_repeat_mode"
        const val UPDATE_FAVORITE = "update_favorite"
        const val UPDATE_MEDIA_URI = "update_media_uri"
        const val STOP_METHOD = "stop"
        const val RELEASE_METHOD = "release"
        const val SEEK_METHOD = "seek"
        const val REMOVE_NOTIFICATION_METHOD = "remove_notification"
        const val SET_VOLUME_METHOD = "setVolume"
        const val GET_DURATION_METHOD = "getDuration"
        const val GET_CURRENT_POSITION_METHOD = "getCurrentPosition"
        const val SET_RELEASE_MODE_METHOD = "setReleaseMode"
        const val CAN_PLAY = "can_play"
        const val DISABLE_NOTIFICATION_COMMANDS = "disable_notification_commands"
        const val ENABLE_NOTIFICATION_COMMANDS = "enable_notification_commands"
        const val TAG = "Player"
        const val Ok = 1
        private var alreadyAttachedToActivity: Boolean = false
        var cookie = ""
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        Log.d(TAG, "onAttachedToEngine $alreadyAttachedToActivity")
        if (alreadyAttachedToActivity)
            return
        val channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL)
        val context = flutterPluginBinding.applicationContext
        channel.setMethodCallHandler(this)
        PlayerSingleton.setChannel(channel, context)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        Log.d(TAG, "onDetachedFromEngine")
        PlayerSingleton.channel?.setMethodCallHandler(null)
        PlayerSingleton.channel = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        Log.d(TAG, "onAttachedToActivity")
//        val isStopped = (binding.activity.applicationInfo.flags and ApplicationInfo.FLAG_STOPPED) == ApplicationInfo.FLAG_STOPPED
//        if(!isStopped){
        alreadyAttachedToActivity = true
//        }
    }

    override fun onDetachedFromActivityForConfigChanges() {
        Log.d(TAG, "onDetachedFromActivityForConfigChanges")
    }

    override fun onReattachedToActivityForConfigChanges(p0: ActivityPluginBinding) {
        Log.d(TAG, "onReattachedToActivityForConfigChanges")
    }

    override fun onDetachedFromActivity() {
        Log.d(TAG, "onDetachedFromActivity")
        alreadyAttachedToActivity = false
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
        if (call.method == ENQUEUE) {
            val batch: Map<String, Any> = call.arguments()!!
            cookie = if (batch.containsKey("cookie")) batch["cookie"] as String else cookie
            PlayerSingleton.externalPlayback =
                if (batch.containsKey("externalplayback")) batch["externalplayback"].toString() == "true" else PlayerSingleton.externalPlayback
        } else {
            cookie = call.argument<String>("cookie") ?: cookie
            PlayerSingleton.externalPlayback = call.argument<Boolean>("externalplayback")
        }
        Log.d(
            TAG,
            "method: ${call.method}"
        )
        when (call.method) {
            ENQUEUE -> {
                val batch: Map<String, Any> = call.arguments()!!
                val listMedia: List<Map<String, String>> =
                    batch["batch"] as List<Map<String, String>>
                val autoPlay: Boolean = (batch["autoPlay"] ?: false) as Boolean
                val shouldNotifyTransition: Boolean = (batch["shouldNotifyTransition"] ?: false) as Boolean
                val json = Gson().toJson(listMedia)
                PlayerSingleton.mediaSessionConnection?.enqueue(
                    json,
                    autoPlay,
                    shouldNotifyTransition,
                )
            }

            PLAY_METHOD -> {
                val shouldPrepare = call.argument<Boolean?>("shouldPrepare") ?: false
                PlayerSingleton.mediaSessionConnection?.play(shouldPrepare)
            }

            SET_REPEAT_MODE -> {
                val mode = call.argument<String?>("mode") ?: ""
                PlayerSingleton.mediaSessionConnection?.setRepeatMode(mode)
            }

            REORDER -> {
                val from = call.argument<Int>("oldIndex")
                val to = call.argument<Int>("newIndex")
                val positionsList =
                    call.argument<List<Map<String, Int>>>(POSITIONS_LIST) ?: emptyList()
                if (from != null && to != null) {
                    PlayerSingleton.mediaSessionConnection?.reorder(from, to, positionsList)
                }
            }

            REMOVE_ALL -> {
                PlayerSingleton.mediaSessionConnection?.removeAll()
            }

            REMOVE_IN -> {
                val indexes = call.argument<List<Int>>(INDEXES_TO_REMOVE) ?: emptyList()
                PlayerSingleton.mediaSessionConnection?.removeIn(indexes)
            }

            NEXT_METHOD -> {
                PlayerSingleton.mediaSessionConnection?.next()
            }

            TOGGLE_SHUFFLE -> {
                val positionsList =
                    call.argument<List<Map<String, Int>>>(POSITIONS_LIST) ?: emptyList()
                PlayerSingleton.mediaSessionConnection?.toggleShuffle(positionsList)
            }

            UPDATE_MEDIA_URI ->{
                val id = call.argument<Int>("id") ?: 0
                val uri = call.argument<String>("uri")
                PlayerSingleton.mediaSessionConnection?.updateMediaUri(id,uri)
            }

            REPEAT_MODE -> {
                PlayerSingleton.mediaSessionConnection?.repeatMode()
            }

            DISABLE_REPEAT_MODE -> {
                PlayerSingleton.mediaSessionConnection?.disableRepeatMode()
            }

            PREVIOUS_METHOD -> {
                PlayerSingleton.mediaSessionConnection?.previous()
            }

            UPDATE_FAVORITE -> {
                val isFavorite = call.argument<Boolean?>(IS_FAVORITE_ARGUMENT) ?: false
                val idFavorite = call.argument<Int?>(ID_FAVORITE_ARGUMENT) ?: 0
                PlayerSingleton.mediaSessionConnection?.updateFavorite(isFavorite, idFavorite)
            }

            PLAY_FROM_QUEUE_METHOD -> {
                val position = call.argument<Int>(POSITION_ARGUMENT) ?: 0
                val timePosition = call.argument<Int>(TIME_POSITION_ARGUMENT) ?: 0
                val loadOnly = call.argument<Boolean>(LOAD_ONLY) ?: false
                PlayerSingleton.mediaSessionConnection?.playFromQueue(
                    position,
                    timePosition.toLong(),
                    loadOnly
                )
            }

            RESUME_METHOD -> {
                PlayerSingleton.mediaSessionConnection?.play()
            }

            PAUSE_METHOD -> {
                PlayerSingleton.mediaSessionConnection?.pause()
            }

            "ads_playing" -> {
                PlayerSingleton.mediaSessionConnection?.adsPlaying()
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
                val releaseMode =
                    ReleaseMode.valueOf(releaseModeName!!.substring("ReleaseMode.".length))
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

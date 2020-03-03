package br.com.suamusica.player

import android.content.Context
import android.os.Handler
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.PluginRegistry.Registrar


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
    const val CLEAR_METHOD = "seek"
    const val SET_VOLUME_METHOD = "setVolume"
    const val GET_DURATION_METHOD = "getDuration"
    const val GET_CURRENT_POSITION_METHOD = "getCurrentPosition"
    const val SET_RELEASE_MODE_METHOD = "setReleaseMode"

    const val Ok = 1

    private var playerId : String? = null
    private val players = HashMap<String, Player>()
    private var channel: MethodChannel? = null

    @JvmStatic
    fun registerWith(registrar: Registrar) {
      channel = MethodChannel(registrar.messenger(), "smplayer")
      channel?.setMethodCallHandler(Plugin(channel!!, registrar.context()))
    }

    @JvmStatic
    fun playerId(call: MethodCall): String =
            if (call.hasArgument(PLAYER_ID_ARGUMENT)) call.argument(PLAYER_ID_ARGUMENT)!! else DEFAULT_PLAYER_ID

    private fun getPlayer(playerId: String,
                          context: Context,
                          channel: MethodChannel,
                          plugin: Plugin,
                          handler: Handler,
                          cookie: String?): Player {
      if (!players.containsKey(playerId)) {
        players.clear()
        val player = WrappedExoPlayer(playerId, context, channel, plugin, handler, cookie!!)
        players[playerId] = player
        Plugin.playerId = playerId
      }
      return players[playerId]!!
    }

    @JvmStatic
    fun currentPlayer() : Player? = players.values.firstOrNull()

    @JvmStatic
    fun next() {
      channel?.invokeMethod("commandCenter.onNext", mapOf("playerId" to playerId))
    }

    @JvmStatic
    fun previous() {
      channel?.invokeMethod("commandCenter.onPrevious", mapOf("playerId" to playerId))
    }
  }

  private val handler = Handler()

  override fun onMethodCall(call: MethodCall, response: MethodChannel.Result) {
    try {
      handleMethodCall(call, response)
    } catch (e: Exception) {
      Log.e("SMPlayer", "Unexpected error!", e)
      response.error("Unexpected error!", e.message, e)
    }
  }
  
  private fun handleMethodCall(call: MethodCall, response: MethodChannel.Result) {
    val playerId = playerId(call)
    val cookie = call.argument<String>("cookie")
    Log.i("SMPlayer", "cookie: $cookie")
    val player = getPlayer(playerId, context, channel, this, handler, cookie)
    when (call.method) {
      PLAY_METHOD -> {
        val name = call.argument<String>(NAME_ARGUMENT)!!
        val author = call.argument<String>(AUTHOR_ARGUMENT)!!
        val url = call.argument<String>(URL_ARGUMENT)!!
        val coverUrl = call.argument<String>(COVER_URL_ARGUMENT)!!
        val volume = call.argument<Double>(VOLUME_ARGUMENT)!!
        val position = call.argument<Int>(POSITION_ARGUMENT)
        val stayAwake = call.argument<Boolean>(STAY_AWAKE_ARGUMENT)!!
        val loadOnly = call.argument<Boolean>(LOAD_ONLY)!!
        player.stayAwake = stayAwake
        player.volume = volume
        player.prepare(Media(name, author, url, coverUrl))
        if (position != null) {
          player.seek(position)
        }
        if (!loadOnly) {
          player.play()
        }
      }
      RESUME_METHOD -> {
        player.play()
      }
      PAUSE_METHOD -> {
        player.pause()
      }
      STOP_METHOD -> {
        player.stop()
      }
      RELEASE_METHOD -> {
        player.release()
      }
      SEEK_METHOD -> {
        val position = call.argument<Int>(POSITION_ARGUMENT)!!
        player.seek(position)
      }
      CLEAR_METHOD -> {
        return
      }
      SET_VOLUME_METHOD -> {
        val volume = call.argument<Double>(VOLUME_ARGUMENT)!!
        player.volume = volume
      }
      GET_DURATION_METHOD -> {
        response.success(player.duration)
        return
      }
      GET_CURRENT_POSITION_METHOD -> {
        response.success(player.currentPosition)
        return
      }
      SET_RELEASE_MODE_METHOD -> {
        val releaseModeName = call.argument<String>(RELEASE_MODE_ARGUMENT)
        val releaseMode = ReleaseMode.valueOf(releaseModeName!!.substring("ReleaseMode.".length))
        player.releaseMode = releaseMode
      }
      else -> {
        response.notImplemented()
        return
      }
    }
    response.success(Ok)
  }
}

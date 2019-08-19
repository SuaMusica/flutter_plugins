package br.com.suamusica.player

import android.app.Activity
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.PluginRegistry.Registrar


class Plugin : MethodCallHandler {
  companion object {
    // Argument names
    const val PLAYER_ID_ARGUMENT = "playerId"
    const val DEFAULT_PLAYER_ID = "default"
    const val URL_ARGUMENT = "url"
    const val VOLUME_ARGUMENT = "volume"
    const val POSITION_ARGUMENT = "position"
    const val STAY_AWAKE_ARGUMENT = "stayAwake"
    const val RELEASE_MODE_ARGUMENT = "releaseMode"

    // Method names
    const val PLAY_METHOD = "play"
    const val RESUME_METHOD = "resume"
    const val PAUSE_METHOD = "pause"
    const val STOP_METHOD = "stop"
    const val RELEASE_METHOD = "release"
    const val SEEK_METHOD = "seek"
    const val SET_VOLUME_METHOD = "setVolume"
    const val GET_DURATION_METHOD = "getDuration"
    const val GET_CURRENT_POSITION_METHOD = "getCurrentPosition"
    const val SET_RELEASE_MODE_METHOD = "setReleaseMode"

    @JvmStatic
    fun registerWith(registrar: Registrar) {
      val channel = MethodChannel(registrar.messenger(), "suamusica_player")
      channel.setMethodCallHandler(Plugin(channel, registrar.activity()))
    }
  }

  private constructor(channel: MethodChannel, activity: Activity) {
    this.channel = channel
    this.activity = activity
  }

  private val channel: MethodChannel
  private val activity: Activity

  private val players = HashMap<String, Player>()

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
    val player = getPlayer(playerId!!, cookie)
    when (call.method) {
      PLAY_METHOD -> {
        val url = call.argument<String>(URL_ARGUMENT)!!
        val volume = call.argument<Double>(VOLUME_ARGUMENT)!!
        val position = call.argument<Int>(POSITION_ARGUMENT)
        val stayAwake = call.argument<Boolean>(STAY_AWAKE_ARGUMENT)!!
        player.stayAwake = stayAwake
        player.volume = volume
        player.prepare(url)
        if (position != null) {
          player.seek(position)
        }
        player.play()
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
    response.success(1)
  }

  private fun playerId(call: MethodCall): String =
          if (call.hasArgument(PLAYER_ID_ARGUMENT)) call.argument(PLAYER_ID_ARGUMENT)!! else DEFAULT_PLAYER_ID

  private fun getPlayer(playerId: String, cookie: String?): Player {
    if (!players.containsKey(playerId)) {
      val player = WrappedExoPlayer(playerId, activity, cookie!!)
      players[playerId] = player
    }
    return players[playerId]!!
  }
}

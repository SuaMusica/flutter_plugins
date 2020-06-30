package br.com.suamusica.player

import io.flutter.plugin.common.MethodChannel

class MethodChannelManager(private val channel: MethodChannel) {

    fun notifyPositionChange(playerId: String, position: Long, duration: Long) {
        val args = ArgsBuilder()
                .playerId(playerId)
                .position(position)
                .duration(duration)
                .build()

        invokeMethod("audio.onCurrentPosition", args)
    }

    fun notifyPlayerStateChange(playerId: String, state: PlayerState, error: String? = null) {
        val args = ArgsBuilder()
                .playerId(playerId)
                .state(state)
                .error(error)
                .build()

        invokeMethod("state.change", args)
    }

    fun notifyNext(playerId: String) {
        val args = ArgsBuilder()
                .playerId(playerId)
                .build()
        invokeMethod("commandCenter.onNext", args)
    }
    fun notifyPrevious(playerId: String) {
        val args = ArgsBuilder()
                .playerId(playerId)
                .build()
        invokeMethod("commandCenter.onPrevious", args)
    }


    private fun invokeMethod(method: String, args: Map<String, Any>) {
        channel.invokeMethod(method, args)
    }

}
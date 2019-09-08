package br.com.suamusica.player

import io.flutter.plugin.common.MethodChannel

class MethodChannelManager(val channel: MethodChannel) {

    fun notifyPositionChange(playerId: String, position: Long, duration: Long) {
        val args = ArgsBuilder()
                .playerId(playerId)
                .position(position)
                .duration(duration)
                .build()

        invokeMethod("audio.onCurrentPosition", args)
    }

    fun notifyPlayerStateChange(playerId: String, state: PlayerState) {
        val args = ArgsBuilder()
                .playerId(playerId)
                .state(state)
                .build()

        invokeMethod("state.change", args)
    }


    private fun invokeMethod(method: String, args: Map<String, Any>) {
        channel.invokeMethod(method, args)
    }

}
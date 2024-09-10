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
    fun notifyItemTransition(playerId: String) {
        val args = ArgsBuilder()
            .playerId(playerId)
            .state(PlayerState.ITEM_TRANSITION)
            .build()
        invokeMethod("state.change", args)
    }

    fun sendCurrentQueue(
        idSum: Long,
        playerId: String,
    ) {
        val args = MethodChannelManagerArgsBuilder()
            .event("CURRENT_QUEUE")
            .playerId(playerId)
            .idSum(idSum)
            .build()
        invokeMethod("GET_INFO", args)
    }


    private fun invokeMethod(method: String, args: Map<String, Any>) {
        channel.invokeMethod(method, args)
    }

    fun currentMediaIndex(playerId: String, currentMediaIndex: Int) {
        val args = MethodChannelManagerArgsBuilder()
            .playerId(playerId)
            .currentMediaIndex(currentMediaIndex)
            .build()
        invokeMethod("SET_CURRENT_MEDIA_INDEX", args)
    }
    fun onRepeatChanged(playerId: String, repeatMode: Int) {
        val args = MethodChannelManagerArgsBuilder()
            .playerId(playerId)
            .repeatMode(repeatMode)
            .build()
        invokeMethod("REPEAT_CHANGED", args)
    }
    fun onShuffleModeEnabled(playerId: String, shuffleModeEnabled: Boolean) {
        val args = MethodChannelManagerArgsBuilder()
            .playerId(playerId)
            .shuffleModeEnabled(shuffleModeEnabled)
            .build()
        invokeMethod("SHUFFLE_CHANGED", args)
    }

}
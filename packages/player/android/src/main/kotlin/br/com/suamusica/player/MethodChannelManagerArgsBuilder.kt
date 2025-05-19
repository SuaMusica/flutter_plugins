package br.com.suamusica.player

class MethodChannelManagerArgsBuilder {

    private val args = mutableMapOf<String, Any>()

    fun build() = args

    fun event(event: String): MethodChannelManagerArgsBuilder {
        args["EVENT_ARGS"] = event
        return this
    }
    fun playerId(id: String): MethodChannelManagerArgsBuilder {
        args["playerId"] = id
        return this
    }  

    fun currentMediaIndex(index: Int): MethodChannelManagerArgsBuilder {
        args["CURRENT_MEDIA_INDEX"] = index
        return this
    }

    fun repeatMode(repeatMode: Int): MethodChannelManagerArgsBuilder {
        args["REPEAT_MODE"] = repeatMode
        return this
    }

    fun shuffleModeEnabled(shuffleModeEnabled: Boolean): MethodChannelManagerArgsBuilder {
        args["SHUFFLE_MODE"] = shuffleModeEnabled
        return this
    }

    fun idSum(idSum: Long): MethodChannelManagerArgsBuilder {
        args["ID_SUM"] = idSum
        return this
    }
}
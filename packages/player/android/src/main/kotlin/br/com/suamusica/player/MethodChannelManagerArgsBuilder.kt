package br.com.suamusica.player

import com.google.gson.Gson

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

    fun queue(queue: List<Media>): MethodChannelManagerArgsBuilder {
        args["QUEUE_ARGS"] = Gson().toJson(queue)
        return this
    }
}
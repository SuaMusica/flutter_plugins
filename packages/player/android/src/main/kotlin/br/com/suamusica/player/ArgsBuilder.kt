package br.com.suamusica.player

import java.util.*

class ArgsBuilder {
    private val args = mutableMapOf<String, Any>()

    fun playerId(id: String): ArgsBuilder {
        args["playerId"] = id
        return this
    }

    fun position(position: Long): ArgsBuilder {
        args["position"] = position
        return this
    }

    fun duration(duration: Long): ArgsBuilder {
        args["duration"] = duration
        return this
    }

    fun state(state: PlayerState): ArgsBuilder {
        args["state"] = state.ordinal
        return this
    }

    fun error(error: String?): ArgsBuilder {
        error?.let { value ->
            args["error"] = value
        }
        return this
    }


    fun build() = Collections.unmodifiableMap(args)
}
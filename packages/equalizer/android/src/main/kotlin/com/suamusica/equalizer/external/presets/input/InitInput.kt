package com.suamusica.equalizer.external.presets.input

import com.suamusica.equalizer.extensions.getRequired

data class InitInput(val sessionId: Int, val presetInputs: List<PresetInput>) {

    private constructor(args: Map<String, Any>)
            : this(
            args.getRequired(SESSION_ID),
            args.getRequired<List<Any>>(PRESETS).map { PresetInput(it) }
    )

    @Suppress("UNCHECKED_CAST")
    constructor(args: Any) : this(
            args = args as Map<String, Any>)

    companion object {
        private const val SESSION_ID = "session_id"
        private const val PRESETS = "presets"
    }
}
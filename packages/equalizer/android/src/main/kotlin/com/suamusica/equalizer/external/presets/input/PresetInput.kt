package com.suamusica.equalizer.external.presets.input

import com.suamusica.equalizer.extensions.getRequired

data class PresetInput(val name: String, val bandInputs: List<BandInput>) {

    private constructor(args: Map<String, Any>)
            : this(
            args.getRequired(NAME),
            args.getRequired<List<Any>>(BANDS).map { BandInput(it) }
    )

    @Suppress("UNCHECKED_CAST")
    constructor(args: Any) : this(
            args = args as Map<String, Any>)

    companion object {
        private const val NAME = "preset.name"
        private const val BANDS = "preset.bands"
    }
}
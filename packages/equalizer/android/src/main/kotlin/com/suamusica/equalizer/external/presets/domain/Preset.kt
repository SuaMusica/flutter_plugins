package com.suamusica.equalizer.external.presets.domain

import com.suamusica.equalizer.extensions.getRequired

data class Preset(val name: String, val bands: List<Band>) {

    private constructor(args: Map<String, Any>)
            : this(
            args.getRequired(NAME),
            args.getRequired<List<Any>>(BANDS).map { Band(it) }
    )

    @Suppress("UNCHECKED_CAST")
    constructor(args: Any) : this(
            args = args as Map<String, Any>)

    companion object {
        private const val NAME = "preset.name"
        private const val BANDS = "preset.bands"
    }
}
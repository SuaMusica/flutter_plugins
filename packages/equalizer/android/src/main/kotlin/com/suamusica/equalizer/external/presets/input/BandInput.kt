package com.suamusica.equalizer.external.presets.input

import com.suamusica.equalizer.extensions.getRequired
import com.suamusica.equalizer.extensions.getValueOrNull
import kotlin.math.absoluteValue
import kotlin.math.roundToInt

data class BandInput(val desiredLevel: Int?, val levelPercent: Int) {

    fun getLevel(maxDb: Int): Int {

        desiredLevel?.let {
            if (it.absoluteValue <= maxDb) {
                return it
            }
        }

        return (maxDb * levelPercent / 100.0).roundToInt()
    }

    private constructor(args: Map<String, Any>)
            : this(
            args.getValueOrNull(DESIRED_LEVEL),
            args.getRequired(LEVEL_PERCENT)
    )

    @Suppress("UNCHECKED_CAST")
    constructor(args: Any) : this(
            args = args as Map<String, Any>)


    companion object {
        private const val DESIRED_LEVEL = "band.desired_level"
        private const val LEVEL_PERCENT = "band.level_percent"
    }

}
package com.suamusica.equalizer.external.presets.domain

import com.suamusica.equalizer.extensions.getRequired

data class Band(val position: Int, val levelPercent: Int) {

    fun getLevel(maxDb: Int): Int {
        return maxDb * levelPercent / 100
    }

    private constructor(args: Map<String, Any>)
            : this(
            args.getRequired(POSITION),
            args.getRequired(LEVEL_PERCENT)
    )

    @Suppress("UNCHECKED_CAST")
    constructor(args: Any) : this(
            args = args as Map<String, Any>)


    companion object {
        private const val POSITION = "band.position"
        private const val LEVEL_PERCENT = "band.level_percent"
    }

}

data class AndroidEqualizerLevelRange(val min: Int, val max: Int)
data class AndroidEqualizerBand(val position: Int, val level: Int)

val Int.isEven get() = (this % 2 == 0)

fun List<Band>.toAndroidEqualizerBand(
        numberOfAndroidBands: Int,
        maxDb: Int
): List<AndroidEqualizerBand> {

    when {
        numberOfAndroidBands == this.size -> {
            return this.mapIndexed { index, band -> AndroidEqualizerBand(index, band.getLevel(maxDb)) }
        }
        numberOfAndroidBands > this.size -> {

            val diff = numberOfAndroidBands - this.size
            val startIndex: Int
            val endIndex: Int

            if (diff.isEven) {
                startIndex = diff / 2
                endIndex = numberOfAndroidBands - startIndex
            } else {
                startIndex = diff / 2
                endIndex = numberOfAndroidBands - startIndex - 1
            }

            val leftFlatBands = (0 until startIndex).map { AndroidEqualizerBand(it, 0) }
            val customizedBands = (startIndex until endIndex).map {
                val bandIndex = it - startIndex
                val band = this[bandIndex]
                AndroidEqualizerBand(it, band.getLevel(maxDb))
            }
            val rightFlatBands = (endIndex until numberOfAndroidBands).map { AndroidEqualizerBand(it, 0) }

            return mutableListOf<AndroidEqualizerBand>().also {
                it.addAll(leftFlatBands)
                it.addAll(customizedBands)
                it.addAll(rightFlatBands)
            }

        }
        else -> {

            val diff = this.size - numberOfAndroidBands
            val startIndex: Int
            val endIndex: Int

            if (diff.isEven) {
                startIndex = diff / 2
                endIndex = this.size - startIndex
            } else {
                startIndex = diff / 2
                endIndex = this.size - startIndex - 1
            }

            return (startIndex until endIndex).mapIndexed { index, it ->
                val band = this[it]
                AndroidEqualizerBand(index, band.getLevel(maxDb))
            }
        }
    }
}
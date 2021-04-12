package com.suamusica.equalizer.extensions

import com.suamusica.equalizer.external.presets.domain.Band
import com.suamusica.equalizer.external.presets.domain.Preset
import com.suamusica.equalizer.external.presets.input.BandInput
import com.suamusica.equalizer.external.presets.input.PresetInput

fun List<PresetInput>.toDomainPresetList(numberOfAndroidBands: Int, maxDb: Int): List<Preset> {
    return this.map {
        Preset(
                name = it.name,
                bands = it.bandInputs.toDomainBandList(
                        numberOfAndroidBands = numberOfAndroidBands,
                        maxDb = maxDb
                )
        )
    }
}

val Int.isEven get() = (this % 2 == 0)

fun List<BandInput>.toDomainBandList(
        numberOfAndroidBands: Int,
        maxDb: Int
): List<Band> {

    when {
        numberOfAndroidBands == this.size -> {
            return this.mapIndexed { bandId, bandInput -> Band(bandId, bandInput.getLevel(maxDb)) }
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

            val leftFlatBands = (0 until startIndex).map { bandId -> Band(bandId, 0) }
            val customizedBands = (startIndex until endIndex).map { bandId ->
                val bandIndex = bandId - startIndex
                val bandInput = this[bandIndex]
                Band(bandId, bandInput.getLevel(maxDb))
            }
            val rightFlatBands = (endIndex until numberOfAndroidBands).map { bandId -> Band(bandId, 0) }

            return mutableListOf<Band>().also {
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

            return (startIndex until endIndex).mapIndexed { bandId, bandIndex ->
                val band = this[bandIndex]
                Band(bandId, band.getLevel(maxDb))
            }
        }
    }
}
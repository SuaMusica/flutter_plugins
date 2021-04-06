package com.suamusica.equalizer

import android.media.audiofx.Equalizer

class CustomEQ {

    companion object {
        private var equalizer: Equalizer? = null

        fun init(sessionId: Int) {
            equalizer = Equalizer(0, sessionId)
        }

        fun enable(enable: Boolean) {
            equalizer?.enabled = enable
        }

        val isEnabled get() = equalizer?.enabled ?: false

        fun release() {
            equalizer?.release()
        }

        /**
         * Returns an array with two positions with range
         * Example -10db and 10db
         */
        val bandLevelRange: List<Int> get() =
            equalizer?.bandLevelRange?.map { it / 100 } ?: emptyList()

        fun getBandLevel(bandId: Int): Int {
            return equalizer?.let { it.getBandLevel(bandId.toShort()) / 100 } ?: 0
        }

        fun setBandLevel(bandId: Int, level: Int) {
            equalizer?.setBandLevel(bandId.toShort(), (level * 100).toShort())
        }

        val numberOfBands by lazy { equalizer?.numberOfBands?.toInt() ?: 0 }

        val centerBandFreqs by lazy {
            val bands = mutableListOf<Int>()
            for (i in 0 until numberOfBands) {
                equalizer?.getCenterFreq(i.toShort())?.let { bands.add(it) }
            }
            bands
        }

        val presetNames by lazy {
            val numberOfPresets = equalizer?.numberOfPresets ?: 0
            val presets = mutableListOf<String>()
            for (i in 0 until numberOfPresets) {
                equalizer?.getPresetName(i.toShort())?.let { presets.add(it) }
            }
            presets
        }

        fun setPreset(presetName: String?) {
            equalizer?.usePreset(presetNames.indexOf(presetName).toShort())
        }

        val currentPreset get() = equalizer?.currentPreset ?: -1
    }


}
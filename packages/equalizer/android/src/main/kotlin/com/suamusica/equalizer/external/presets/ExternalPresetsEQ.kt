package com.suamusica.equalizer.external.presets

import android.media.audiofx.Equalizer

class ExternalPresetsEQ(val preferences: ExternalPresetsEQPreferences) {

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
    val bandLevelRange: List<Int>
        get() =
            equalizer?.bandLevelRange?.map { it / 100 } ?: emptyList()

    fun getBandLevel(bandId: Int): Int {
        return equalizer?.let { it.getBandLevel(bandId.toShort()) / 100 } ?: 0
    }

    fun setBandLevel(bandId: Int, level: Int) {
        equalizer?.setBandLevel(bandId.toShort(), (level * 100).toShort())
    }
}
package com.suamusica.equalizer.external.presets.domain

import com.google.gson.annotations.SerializedName

data class Preset(
    @SerializedName("name") val name: String,
    @SerializedName("bands") val bands: List<Band>? = null,
) {
    fun bandsOrEmpty(): List<Band> = bands.orEmpty()
}

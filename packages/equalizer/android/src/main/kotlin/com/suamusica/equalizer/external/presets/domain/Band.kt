package com.suamusica.equalizer.external.presets.domain

import com.google.gson.annotations.SerializedName

data class Band(
    @SerializedName("id") val id: Int,
    @SerializedName("level") val level: Int,
)

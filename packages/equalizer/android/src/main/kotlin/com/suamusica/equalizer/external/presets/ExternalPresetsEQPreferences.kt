package com.suamusica.equalizer.external.presets

import android.content.Context
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import com.suamusica.equalizer.external.presets.domain.Band
import com.suamusica.equalizer.external.presets.domain.Preset

class ExternalPresetsEQPreferences(context: Context) {

    companion object {
        private const val SHARED_PREFERENCE_NAME = "ExternalPresetsEQPreferences"
        private const val PRESETS_KEY = "presets"
        private const val ENABLED_KEY = "enabled"
        private const val CURRENT_PRESET_KEY = "presets"
        private val INITIAL_CUSTOM_PRESET = Preset(name = "Custom", bands = List(11) { Band(it, 0) })
    }

    private val gson = Gson()
    private val preferences = context.getSharedPreferences(SHARED_PREFERENCE_NAME, Context.MODE_PRIVATE)


    fun init(availablePresets: List<Preset>) {
        setAvailablePresets(availablePresets)
    }

    fun setEnabled(enabled: Boolean) {
        preferences.edit().putBoolean(ENABLED_KEY, enabled).apply()
    }

    fun isEnabled(): Boolean {
        return preferences.getBoolean(ENABLED_KEY, false)
    }

    private fun setAvailablePresets(presets: List<Preset>) {
        val jsonString = gson.toJson(presets)
        preferences.edit().putString(PRESETS_KEY, jsonString).apply()
    }

    fun getAvailablePresets(): List<Preset> {
        val jsonString = preferences.getString(PRESETS_KEY, null)
        val typeToken = object : TypeToken<List<Preset>>() {}
        val result = mutableListOf<Preset>()
        val presets = jsonString?.let { gson.fromJson<List<Preset>>(it, typeToken.type) }
                ?: emptyList()
        result.addAll(presets)
        result.add(INITIAL_CUSTOM_PRESET)
        return result
    }

    fun selectPreset(name: String) {
        getAvailablePresets().find { it.name == name }?.let {
            preferences.edit().putString(CURRENT_PRESET_KEY, gson.toJson(it))
        }
    }

    fun getCurrentPreset(): Preset {
        val jsonString = preferences.getString(CURRENT_PRESET_KEY, null)
        return jsonString?.let { gson.fromJson(jsonString, Preset::class.java) }
                ?: getAvailablePresets().first()
    }

    fun getCurrentPresetIndex(): Int {
        val currentPreset = getCurrentPreset()
        return getAvailablePresets().indexOfFirst { it.name == currentPreset.name }
    }

    fun setBandLevel(band: Band) {
        getCurrentPreset().bands
    }
}
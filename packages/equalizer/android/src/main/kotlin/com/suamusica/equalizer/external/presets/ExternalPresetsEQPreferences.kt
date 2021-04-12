package com.suamusica.equalizer.external.presets

import android.content.Context
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import com.suamusica.equalizer.external.presets.domain.Band
import com.suamusica.equalizer.external.presets.domain.Preset

class ExternalPresetsEQPreferences(context: Context) {

    companion object {
        private const val SHARED_PREFERENCE_NAME = "ExternalPresetsEQPreferences"
        private const val USER_PRESETS_KEY = "user_presets"
        private const val ENABLED_KEY = "enabled"
        private const val CURRENT_PRESET_KEY = "current_preset"
        private const val CUSTOM_PRESET_KEY = "custom_preset"
        private const val CUSTOM_PRESET_NAME = "Custom"
    }

    private val gson = Gson()
    private val preferences = context.getSharedPreferences(SHARED_PREFERENCE_NAME, Context.MODE_PRIVATE)


    fun init(userPresets: List<Preset>) {
        setUserPresets(userPresets)
        updateCurrentPreset()
    }

    private fun updateCurrentPreset() {
        val currentPreset = getCurrentPreset()
        setCurrentPresetByName(currentPreset.name)
    }

    fun setEnabled(enabled: Boolean) {
        preferences.edit().putBoolean(ENABLED_KEY, enabled).apply()
    }

    fun isEnabled(): Boolean {
        return preferences.getBoolean(ENABLED_KEY, false)
    }

    private fun setUserPresets(Presets: List<Preset>) {
        val jsonString = gson.toJson(Presets)
        preferences.edit().putString(USER_PRESETS_KEY, jsonString).apply()
    }

    private fun getUserPresets(): List<Preset> {
        val availablePresetsJsonString = preferences.getString(USER_PRESETS_KEY, null)
        val typeToken = object : TypeToken<List<Preset>>() {}
        return availablePresetsJsonString?.let { gson.fromJson<List<Preset>>(it, typeToken.type) }
                ?: emptyList()
    }

    fun getAvailablePresets(): List<Preset> {
        val result = mutableListOf<Preset>()
        result.addAll(getUserPresets())
        result.add(getCustomPreset())
        return result
    }

    fun setCurrentPresetByName(name: String) {
        val availablePresets = getAvailablePresets()
        val preset = availablePresets.find { it.name == name }
        setCurrentPreset(preset ?: availablePresets.first())
    }

    private fun setCurrentPreset(preset: Preset) {
        preferences.edit().putString(CURRENT_PRESET_KEY, gson.toJson(preset)).apply()
    }

    fun getCurrentPreset(): Preset {
        val jsonString = preferences.getString(CURRENT_PRESET_KEY, null)
        return jsonString?.let { gson.fromJson<Preset>(jsonString, Preset::class.java) }
                ?: getUserPresets().first()
    }

    fun getCurrentPresetIndex(): Int {
        val currentPreset = getCurrentPreset()
        return getAvailablePresets().indexOfFirst { it.name == currentPreset.name }
    }

    fun setBandLevel(newBand: Band) {
        val currentPreset = getCurrentPreset()
        val customPresetBands = currentPreset.bands.map {
            if (it.id == newBand.id) {
                newBand
            } else {
                it
            }
        }
        setCustomPresetBands(customPresetBands)
        setCurrentPresetByName(name = CUSTOM_PRESET_NAME)
    }

    private fun getCustomPreset(): Preset {
        val jsonString = preferences.getString(CUSTOM_PRESET_KEY, null)
        return jsonString?.let { gson.fromJson(jsonString, Preset::class.java) }
                ?: Preset(
                        name = CUSTOM_PRESET_NAME,
                        bands = List(getUserPresets().first().bands.size) { Band(it, 0) }
                )
    }

    private fun setCustomPresetBands(presetBands: List<Band>) {
        val preset = Preset(name = CUSTOM_PRESET_NAME, bands = presetBands)
        preferences.edit().putString(CUSTOM_PRESET_KEY, gson.toJson(preset)).apply()
    }
}
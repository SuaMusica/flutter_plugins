package com.suamusica.equalizer.external.presets

import com.suamusica.equalizer.AudioEffectUtil
import com.suamusica.equalizer.CustomEQ
import com.suamusica.equalizer.external.presets.domain.Band
import com.suamusica.equalizer.external.presets.domain.InitInput
import com.suamusica.equalizer.external.presets.domain.Preset
import com.suamusica.equalizer.external.presets.domain.toAndroidEqualizerBand
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class ExternalPresetsEQMethodCallHandler(
        private val externalPresetsEQPreferences: ExternalPresetsEQPreferences,
        private val audioEffectUtil: AudioEffectUtil
) : MethodChannel.MethodCallHandler {

    companion object {
        const val OK = 0
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {

        when (call.method.split(".").last()) {
            "open" -> result.notImplemented()
            "setAudioSessionId" -> {
                audioEffectUtil.setAudioSessionId(call.arguments as Int)
                result.success(OK)
            }
            "deviceHasEqualizer" -> {
                val sessionId = call.argument<Int>("audioSessionId") ?: 0
                val deviceHasEqualizer = audioEffectUtil.deviceHasEqualizer(sessionId)
                result.success(deviceHasEqualizer)
            }
            "removeAudioSessionId" -> audioEffectUtil.removeAudioSessionId(call.arguments as Int)
            "init" -> {
                val initInput = InitInput(call.arguments)

                CustomEQ.init(initInput.sessionId)
                CustomEQ.enable(externalPresetsEQPreferences.isEnabled())
                val numberOfAndroidBands = CustomEQ.numberOfBands
                val levelRange = CustomEQ.bandLevelRange
                val maxDb = levelRange.last()

                val presets = initInput.presets.map { preset ->
                    val bands: List<Band> = preset.bands.toAndroidEqualizerBand(numberOfAndroidBands, maxDb)
                            .map { androidEQBand ->
                                Band(desiredLevel = androidEQBand.level, levelPercent = androidEQBand.levelPercent)
                            }
                    Preset(name = preset.name, bands = bands)
                }

                externalPresetsEQPreferences.init(presets)
                val currentPreset = externalPresetsEQPreferences.getCurrentPreset()
                currentPreset.bands.forEachIndexed { id, band -> CustomEQ.setBandLevel(id, band.getLevel(maxDb))}

                result.success(OK)
            }
            "enable" -> {
                val enabled = call.arguments as Boolean
                externalPresetsEQPreferences.setEnabled(enabled)
                CustomEQ.enable(enabled)
                result.success(OK)
            }
            "isEnabled" -> result.success(CustomEQ.isEnabled)
            "release" -> {
                CustomEQ.release()
                result.success(OK)
            }
            "getBandLevelRange" -> result.success(CustomEQ.bandLevelRange)
            "getCenterBandFreqs" -> result.success(CustomEQ.centerBandFreqs)
            "getPresetNames" -> result.success(externalPresetsEQPreferences.getAvailablePresets().map { it.name })
            "getBandLevel" -> {
                val bandId = call.arguments as Int
                val levelRange = CustomEQ.bandLevelRange
                val level = externalPresetsEQPreferences.getCurrentPreset()
                        .bands[bandId].getLevel(maxDb = levelRange.last())
                result.success(level)
            }
            "setBandLevel" -> {
                val bandId = call.argument<Int>("bandId")
                val level = call.argument<Int>("level")
                bandId?.let {
                    level?.let {
                        // TODO()
                        externalPresetsEQPreferences.getCurrentPreset()
                        CustomEQ.setBandLevel(bandId, level)
                    }
                }
                result.success(OK)
            }
            "setPreset" -> {
                CustomEQ.setPreset(call.arguments as String)
                result.success(OK)
            }
            "getCurrentPreset" -> {
                result.success(CustomEQ.currentPreset)
            }
            else -> result.notImplemented()
        }
    }
}
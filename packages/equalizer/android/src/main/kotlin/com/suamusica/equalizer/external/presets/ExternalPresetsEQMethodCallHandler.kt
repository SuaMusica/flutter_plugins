package com.suamusica.equalizer.external.presets

import com.suamusica.equalizer.AudioEffectUtil
import com.suamusica.equalizer.CustomEQ
import com.suamusica.equalizer.VibratorHelper
import com.suamusica.equalizer.extensions.toDomainPresetList
import com.suamusica.equalizer.external.presets.domain.Band
import com.suamusica.equalizer.external.presets.input.InitInput
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class ExternalPresetsEQMethodCallHandler(
        private val externalPresetsEQPreferences: ExternalPresetsEQPreferences,
        private val audioEffectUtil: AudioEffectUtil,
        private val vibratorHelper: VibratorHelper
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
                CustomEQ.enable(true)
                val numberOfAndroidBands = CustomEQ.numberOfBands
                val levelRange = CustomEQ.bandLevelRange
                val maxDb = levelRange.last()

                val presets = initInput.presetInputs.toDomainPresetList(numberOfAndroidBands, maxDb)

                externalPresetsEQPreferences.init(presets)
                setCurrentPresetIntoAndroidEqualizer()
                CustomEQ.enable(externalPresetsEQPreferences.isEnabled())
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
                val level = externalPresetsEQPreferences.getCurrentPreset()
                        .bands
                        .find { it.id == bandId }?.level ?: 0
                result.success(level)
            }
            "setBandLevel" -> {
                val bandId = call.argument<Int>("bandId")
                val level = call.argument<Int>("level")
                bandId?.let {
                    level?.let {
                        externalPresetsEQPreferences.setBandLevel(Band(id = bandId, level = level))
                        CustomEQ.setBandLevel(bandId, level)
                    }
                }
                result.success(OK)
            }
            "setPreset" -> {
                val presetName = call.arguments as String
                externalPresetsEQPreferences.setCurrentPresetByName(name = presetName)
                setCurrentPresetIntoAndroidEqualizer()
                result.success(OK)
            }
            "getCurrentPreset" -> {
                result.success(externalPresetsEQPreferences.getCurrentPresetIndex())
            }
            "vibrate" -> {
                val milliseconds = call.argument<Int>("milliseconds") ?: 0
                val amplitude = call.argument<Int>("amplitude") ?: 0
                vibratorHelper.vibrate(milliseconds = milliseconds.toLong(), amplitude = amplitude)
                result.success(OK)
            }
            else -> result.notImplemented()
        }
    }

    private fun setCurrentPresetIntoAndroidEqualizer() {
        val currentPreset = externalPresetsEQPreferences.getCurrentPreset()
        currentPreset.bands.forEach { band -> CustomEQ.setBandLevel(band.id, band.level) }
    }
}
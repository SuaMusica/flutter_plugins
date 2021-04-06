package com.suamusica.equalizer.external.presets

import com.suamusica.equalizer.AudioEffectUtil
import com.suamusica.equalizer.CustomEQ
import com.suamusica.equalizer.external.presets.domain.AndroidEqualizerLevelRange
import com.suamusica.equalizer.external.presets.domain.InitInput
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
                externalPresetsEQPreferences.init(initInput.presets)
                CustomEQ.init(initInput.sessionId)
                CustomEQ.enable(externalPresetsEQPreferences.isEnabled())
                val currentPreset = externalPresetsEQPreferences.getCurrentPreset()
                val levelRange = CustomEQ.bandLevelRange
                val androidEqualizerBandList = currentPreset.bands.toAndroidEqualizerBand(CustomEQ.numberOfBands, levelRange.last())
                androidEqualizerBandList.forEach { CustomEQ.setBandLevel(it.position, it.level) }
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
            "getPresetNames" -> result.success(CustomEQ.presetNames)
            "getBandLevel" -> result.success(CustomEQ.getBandLevel(call.arguments as Int))
            "setBandLevel" -> {
                val bandId = call.argument<Int>("bandId")
                val level = call.argument<Int>("level")
                bandId?.let {
                    level?.let {
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
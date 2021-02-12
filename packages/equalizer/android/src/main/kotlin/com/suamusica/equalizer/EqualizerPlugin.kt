package com.suamusica.equalizer

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.media.audiofx.AudioEffect
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** EqualizerPlugin */
class EqualizerPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {

    companion object {
        const val OK = 0
        const val TAG = "EqualizerPlugin"
    }

    private lateinit var channel: MethodChannel
    private var applicationContext: Context? = null
    private var activity: Activity? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "equalizer")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {

        Log.d(TAG, "call.method: ${call.method}")
        when (call.method) {
            "open" -> {
                val sessionId = call.argument<Int>("audioSessionId") ?: 0
                val contentType = call.argument<Int>("contentType") ?: 0
                displayDeviceEqualizer(sessionId, contentType, result)
            }
            "setAudioSessionId" -> {
                setAudioSessionId(call.arguments as Int)
                result.success(OK)
            }
            "deviceHasEqualizer" -> {
                val sessionId = call.argument<Int>("audioSessionId") ?: 0
                val deviceHasEqualizer = deviceHasEqualizer(sessionId)
                result.success(deviceHasEqualizer)
            }
            "removeAudioSessionId" -> removeAudioSessionId(call.arguments as Int)
            "init" -> {
                CustomEQ.init(call.arguments as Int)
                result.success(OK)
            }
            "enable" -> {
                CustomEQ.enable(call.arguments as Boolean)
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

    private fun displayDeviceEqualizer(sessionId: Int, contentType: Int, result: Result) {
        val intent = Intent(AudioEffect.ACTION_DISPLAY_AUDIO_EFFECT_CONTROL_PANEL)
        intent.putExtra(AudioEffect.EXTRA_PACKAGE_NAME, applicationContext!!.packageName)
        intent.putExtra(AudioEffect.EXTRA_AUDIO_SESSION, sessionId)
        intent.putExtra(AudioEffect.EXTRA_CONTENT_TYPE, contentType)
        if (intent.resolveActivity(applicationContext!!.packageManager) != null) {
            activity!!.startActivityForResult(intent, 0)
        } else {
            result.error("EQ",
                    "No equalizer found!",
                    "This device may lack equalizer functionality."
            )
        }
    }

    private fun deviceHasEqualizer(sessionId: Int): Boolean {
        val intent = Intent(AudioEffect.ACTION_DISPLAY_AUDIO_EFFECT_CONTROL_PANEL)
        intent.putExtra(AudioEffect.EXTRA_PACKAGE_NAME, applicationContext?.packageName)
        intent.putExtra(AudioEffect.EXTRA_AUDIO_SESSION, sessionId)
        return applicationContext?.packageManager?.let { intent.resolveActivity(it) != null }
                ?: false
    }

    private fun setAudioSessionId(sessionId: Int) {
        val i = Intent(AudioEffect.ACTION_OPEN_AUDIO_EFFECT_CONTROL_SESSION)
        i.putExtra(AudioEffect.EXTRA_PACKAGE_NAME, applicationContext?.packageName)
        i.putExtra(AudioEffect.EXTRA_AUDIO_SESSION, sessionId)
        applicationContext?.sendBroadcast(i)
    }

    private fun removeAudioSessionId(sessionId: Int) {
        val i = Intent(AudioEffect.ACTION_CLOSE_AUDIO_EFFECT_CONTROL_SESSION)
        i.putExtra(AudioEffect.EXTRA_PACKAGE_NAME, applicationContext?.packageName)
        i.putExtra(AudioEffect.EXTRA_AUDIO_SESSION, sessionId)
        applicationContext?.sendBroadcast(i)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = null
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        this.activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {

    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {

    }

    override fun onDetachedFromActivity() {

    }
}
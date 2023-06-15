package com.suamusica.equalizer

import EqualizerHelpers
import android.content.Context
import android.content.Intent
import android.media.audiofx.AudioEffect
import android.os.Build
import android.text.TextUtils
import java.io.BufferedReader
import java.io.IOException
import java.io.InputStreamReader
import java.lang.reflect.Method


class AudioEffectUtil(private val context: Context) {
    /// TODO: is here
    fun deviceHasEqualizer(sessionId: Int): Boolean {
        val intent = Intent(AudioEffect.ACTION_DISPLAY_AUDIO_EFFECT_CONTROL_PANEL)
        intent.putExtra(AudioEffect.EXTRA_PACKAGE_NAME, context.packageName)
        intent.putExtra(AudioEffect.EXTRA_AUDIO_SESSION, sessionId)
        /// for xiaomi devices
        intent.putExtra("android.media.extra.CONTENT_TYPE", 0)
        intent.putExtra("android.media.extra.AUDIO_SESSION", sessionId)
        intent.putExtra(AudioEffect.EXTRA_CONTENT_TYPE, 0)
//        intent.putExtra(AudioEffect.EFFECT_TYPE_EQUALIZER, sessionId)
        intent.putExtra(AudioEffect.EXTRA_AUDIO_SESSION, sessionId)
//        EFFECT_TYPE_EQUALIZER
        println("XIAOMI INTENT: $intent")
        println("XIAOMI isMiUi: ${isMiUi()}")
        println("XIAOMI Build.MANUFACTURER: ${Build.MANUFACTURER}")
        println("XIAOMI Build.MODEL: ${Build.MODEL}")
        println("XIAOMI Build.VERSION_CODES: ${Build.VERSION_CODES.M}")
//        println("XIAOMI isXiaomiWithVersionGreaterThan11: ${isXiaomiWithVersionGreaterThan11(context)}")
        println("XIAOMI readMIVersion: ${readMIVersion()}")
        println("XIAOMI isMiuiVersionNameEqualsOrGreatherThan11: ${isMiuiVersionNameEqualsOrGreatherThan11()}")
//        println("XIAOMI hasMiuiEqualizer: ${hasMiuiEqualizer(context)}")
        return EqualizerHelpers().isMiuiVersionEqualsOrGreatherThan11() || context.packageManager?.let { intent.resolveActivity(it) != null }
                ?: false
        return context.packageManager?.let { intent.resolveActivity(it) != null }
                ?: false
    }

    fun setAudioSessionId(sessionId: Int) {
        val i = Intent(AudioEffect.ACTION_OPEN_AUDIO_EFFECT_CONTROL_SESSION)
        i.putExtra(AudioEffect.EXTRA_PACKAGE_NAME, context.packageName)
        i.putExtra(AudioEffect.EXTRA_AUDIO_SESSION, sessionId)
        context.sendBroadcast(i)
    }

    fun removeAudioSessionId(sessionId: Int) {
        val i = Intent(AudioEffect.ACTION_CLOSE_AUDIO_EFFECT_CONTROL_SESSION)
        i.putExtra(AudioEffect.EXTRA_PACKAGE_NAME, context.packageName)
        i.putExtra(AudioEffect.EXTRA_AUDIO_SESSION, sessionId)
        context.sendBroadcast(i)
    }

    private fun isMiUi(): Boolean {
        return !TextUtils.isEmpty(getSystemProperty("ro.miui.ui.version.name"))
    }

    private fun getSystemProperty(propName: String): String? {
        val line: String
        var input: BufferedReader? = null
        try {
            val p = Runtime.getRuntime().exec("getprop $propName")
            input = BufferedReader(InputStreamReader(p.inputStream), 1024)
            line = input.readLine()
            input.close()
        } catch (ex: IOException) {
            return null
        } finally {
            if (input != null) {
                try {
                    input.close()
                } catch (e: IOException) {
                    e.printStackTrace()
                }
            }
        }
        return line
    }

    private fun readMIVersion() {
        try {
            val propertyClass =
                Class.forName("android.os.SystemProperties")
            val method: Method = propertyClass.getMethod("get", String::class.java)
            val miuiVersion = method.invoke(propertyClass, "ro.miui.ui.version.name") as String
            println("xiaomi Version Name: $miuiVersion")
            val versionCode = method.invoke(propertyClass, "ro.miui.ui.version.code") as String
            println("xiaomi Version Code: $versionCode")
            val versionName = method.invoke(propertyClass, "ro.miui.ui.version.name") as String
            val versionNameWithoutV = versionName.substring(1)
            println("xiaomi Version Name: $versionName")
            println("xiaomi Version Name without V: $versionNameWithoutV")
        } catch (e: ClassNotFoundException) {
            e.printStackTrace()
        } catch (e: NoSuchMethodException) {
            e.printStackTrace()
        } catch (e: IllegalAccessException) {
            e.printStackTrace()
        }
    }

    private fun isMiuiVersionNameEqualsOrGreatherThan11(): Boolean {
        try {
            val propertyClass =
                Class.forName("android.os.SystemProperties")
            val method: Method = propertyClass.getMethod("get", String::class.java)
            val versionName = method.invoke(propertyClass, "ro.miui.ui.version.name") as String
            if (versionName.isEmpty()) return false
            if (!versionName.startsWith("V")) {
                return versionName.toInt() >= 11
            }
            return versionName.substring(1).toInt() >= 11
        } catch (e: ClassNotFoundException) {
            e.printStackTrace()
        } catch (e: NoSuchMethodException) {
            e.printStackTrace()
        } catch (e: IllegalAccessException) {
            e.printStackTrace()
        }
        return false
    }

//    private fun isXiaomiWithVersionGreaterThan11(context: Context): Boolean {
//
//        // Get the Build.VERSION.RELEASE property.
//        val miuiVersion = getSystemProperty("ro.miui.ui.version.name")
//
//        // Check if the device is running MIUI.
//        val isMiUi = miuiVersion != null && miuiVersion.startsWith("MIUI")
//
//        // Check if the device has a version greater than 11.
//        val isVersionGreaterThan11 = miuiVersion != null
//
//        return isMiUi && isVersionGreaterThan11
//    }
//
//    @RequiresApi(Build.VERSION_CODES.JELLY_BEAN_MR2)
//    fun hasMiuiEqualizer(context: Context): Boolean {
//
//        // Get the AudioManager instance.
//        val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as android.media.AudioManager
//
//        val isMiUi = isMiUi()
//
//        // Check if the device is running MIUI.
//        if (!isMiUi) {
//            return false
//        }
//
//// Check if the device has a version greater than 11.
//        val isVersionGreaterThan11 = isXiaomiWithVersionGreaterThan11(context)
//
//        // Check if the device has the equalizer feature.
//        val hasEqualizerFeature = audioManager.isWiredHeadsetOn
//
//        return isMiUi && isVersionGreaterThan11 && hasEqualizerFeature
//
//    }


//    fun deviceHasEqualizer(sessionId: Int): Boolean {
//        val packageManager = context.packageManager
//
//        // Check if the device has the equalizer feature.
//        val hasEqualizerFeature = packageManager.hasSystemFeature("android.hardware.audio.effect.equalizer")
//
//        // Check if there is an equalizer app installed.
//        val equalizerApps = packageManager.queryIntentActivities(
//            Intent(AudioEffect.ACTION_DISPLAY_AUDIO_EFFECT_CONTROL_PANEL), 0
//        )
//
//        return hasEqualizerFeature || equalizerApps.isNotEmpty()
//    }
}


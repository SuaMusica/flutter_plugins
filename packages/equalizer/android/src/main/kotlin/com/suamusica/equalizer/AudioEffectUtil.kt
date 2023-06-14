package com.suamusica.equalizer

import android.content.Context
import android.content.Intent
import android.media.audiofx.AudioEffect

class AudioEffectUtil(private val context: Context) {
    /// TODO: is here
    fun deviceHasEqualizer(sessionId: Int): Boolean {
        val intent = Intent(AudioEffect.ACTION_DISPLAY_AUDIO_EFFECT_CONTROL_PANEL)
        intent.putExtra(AudioEffect.EXTRA_PACKAGE_NAME, context.packageName)
        intent.putExtra(AudioEffect.EXTRA_AUDIO_SESSION, sessionId)
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
}
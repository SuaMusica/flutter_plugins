package com.suamusica.smads.helpers

import android.app.KeyguardManager
import android.content.Context

object ScreenHelper {
    fun isLocked(context: Context): Boolean {
        val keyguardManager: KeyguardManager = context.getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
        return keyguardManager.isKeyguardLocked
    }
}
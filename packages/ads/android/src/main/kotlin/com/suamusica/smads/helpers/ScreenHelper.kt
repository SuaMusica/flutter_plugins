package com.suamusica.smads.helpers

import android.app.ActivityManager
import android.app.KeyguardManager
import android.content.Context

object ScreenHelper {
    fun isLocked(context: Context): Boolean {
        val keyguardManager: KeyguardManager = context.getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
        return keyguardManager.isKeyguardLocked
    }

    fun isVisible(context: Context): Boolean {
        val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        activityManager.runningAppProcesses?.forEach {
            if (it.processName == context.packageName) {
                return when(it.importance) {
                    ActivityManager.RunningAppProcessInfo.IMPORTANCE_VISIBLE,
                    ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND -> true
                    else -> false
                }
            }
        }
        return false
    }
}
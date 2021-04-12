package com.suamusica.equalizer

import android.content.Context
import android.os.VibrationEffect
import android.os.Vibrator

class VibratorHelper(private val context: Context) {

    private val vibrator = context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator

    fun vibrate(milliseconds: Long, amplitude: Int) {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            vibrator.vibrate(VibrationEffect.createOneShot(milliseconds, amplitude))
        }
    }
}
package com.suamusica.smads.helpers

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.Toast
import com.suamusica.smads.BuildConfig
import timber.log.Timber

object Navigator {

    private const val PREMIUM_DEEP_LINK = "suamusica://premium"
    private const val PREMIUM_ACTIVITY_NOT_FOUND_MESSAGE = "Activity Premium não encontrada."

    fun redirectToPremiumActivity(context: Context, onSuccess: () -> Unit) {
        try {
            context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(PREMIUM_DEEP_LINK)))
            onSuccess()
        } catch (t: ActivityNotFoundException) {
            Timber.e(t)
            if (BuildConfig.DEBUG) {
                Toast.makeText(context, PREMIUM_ACTIVITY_NOT_FOUND_MESSAGE, Toast.LENGTH_SHORT).show()
            }
        }
    }
}
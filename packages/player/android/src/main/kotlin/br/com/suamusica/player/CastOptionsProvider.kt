package br.com.suamusica.player

import android.content.Context
import android.util.Log

import com.google.android.gms.cast.framework.CastOptions
import com.google.android.gms.cast.framework.OptionsProvider
import com.google.android.gms.cast.framework.SessionProvider
import com.google.android.gms.cast.framework.media.CastMediaOptions
import com.google.android.gms.cast.framework.media.MediaIntentReceiver
import com.google.android.gms.cast.framework.media.NotificationOptions

class CastOptionsProvider : OptionsProvider {
    override fun getCastOptions(context: Context): CastOptions {
        Log.d("Player","#NATIVE LOGS ==> CAST getCastOptions ")

        val buttonActions = listOf(
            MediaIntentReceiver.ACTION_SKIP_NEXT,
            MediaIntentReceiver.ACTION_TOGGLE_PLAYBACK,
            MediaIntentReceiver.ACTION_SKIP_PREV,
            MediaIntentReceiver.ACTION_STOP_CASTING
        )

        val compatButtonAction = intArrayOf(1, 3)
        val notificationOptions =
            NotificationOptions.Builder()
                .setActions(buttonActions, compatButtonAction)
                .setSkipStepMs(30000)
                .build()
        val mediaOptions = CastMediaOptions.Builder()
            .setNotificationOptions(notificationOptions)
            .setMediaSessionEnabled(false)
            .setNotificationOptions(null)
            .build()
        return CastOptions.Builder()
            .setReceiverApplicationId("A715FF7E")
            .setCastMediaOptions(mediaOptions)
            .build()
    }

    override fun getAdditionalSessionProviders(context: Context): List<SessionProvider>? {
        Log.d("Player","#NATIVE LOGS ==> CAST getCastOptions")
        return null
    }
}
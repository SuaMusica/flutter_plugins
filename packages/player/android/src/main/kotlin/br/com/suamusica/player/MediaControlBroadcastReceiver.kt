package br.com.suamusica.player

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.media3.common.util.UnstableApi

class MediaControlBroadcastReceiver : BroadcastReceiver() {
    @UnstableApi
    override fun onReceive(context: Context?, intent: Intent?) {
         MediaButtonEventHandler(null).onMediaButtonEventHandler(intent)
    }
}
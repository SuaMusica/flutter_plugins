package br.com.suamusica.player

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class MediaControlBroadcastReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        MediaButtonEventHandler().onMediaButtonEventHandler(intent)
    }
}
package br.com.suamusica.player

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import android.view.KeyEvent

class MediaControlBroadcastReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent == null || Intent.ACTION_MEDIA_BUTTON != intent.action
                || !intent.hasExtra(Intent.EXTRA_KEY_EVENT)) {
            return
        }
        val ke = intent.getParcelableExtra<KeyEvent>(Intent.EXTRA_KEY_EVENT)
        Log.i("Player", "Key: $ke")
        when (ke!!.keyCode) {
            KeyEvent.KEYCODE_MEDIA_PLAY -> {
                Plugin.play()
            }
            KeyEvent.KEYCODE_MEDIA_PAUSE -> {
                Plugin.pause()
            }
            KeyEvent.KEYCODE_MEDIA_NEXT -> {
                Log.i("Player", "Player: Key Code : Next")
                Plugin.next()
            }
            KeyEvent.KEYCODE_MEDIA_PREVIOUS -> {
                Log.i("Player", "Player: Key Code : Previous")
                Plugin.previous()
            }
            KeyEvent.KEYCODE_MEDIA_STOP -> {
                Plugin.stop()
            }
        }


    }
}
package br.com.suamusica.player

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import android.view.KeyEvent

class MusicService : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent == null || Intent.ACTION_MEDIA_BUTTON != intent.action
                || !intent.hasExtra(Intent.EXTRA_KEY_EVENT)) {
            return
        }
        val ke = intent.getParcelableExtra<KeyEvent>(Intent.EXTRA_KEY_EVENT)
        Log.i("Player", "Key: $ke")

        when (ke.keyCode) {
            KeyEvent.KEYCODE_MEDIA_PLAY -> {
                Plugin.currentPlayer()?.play()
            }
            KeyEvent.KEYCODE_MEDIA_PAUSE -> {
                Plugin.currentPlayer()?.pause()
            }
            KeyEvent.KEYCODE_MEDIA_NEXT -> {
                Plugin.next()
            }
            KeyEvent.KEYCODE_MEDIA_PREVIOUS -> {
                Plugin.previous()
            }
            KeyEvent.KEYCODE_MEDIA_STOP -> {
                Plugin.currentPlayer()?.stop()
            }
        }


    }
}
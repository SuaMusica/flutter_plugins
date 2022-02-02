package br.com.suamusica.player

import android.content.Intent
import android.util.Log
import android.view.KeyEvent
import com.google.android.exoplayer2.Player
import com.google.android.exoplayer2.ext.mediasession.MediaSessionConnector

class MediaButtonEventHandler : MediaSessionConnector.MediaButtonEventHandler {

    override fun onMediaButtonEvent(player: Player, intent: Intent): Boolean {
        onMediaButtonEventHandler(intent)
        return true
    }

    fun onMediaButtonEventHandler(intent: Intent?) {

        if (intent == null) {
            return
        }

        if (Intent.ACTION_MEDIA_BUTTON == intent.action) {
            mediaButtonHandler(intent)
        } else if (intent.hasExtra(FAVORITE)) {
            PlayerSingleton.favorite(intent.getBooleanExtra(FAVORITE, false))
        }

    }

    private fun mediaButtonHandler(intent: Intent) {
        val ke = intent.getParcelableExtra<KeyEvent>(Intent.EXTRA_KEY_EVENT)
        Log.d("Player", "Key: $ke")

        if (ke!!.action == KeyEvent.ACTION_UP) {
            return
        }

        when (ke.keyCode) {
            KeyEvent.KEYCODE_MEDIA_PLAY -> {
                PlayerSingleton.play()
            }
            KeyEvent.KEYCODE_MEDIA_PAUSE -> {
                PlayerSingleton.pause()
            }
            KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE -> {
                Log.d("Player", "Player: Key Code : PlayPause")
                PlayerSingleton.togglePlayPause()
            }
            KeyEvent.KEYCODE_MEDIA_NEXT -> {
                Log.d("Player", "Player: Key Code : Next")
                PlayerSingleton.next()
            }
            KeyEvent.KEYCODE_MEDIA_PREVIOUS -> {
                Log.d("Player", "Player: Key Code : Previous")
                PlayerSingleton.previous()
            }
            KeyEvent.KEYCODE_MEDIA_STOP -> {
                PlayerSingleton.stop()
            }
        }
    }
}
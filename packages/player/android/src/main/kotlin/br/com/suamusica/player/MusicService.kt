package br.com.suamusica.player

import android.app.IntentService
import android.content.Intent
import android.util.Log

class MusicService : IntentService("MusicService") {
    override fun onHandleIntent(intent: Intent?) {
        Log.i("Player", "We got something \$intent")
    }
}
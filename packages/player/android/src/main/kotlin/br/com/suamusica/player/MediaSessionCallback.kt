package br.com.suamusica.player

import android.content.Intent
import android.support.v4.media.session.MediaSessionCompat
import android.support.v4.media.session.MediaSessionCompat.Callback
import android.util.Log

class MediaSessionCallback(): Callback() {
    override fun onMediaButtonEvent(mediaButtonEvent: Intent?): Boolean {
        Log.i("Player", "onMediaButtonEvent(): $mediaButtonEvent")
        return super.onMediaButtonEvent(mediaButtonEvent)
    }

    override fun onSkipToPrevious() {
        Log.i("Player", "onSkipToPrevious()")
        super.onSkipToPrevious()
    }

    override fun onPlay() {
        Log.i("Player", "onPlay()")
        super.onPlay()
    }

    override fun onStop() {
        Log.i("Player", "onStop()")
        super.onStop()
    }

    override fun onSkipToNext() {
        Log.i("Player", "onSkipToNext()")
        super.onSkipToNext()
    }

    override fun onPause() {
        Log.i("Player", "onPause()")
        super.onPause()
    }

}
package br.com.suamusica.player

import android.content.Context
import android.util.Log
import com.google.android.exoplayer2.C
import com.google.android.exoplayer2.ExoPlaybackException
import com.google.android.exoplayer2.ExoPlayer
import com.google.android.exoplayer2.ExoPlayerFactory
import com.google.android.exoplayer2.audio.AudioAttributes
import java.util.concurrent.TimeUnit

class WrappedExoPlayer(val playerId: String, override val context: Context): Player {
    override var volume = 1.0
    override val duration = 0
    override val currentPosition = 0
    override var releaseMode = ReleaseMode.RELEASE
    override var stayAwake: Boolean = false

    private var isToShowNotification = true

    override fun seek(position: Int) {
    }

    override fun play() {
    }

    override fun pause() {
    }

    override fun stop() {
    }

    override fun release() {
    }

    override fun setUrl(url: String, local: Boolean) {
    }
}

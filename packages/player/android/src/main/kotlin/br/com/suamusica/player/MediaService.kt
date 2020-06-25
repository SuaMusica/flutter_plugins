package br.com.suamusica.player

import android.app.Service
import android.content.Intent
import android.os.Handler
import android.os.IBinder
import android.os.Messenger
import smplayer.IMediaService.Stub

class MediaService : Service() {
    var player: Player? = null

    enum class MessageType {
        STATE_CHANGE,
        POSITION_CHANGE
    }

    private val binder = object : Stub() {
        override fun getDuration() = player?.duration ?: 0L
        override fun getCurrentPosition() = player?.currentPosition ?: 0L

        override fun removeNotification() {
            player?.removeNotification()
        }

        override fun prepare(cookie: String, name: String, author: String, url: String, coverUrl: String) {
            player?.prepare(cookie, Media(name, author, url, coverUrl))
        }

        override fun play() {
            player?.play()
        }

        override fun pause() {
            player?.pause()
        }

        override fun stop() {
            player?.stop()
        }

        override fun seek(position: Long) {
            player?.seek(position)
        }

        override fun next() {
            player?.next()
        }

        override fun previous() {
            player?.previous()
        }


        override fun getReleaseMode() = player?.releaseMode!!.ordinal
        override fun setReleaseMode(releaseMode: Int) {
            player?.releaseMode = ReleaseMode.fromInt(releaseMode)
        }

        override fun sendNotification() {
            player?.sendNotification()
        }

        override fun release() {
            player?.release()
        }
    }

    override fun onCreate() {
        super.onCreate()
        val messenger = Messenger(binder)
        player = WrappedExoPlayer(this, messenger, Handler())
    }

    override fun onBind(intent: Intent): IBinder {
        return binder
    }
}
package br.com.suamusica.player

import android.net.Uri
import android.os.Bundle
import android.os.ResultReceiver
import android.support.v4.media.session.MediaControllerCompat
import android.support.v4.media.session.MediaSessionCompat
import android.util.Log
import com.google.android.exoplayer2.ControlDispatcher
import com.google.android.exoplayer2.Player
import com.google.android.exoplayer2.ext.mediasession.MediaSessionConnector

class MusicPlayerPlaybackPreparer(val player: br.com.suamusica.player.Player,
                                  val exoPlayer: Player,
                                  val mediaController: MediaControllerCompat,
                                  val mediaSession: MediaSessionCompat) : MediaSessionConnector.PlaybackPreparer {
    val TAG = "Player"

    override fun onPrepareFromMediaId(mediaId: String, playWhenReady: Boolean, extras: Bundle) {
        Log.i(TAG, "MusicPlayerPlaybackPreparer.onPrepareFromMediaId : START")

        Log.i(TAG, "MusicPlayerPlaybackPreparer.onPrepareFromMediaId : END")
    }

    override fun onPrepareFromSearch(query: String, playWhenReady: Boolean, extras: Bundle) {
        Log.i(TAG, "MusicPlayerPlaybackPreparer.onPrepareFromSearch : START")

        Log.i(TAG, "MusicPlayerPlaybackPreparer.onPrepareFromSearch : END")
    }

    override fun onPrepareFromUri(uri: Uri, playWhenReady: Boolean, extras: Bundle) {
        Log.i(TAG, "MusicPlayerPlaybackPreparer.onPrepareFromUri : START")

        Log.i(TAG, "MusicPlayerPlaybackPreparer.onPrepareFromUri : END")
    }

    override fun onCommand(player: Player,
                           controlDispatcher: ControlDispatcher,
                           command: String, extras: Bundle?, cb: ResultReceiver?): Boolean {
        try {
            Log.i(TAG, "MusicPlayerPlaybackPreparer.onPrepareFromUri : START")

            return when (command) {
                "prepare" -> {
                    return extras?.let {
                        val cookie = it.getString("cookie")
                        val name = it.getString("name")
                        val author = it.getString("author")
                        val url = it.getString("url")
                        val coverUrl = it.getString("coverUrl")
                        this.player.prepare(cookie, Media(name, author, url, coverUrl))
                        return@let true
                    } ?: false
                }

                "play" -> {
                    this.player.play()
                    true
                }
                else -> false
            }
        } finally {
            Log.i(TAG, "MusicPlayerPlaybackPreparer.onPrepareFromUri : END")
        }
    }

    override fun getSupportedPrepareActions(): Long {
        return 0L
    }

    override fun onPrepare(playWhenReady: Boolean) {

    }
}
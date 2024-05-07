package br.com.suamusica.player

import android.net.Uri
import android.os.Bundle
import android.os.ResultReceiver
import android.util.Log
import com.google.android.exoplayer2.Player
import com.google.android.exoplayer2.ext.mediasession.MediaSessionConnector

class MusicPlayerPlaybackPreparer(
    private val mediaService: MediaService,
                                  ) : MediaSessionConnector.PlaybackPreparer {
    val TAG = "Player"

    override fun onPrepareFromMediaId(mediaId: String, playWhenReady: Boolean, extras: Bundle?) {
        Log.i(TAG, "MusicPlayerPlaybackPreparer.onPrepareFromMediaId : START")

        Log.i(TAG, "MusicPlayerPlaybackPreparer.onPrepareFromMediaId : END")
    }

    override fun onPrepareFromSearch(query: String, playWhenReady: Boolean, extras: Bundle?) {
        Log.i(TAG, "MusicPlayerPlaybackPreparer.onPrepareFromSearch : START")

        Log.i(TAG, "MusicPlayerPlaybackPreparer.onPrepareFromSearch : END")
    }

    override fun onPrepareFromUri(uri: Uri, playWhenReady: Boolean, extras: Bundle?) {
        Log.i(TAG, "MusicPlayerPlaybackPreparer.onPrepareFromUri : START")

        Log.i(TAG, "MusicPlayerPlaybackPreparer.onPrepareFromUri : END")
    }

    override fun onCommand(player: Player,
                           command: String, extras: Bundle?, cb: ResultReceiver?): Boolean {
        try {
            Log.i(TAG, "MusicPlayerPlaybackPreparer.onCommand : START")

            return when (command) {
                "prepare" -> {
                    return extras?.let {
                        val cookie = it.getString("cookie")!!
                        val name = it.getString("name")!!
                        val author = it.getString("author")!!
                        val url = it.getString("url")!!
                        val coverUrl = it.getString("coverUrl")!!
                        val bigCoverUrl = it.getString("bigCoverUrl")

                        var isFavorite:Boolean? = null;
                        if(it.containsKey(PlayerPlugin.IS_FAVORITE_ARGUMENT)){
                            isFavorite = it.getBoolean(PlayerPlugin.IS_FAVORITE_ARGUMENT)
                        }
                        mediaService.prepare(cookie, Media(name, author, url, coverUrl, bigCoverUrl,isFavorite))
                        return@let true
                    } ?: false
                }
                "play" -> {
                    mediaService.play()
                    true
                }
                "pause" -> {
                    mediaService.pause()
                    true
                }
                "stop" -> {
                    mediaService.stop()
                    true
                }
                "togglePlayPause" -> {
                    mediaService.togglePlayPause()
                    true
                }
                "release" -> {
                    mediaService.release()
                    true
                }
                "seek" -> {
                    return extras?.let {
                        val position = it.getLong("position")
                        val playWhenReady = it.getBoolean("playWhenReady")
                        mediaService.seek(position, playWhenReady)
                        return@let true
                    } ?: false
                }
                "remove_notification" -> {
                    mediaService.removeNotification()
                    return true
                }
                "send_notification" -> {
                    return extras?.let {
                        val name = it.getString("name")!!
                        val author = it.getString("author")!!
                        val url = it.getString("url")!!
                        val coverUrl = it.getString("coverUrl")!!
                        val bigCoverUrl = it.getString("bigCoverUrl")
                        var isPlaying:Boolean? = null;
                        var isFavorite:Boolean? = null;
                        if(it.containsKey(PlayerPlugin.IS_PLAYING_ARGUMENT)){
                            isPlaying = it.getBoolean(PlayerPlugin.IS_PLAYING_ARGUMENT)
                        }
                        if(it.containsKey(PlayerPlugin.IS_FAVORITE_ARGUMENT)){
                            isFavorite = it.getBoolean(PlayerPlugin.IS_FAVORITE_ARGUMENT)
                        }
                        mediaService.sendNotification(Media(name, author, url, coverUrl, bigCoverUrl, isFavorite),isPlaying)
                        return true
                    } ?: false
                }
                "ads_playing" -> {
                    mediaService.adsPlaying()
                    return true
                }
                FAVORITE -> {
                    return extras?.let {
                        if(it.containsKey(PlayerPlugin.IS_FAVORITE_ARGUMENT)){
                            mediaService.setFavorite(it.getBoolean(PlayerPlugin.IS_FAVORITE_ARGUMENT))
                        }
                        return@let true
                    } ?: false
                }
                else -> false
            }
        } finally {
            Log.i(TAG, "MusicPlayerPlaybackPreparer.onCommand : END")
        }
    }

    override fun getSupportedPrepareActions(): Long {
        return 0L
    }

    override fun onPrepare(playWhenReady: Boolean) {

    }
}
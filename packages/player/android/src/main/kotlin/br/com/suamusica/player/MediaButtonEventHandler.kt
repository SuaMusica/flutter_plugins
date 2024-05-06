package br.com.suamusica.player

import android.content.Intent
import android.os.Bundle
import android.util.Log
import android.view.KeyEvent
import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import androidx.media3.common.util.UnstableApi
import androidx.media3.session.MediaSession
import androidx.media3.session.SessionCommand
import androidx.media3.session.SessionResult
import com.google.common.util.concurrent.Futures
import com.google.common.util.concurrent.ListenableFuture

@UnstableApi
class MediaButtonEventHandler(
    private val mediaService: MediaService,
) : MediaSession.Callback {
    override fun onConnect(
        session: MediaSession,
        controller: MediaSession.ControllerInfo
    ): MediaSession.ConnectionResult {
        Log.d("Player", "onConnect")
        val sessionCommands = MediaSession.ConnectionResult.DEFAULT_SESSION_COMMANDS.buildUpon()
//            .add(SessionCommand("Favoritar", Bundle.EMPTY))
            .add(SessionCommand("prepare", session.token.extras))
            .build()
        return MediaSession.ConnectionResult.AcceptedResultBuilder(session)
            .setAvailableSessionCommands(sessionCommands)
            .build()
    }

    override fun onAddMediaItems(
        mediaSession: MediaSession,
        controller: MediaSession.ControllerInfo,
        mediaItems: MutableList<MediaItem>
    ): ListenableFuture<MutableList<MediaItem>> {
        Log.d("Player", "onAddMediaItems")
        return super.onAddMediaItems(mediaSession, controller, mediaItems)
    }
//    override fun onMediaButtonEvent(player: Player, intent: Intent): Boolean {
//        onMediaButtonEventHandler(intent)
//        return true
//    }

    //    fun onMediaButtonEventHandler(intent: Intent?) {
//
//        if (intent == null) {
//            return
//        }
//
//        if (Intent.ACTION_MEDIA_BUTTON == intent.action) {
//            mediaButtonHandler(intent)
//        } else if (intent.hasExtra(FAVORITE)) {
//            PlayerSingleton.favorite(intent.getBooleanExtra(FAVORITE, false))
//        }
//
//    }
    override fun onCustomCommand(
        session: MediaSession,
        controller: MediaSession.ControllerInfo,
        customCommand: SessionCommand,
        args: Bundle
    ): ListenableFuture<SessionResult> {
        if (customCommand.customAction == "Favoritar") {
            // Do custom logic here
//        saveToFavorites(session.player.currentMediaItem)
            PlayerSingleton.favorite(
                session.player.currentMediaItem?.mediaMetadata?.extras?.getBoolean(
                    FAVORITE,
                    false
                ) ?: false
            )

            return Futures.immediateFuture(
                SessionResult(SessionResult.RESULT_SUCCESS)
            )
        }
        if (customCommand.customAction == "prepare") {
            Log.d("Player", "prepare2")

            args.let {
                val cookie = it.getString("cookie")!!
                val name = it.getString("name")!!
                val author = it.getString("author")!!
                val url = it.getString("url")!!
                val coverUrl = it.getString("coverUrl")!!
                var isFavorite: Boolean? = null;
                if (it.containsKey(PlayerPlugin.IS_FAVORITE_ARGUMENT)) {
                    isFavorite = it.getBoolean(PlayerPlugin.IS_FAVORITE_ARGUMENT)
                }
                mediaService.prepare(cookie, Media(name, author, url, coverUrl, isFavorite))
            }
        }
        return Futures.immediateFuture(
            SessionResult(SessionResult.RESULT_SUCCESS)
        )
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
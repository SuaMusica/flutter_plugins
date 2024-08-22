package br.com.suamusica.player

import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.view.KeyEvent
import androidx.media3.common.Player.COMMAND_SEEK_TO_NEXT
import androidx.media3.common.Player.COMMAND_SEEK_TO_NEXT_MEDIA_ITEM
import androidx.media3.common.Player.COMMAND_SEEK_TO_PREVIOUS
import androidx.media3.common.Player.COMMAND_SEEK_TO_PREVIOUS_MEDIA_ITEM
import androidx.media3.common.util.UnstableApi
import androidx.media3.session.CommandButton
import androidx.media3.session.MediaLibraryService
import androidx.media3.session.MediaSession
import androidx.media3.session.R.drawable
import androidx.media3.session.SessionCommand
import androidx.media3.session.SessionResult
import com.google.common.collect.ImmutableList
import com.google.common.util.concurrent.Futures
import com.google.common.util.concurrent.ListenableFuture

@UnstableApi
class MediaButtonEventHandler(
    private val mediaService: MediaService?,
) : MediaLibraryService.MediaLibrarySession.Callback {
    private val BROWSABLE_ROOT = "/"
    private val EMPTY_ROOT = "@empty@"
    override fun onConnect(
        session: MediaSession,
        controller: MediaSession.ControllerInfo
    ): MediaSession.ConnectionResult {
        Log.d("Player", "onConnect")
        val sessionCommands =
            MediaSession.ConnectionResult.DEFAULT_SESSION_COMMANDS.buildUpon()
                .add(SessionCommand("next", Bundle.EMPTY))
                .add(SessionCommand("seek", session.token.extras))
                .add(SessionCommand("previous", Bundle.EMPTY))
                .add(SessionCommand("pause", Bundle.EMPTY))
                .add(SessionCommand("favoritar", Bundle.EMPTY))
                .add(SessionCommand("desfavoritar", Bundle.EMPTY))
                .add(SessionCommand("prepare", session.token.extras))
                .add(SessionCommand("play", Bundle.EMPTY))
                .add(SessionCommand("remove_notification", Bundle.EMPTY))
                .add(SessionCommand("send_notification", session.token.extras))
                .add(SessionCommand("ads_playing", Bundle.EMPTY))
                .add(SessionCommand("onTogglePlayPause", Bundle.EMPTY))
                .build()

        val playerCommands =
            MediaSession.ConnectionResult.DEFAULT_PLAYER_COMMANDS.buildUpon()
                .remove(COMMAND_SEEK_TO_PREVIOUS)
                .remove(COMMAND_SEEK_TO_PREVIOUS_MEDIA_ITEM)
                .remove(COMMAND_SEEK_TO_NEXT)
                .remove(COMMAND_SEEK_TO_NEXT_MEDIA_ITEM)
                .build()

        return MediaSession.ConnectionResult.AcceptedResultBuilder(session)
            .setAvailableSessionCommands(sessionCommands)
            .setAvailablePlayerCommands(playerCommands)
            .build()
    }

    override fun onPostConnect(session: MediaSession, controller: MediaSession.ControllerInfo) {
        super.onPostConnect(session, controller)
        Log.d("Player", "onPostConnect")
    }

    override fun onCustomCommand(
        session: MediaSession,
        controller: MediaSession.ControllerInfo,
        customCommand: SessionCommand,
        args: Bundle
    ): ListenableFuture<SessionResult> {
        Log.d("Player", "TESTE1 CUSTOM_COMMAND: ${customCommand.customAction} | $args")
        if (customCommand.customAction == "favoritar" || customCommand.customAction == "desfavoritar") {
            val isFavorite = customCommand.customAction == "favoritar"
            buildIcons(isFavorite)
            PlayerSingleton.favorite(isFavorite)
        }

        if (customCommand.customAction == "seek") {
            mediaService?.seek(args.getLong("position"), args.getBoolean("playWhenReady"))
        }

        if (customCommand.customAction == "onTogglePlayPause") {
            mediaService?.togglePlayPause()
        }

        if (customCommand.customAction == "send_notification") {
            args.let {
                val isFavorite = it.getBoolean(PlayerPlugin.IS_FAVORITE_ARGUMENT)
                buildIcons(isFavorite)

            }
        }
        if (customCommand.customAction == "play") {
            mediaService?.play()
        }
        if (customCommand.customAction == "previous") {
            PlayerSingleton.previous()
        }
        if (customCommand.customAction == "next") {
            PlayerSingleton.next()
        }
        if (customCommand.customAction == "pause") {
            mediaService?.pause()
        }
        if (customCommand.customAction == "remove_notification" || customCommand.customAction == "ads_playing" ) {
            mediaService?.removeNotification();
        }

        if (customCommand.customAction == "prepare") {
            args.let {
                val cookie = it.getString("cookie")!!
                val name = it.getString("name")!!
                val author = it.getString("author")!!
                val url = it.getString("url")!!
                val coverUrl = it.getString("coverUrl")!!
                val bigCoverUrl = it.getString("bigCoverUrl")!!
                var isFavorite: Boolean? = null;
                if (it.containsKey(PlayerPlugin.IS_FAVORITE_ARGUMENT)) {
                    isFavorite = it.getBoolean(PlayerPlugin.IS_FAVORITE_ARGUMENT)
                }
                mediaService?.prepare(
                    cookie,
                    Media(name, author, url, coverUrl, bigCoverUrl, isFavorite)
                )
                buildIcons(isFavorite ?: false)
            }
        }
        return Futures.immediateFuture(
            SessionResult(SessionResult.RESULT_SUCCESS)
        )
    }

    private fun buildIcons(isFavorite: Boolean): Unit? {
        val list = ImmutableList.of(
            CommandButton.Builder()
                .setDisplayName("Save to favorites")
                .setIconResId(if (isFavorite) drawable.media3_icon_heart_filled else drawable.media3_icon_heart_unfilled)
                .setSessionCommand(
                    SessionCommand(
                        if (isFavorite) "desfavoritar" else "favoritar",
                        Bundle()
                    )
                )
                .setEnabled(true)
                .build(),
            CommandButton.Builder()
                .setDisplayName("next")
                .setIconResId(drawable.media3_icon_next)
                .setSessionCommand(SessionCommand("next", Bundle.EMPTY))
                .setEnabled(true)
                .build(),
        )
        return mediaService?.mediaSession?.setCustomLayout(
            if(Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                list.plus(
                    CommandButton.Builder()
                        .setDisplayName("previous")
                        .setIconResId(drawable.media3_icon_previous)
                        .setSessionCommand(SessionCommand("previous", Bundle.EMPTY))
                        .build()
                )
            } else{
                list
            }
        )
    }


    @UnstableApi
    override fun onMediaButtonEvent(
        session: MediaSession,
        controllerInfo: MediaSession.ControllerInfo,
        intent: Intent
    ): Boolean {
        onMediaButtonEventHandler(intent)
        return true
    }

    @UnstableApi
    fun onMediaButtonEventHandler(intent: Intent?) {

        if (intent == null) {
            return
        }

        if (Intent.ACTION_MEDIA_BUTTON == intent.action) {
            @Suppress("DEPRECATION") val ke =
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    intent.getParcelableExtra(Intent.EXTRA_KEY_EVENT, KeyEvent::class.java)
                } else {
                    intent.getParcelableExtra(Intent.EXTRA_KEY_EVENT)
                }
            if (ke == null) {
                return
            }

            if (ke.action == KeyEvent.ACTION_UP) {
                return
            }

            Log.d("Player", "Key: $ke")

            when (ke.keyCode) {
                KeyEvent.KEYCODE_MEDIA_PLAY -> {
                    PlayerSingleton.play()
                }

                KeyEvent.KEYCODE_MEDIA_PAUSE -> {
                    PlayerSingleton.pause()
                }

                KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE -> {
                    Log.d("Player", "Player: Key Code : PlayPause")
                    mediaService?.togglePlayPause()
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
        } else if (intent.hasExtra(PlayerPlugin.FAVORITE)) {
            PlayerSingleton.favorite(intent.getBooleanExtra(PlayerPlugin.FAVORITE, false))
        }
        return
    }
}


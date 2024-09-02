package br.com.suamusica.player

import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.view.KeyEvent
import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import androidx.media3.common.Player.COMMAND_SEEK_TO_NEXT
import androidx.media3.common.Player.COMMAND_SEEK_TO_NEXT_MEDIA_ITEM
import androidx.media3.common.Player.COMMAND_SEEK_TO_PREVIOUS
import androidx.media3.common.Player.COMMAND_SEEK_TO_PREVIOUS_MEDIA_ITEM
import androidx.media3.common.util.UnstableApi
import androidx.media3.session.CommandButton
import androidx.media3.session.LibraryResult
import androidx.media3.session.MediaLibraryService
import androidx.media3.session.MediaSession
import androidx.media3.session.R.drawable
import androidx.media3.session.SessionCommand
import androidx.media3.session.SessionResult
import br.com.suamusica.player.PlayerPlugin.Companion.POSITION_ARGUMENT
import com.google.common.collect.ImmutableList
import com.google.common.util.concurrent.Futures
import com.google.common.util.concurrent.ListenableFuture
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import com.google.gson.GsonBuilder
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.json.Json

@UnstableApi
class MediaButtonEventHandler(
    private val mediaService: MediaService,
) : MediaSession.Callback {
    private val BROWSABLE_ROOT = "/"
    private val EMPTY_ROOT = "@empty@"
    override fun onConnect(
        session: MediaSession,
        controller: MediaSession.ControllerInfo
    ): MediaSession.ConnectionResult {
        Log.d("Player", "onConnect")
        val sessionCommands =
            MediaSession.ConnectionResult.DEFAULT_SESSION_COMMANDS.buildUpon().apply {
                add(SessionCommand("notification_next", Bundle.EMPTY))
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    add(SessionCommand("notification_previous", Bundle.EMPTY))
                }
                add(SessionCommand("notification_favoritar", Bundle.EMPTY))
                add(SessionCommand("notification_desfavoritar", Bundle.EMPTY))
                add(SessionCommand("seek", session.token.extras))
                add(SessionCommand("pause", Bundle.EMPTY))
                add(SessionCommand("stop", Bundle.EMPTY))
//                add(SessionCommand("next", Bundle.EMPTY))
                add(SessionCommand("enqueue", session.token.extras))
                add(SessionCommand("prepare", session.token.extras))
                add(SessionCommand("playFromQueue", session.token.extras))
                add(SessionCommand("play", Bundle.EMPTY))
                add(SessionCommand("remove_notification", Bundle.EMPTY))
                add(SessionCommand("send_notification", session.token.extras))
                add(SessionCommand("ads_playing", Bundle.EMPTY))
                add(SessionCommand("onTogglePlayPause", Bundle.EMPTY))
            }.build()

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

    override fun onCustomCommand(
        session: MediaSession,
        controller: MediaSession.ControllerInfo,
        customCommand: SessionCommand,
        args: Bundle
    ): ListenableFuture<SessionResult> {
        Log.d("Player", "#MEDIA3# - onCustomCommand ${customCommand.customAction}")
        if (customCommand.customAction == "notification_favoritar" || customCommand.customAction == "notification_desfavoritar") {
            val isFavorite = customCommand.customAction == "notification_favoritar"
            buildIcons(isFavorite)
            PlayerSingleton.favorite(isFavorite)
        }

        if (customCommand.customAction == "seek") {
            mediaService.seek(args.getLong("position"), args.getBoolean("playWhenReady"))
        }

        if (customCommand.customAction == "onTogglePlayPause") {
            mediaService.togglePlayPause()
        }

        if (customCommand.customAction == "stop") {
            mediaService.stop()
        }
        if (customCommand.customAction == "play") {
            mediaService.play()
        }
        if (customCommand.customAction == "playFromQueue") {
            mediaService.playFromQueue(args.getInt(POSITION_ARGUMENT))
        }
        if (customCommand.customAction == "notification_previous") {
            session.player.seekToPrevious()
        }
        if (customCommand.customAction == "notification_next") {
            session.player.seekToNext()
        }
        if (customCommand.customAction == "pause") {
            mediaService.pause()
        }
        if (customCommand.customAction == "ads_playing" || customCommand.customAction == "remove_notification") {
//            mediaService.adsPlaying()
            mediaService.removeNotification()
        }
        if (customCommand.customAction == "enqueue") {
            val json = args.getString("json")
            // Log the received JSON
            Log.d("Player", "First media Received JSON for enqueue: $json")
            val gson = GsonBuilder().create()
            val mediaListType = object : TypeToken<List<Media>>() {}.type
            val mediaList: List<Media> = gson.fromJson(json, mediaListType)

            // Log the first item for debugging
            if (mediaList.isNotEmpty()) {
                Log.d("Player", "First media item: ${gson.toJson(mediaList.first())}")
            }

            mediaService.enqueue(
                args.getString("cookie")!!,
                mediaList,
                args.getBoolean("autoPlay"),
                args.getInt("startFromPos")
            )
        }
        return Futures.immediateFuture(
            SessionResult(SessionResult.RESULT_SUCCESS)
        )
    }

    fun buildIcons(isFavorite: Boolean) {
        val list = ImmutableList.of(
            CommandButton.Builder()
                .setDisplayName("Save to favorites")
                .setIconResId(if (isFavorite) drawable.media3_icon_heart_filled else drawable.media3_icon_heart_unfilled)
                .setSessionCommand(
                    SessionCommand(
                        if (isFavorite) "notification_desfavoritar" else "notification_favoritar",
                        Bundle()
                    )
                )
                .setEnabled(true)
                .build(),
            CommandButton.Builder()
                .setDisplayName("notification_next")
                .setIconResId(drawable.media3_icon_next)
                .setSessionCommand(SessionCommand("notification_next", Bundle.EMPTY))
                .setEnabled(true)
                .build(),
        )
        return mediaService.mediaSession.setCustomLayout(
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                list.plus(
                    CommandButton.Builder()
                        .setDisplayName("notification_previous")
                        .setIconResId(drawable.media3_icon_previous)
                        .setSessionCommand(SessionCommand("notification_previous", Bundle.EMPTY))
                        .build()
                )
            } else {
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
        onMediaButtonEventHandler(intent, session)
        return true
    }

    @UnstableApi
    fun onMediaButtonEventHandler(intent: Intent?, session: MediaSession) {

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
            Log.d("Player", "#MEDIA3# - Key: $ke")
            when (ke.keyCode) {
                KeyEvent.KEYCODE_MEDIA_PLAY -> {
                    PlayerSingleton.play()
                }

                KeyEvent.KEYCODE_MEDIA_PAUSE -> {
                    PlayerSingleton.pause()
                }

                KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE -> {
                    Log.d("Player", "Player: Key Code : PlayPause")
                    mediaService.togglePlayPause()
                }

                KeyEvent.KEYCODE_MEDIA_NEXT -> {
                    Log.d("Player", "Player: Key Code : Next")
                    session.player.seekToNext()
                }

                KeyEvent.KEYCODE_MEDIA_PREVIOUS -> {
                    Log.d("Player", "Player: Key Code : Previous")
                    session.player.seekToPrevious()
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


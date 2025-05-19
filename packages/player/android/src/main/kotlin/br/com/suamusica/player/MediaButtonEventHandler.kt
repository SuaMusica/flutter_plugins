package br.com.suamusica.player

import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.view.KeyEvent
import androidx.media3.cast.CastPlayer
import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import androidx.media3.common.Player.COMMAND_GET_TIMELINE
import androidx.media3.common.Player.COMMAND_SEEK_TO_NEXT
import androidx.media3.common.Player.COMMAND_SEEK_TO_NEXT_MEDIA_ITEM
import androidx.media3.common.Player.COMMAND_SEEK_TO_PREVIOUS
import androidx.media3.common.Player.COMMAND_SEEK_TO_PREVIOUS_MEDIA_ITEM
import androidx.media3.common.Player.REPEAT_MODE_ALL
import androidx.media3.common.Player.REPEAT_MODE_OFF
import androidx.media3.common.Player.REPEAT_MODE_ONE
import androidx.media3.common.Player.STATE_IDLE
import androidx.media3.common.util.UnstableApi
import androidx.media3.session.CommandButton
import androidx.media3.session.LibraryResult
import androidx.media3.session.MediaLibraryService
import androidx.media3.session.MediaSession
import androidx.media3.session.R.drawable
import androidx.media3.session.SessionCommand
import androidx.media3.session.SessionResult
import br.com.suamusica.player.PlayerPlugin.Companion.DISABLE_REPEAT_MODE
import br.com.suamusica.player.PlayerPlugin.Companion.ENQUEUE_METHOD
import br.com.suamusica.player.PlayerPlugin.Companion.FAVORITE
import br.com.suamusica.player.PlayerPlugin.Companion.ID_FAVORITE_ARGUMENT
import br.com.suamusica.player.PlayerPlugin.Companion.ID_URI_ARGUMENT
import br.com.suamusica.player.PlayerPlugin.Companion.INDEXES_TO_REMOVE
import br.com.suamusica.player.PlayerPlugin.Companion.IS_FAVORITE_ARGUMENT
import br.com.suamusica.player.PlayerPlugin.Companion.LOAD_ONLY_ARGUMENT
import br.com.suamusica.player.PlayerPlugin.Companion.NEW_URI_ARGUMENT
import br.com.suamusica.player.PlayerPlugin.Companion.PLAY_FROM_QUEUE_METHOD
import br.com.suamusica.player.PlayerPlugin.Companion.POSITIONS_LIST
import br.com.suamusica.player.PlayerPlugin.Companion.POSITION_ARGUMENT
import br.com.suamusica.player.PlayerPlugin.Companion.REMOVE_ALL
import br.com.suamusica.player.PlayerPlugin.Companion.REMOVE_IN
import br.com.suamusica.player.PlayerPlugin.Companion.REORDER
import br.com.suamusica.player.PlayerPlugin.Companion.REPEAT_MODE
import br.com.suamusica.player.PlayerPlugin.Companion.SEEK_METHOD
import br.com.suamusica.player.PlayerPlugin.Companion.SET_REPEAT_MODE
import br.com.suamusica.player.PlayerPlugin.Companion.TIME_POSITION_ARGUMENT
import br.com.suamusica.player.PlayerPlugin.Companion.TOGGLE_SHUFFLE
import br.com.suamusica.player.PlayerPlugin.Companion.UPDATE_FAVORITE
import br.com.suamusica.player.PlayerPlugin.Companion.UPDATE_IS_PLAYING
import br.com.suamusica.player.PlayerPlugin.Companion.UPDATE_MEDIA_URI
import br.com.suamusica.player.PlayerSingleton.playerChangeNotifier
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
                add(SessionCommand(SEEK_METHOD, session.token.extras))
                add(SessionCommand("pause", Bundle.EMPTY))
                add(SessionCommand("stop", Bundle.EMPTY))
                add(SessionCommand("next", Bundle.EMPTY))
                add(SessionCommand("previous", Bundle.EMPTY))
                add(SessionCommand(UPDATE_FAVORITE, session.token.extras))
                add(SessionCommand(FAVORITE, session.token.extras))
                add(SessionCommand(TOGGLE_SHUFFLE, Bundle.EMPTY))
                add(SessionCommand(REPEAT_MODE, Bundle.EMPTY))
                add(SessionCommand(DISABLE_REPEAT_MODE, Bundle.EMPTY))
                add(SessionCommand(ENQUEUE_METHOD, session.token.extras))
                add(SessionCommand(REMOVE_ALL, Bundle.EMPTY))
                add(SessionCommand(REORDER, session.token.extras))
                add(SessionCommand(REMOVE_IN, session.token.extras))
                add(SessionCommand(SET_REPEAT_MODE, session.token.extras))
                add(SessionCommand("prepare", session.token.extras))
                add(SessionCommand("playFromQueue", session.token.extras))
                add(SessionCommand("play", Bundle.EMPTY))
                add(SessionCommand("remove_notification", Bundle.EMPTY))
                add(SessionCommand("send_notification", session.token.extras))
                add(SessionCommand("ads_playing", Bundle.EMPTY))
                add(SessionCommand("onTogglePlayPause", Bundle.EMPTY))
                add(SessionCommand(UPDATE_MEDIA_URI, session.token.extras))
                add(SessionCommand(UPDATE_IS_PLAYING, session.token.extras))
                add(SessionCommand("cast", session.token.extras))
                add(SessionCommand("cast_next_media", session.token.extras))
            }.build()

        val playerCommands =
            MediaSession.ConnectionResult.DEFAULT_PLAYER_COMMANDS.buildUpon()
                .remove(COMMAND_SEEK_TO_PREVIOUS)
                .remove(COMMAND_SEEK_TO_PREVIOUS_MEDIA_ITEM)
                .remove(COMMAND_SEEK_TO_NEXT)
                .remove(COMMAND_SEEK_TO_NEXT_MEDIA_ITEM)
                .add(COMMAND_GET_TIMELINE)
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
            PlayerSingleton.favorite(isFavorite)
            buildIcons()
        }

        if (customCommand.customAction == "cast") {
            mediaService.castWithCastPlayer(args.getString("cast_id"))
        }

        if (customCommand.customAction == UPDATE_IS_PLAYING) {
            buildIcons()
        }

        if (customCommand.customAction == SEEK_METHOD) {
            val position = args.getLong("position")
            val playWhenReady = args.getBoolean("playWhenReady")
            session.player.seekTo(position)
            session.player.playWhenReady = playWhenReady
        }
        if (customCommand.customAction == FAVORITE) {
            val isFavorite = args.getBoolean(IS_FAVORITE_ARGUMENT)
            val mediaItem = session.player.currentMediaItem!!
            updateFavoriteMetadata(
                session.player,
                session.player.currentMediaItemIndex,
                mediaItem,
                isFavorite,
            )
            buildIcons()
        }
        if (customCommand.customAction == REMOVE_ALL) {
            mediaService.removeAll()
        }
        if (customCommand.customAction == REMOVE_IN) {
            mediaService.removeIn(
                args.getIntegerArrayList(INDEXES_TO_REMOVE) ?: emptyList()
            )
        }
        if (customCommand.customAction == REORDER) {
            val oldIndex = args.getInt("oldIndex")
            val newIndex = args.getInt("newIndex")
            val json = args.getString(POSITIONS_LIST)
            val gson = GsonBuilder().create()
            val mediaListType = object : TypeToken<List<Map<String, Int>>?>() {}.type
            val positionsList: List<Map<String, Int>> = gson.fromJson(json, mediaListType)

            mediaService.reorder(oldIndex, newIndex, positionsList)
        }

        if (customCommand.customAction == "onTogglePlayPause") {
            if (session.player.isPlaying) {
                session.player.pause()
            } else {
                session.player.play()
            }
        }

        if (customCommand.customAction == TOGGLE_SHUFFLE) {
//            val list = args.getSerializable("list",ArrayList<Map<String, Int>>()::class.java)
            val json = args.getString(POSITIONS_LIST)
            val gson = GsonBuilder().create()
            val mediaListType = object : TypeToken<List<Map<String, Int>>>() {}.type
            val positionsList: List<Map<String, Int>> = gson.fromJson(json, mediaListType)
            mediaService.toggleShuffle(positionsList)
        }
        if (customCommand.customAction == REPEAT_MODE) {
            session.player.let {
                when (it.repeatMode) {
                    REPEAT_MODE_OFF -> {
                        it.repeatMode = REPEAT_MODE_ALL
                    }

                    REPEAT_MODE_ONE -> {
                        it.repeatMode = REPEAT_MODE_OFF
                    }

                    else -> {
                        it.repeatMode = REPEAT_MODE_ONE
                    }
                }
            }
        }
        if (customCommand.customAction == DISABLE_REPEAT_MODE) {
            mediaService.disableRepeatMode()
        }
        if (customCommand.customAction == "stop") {
            session.player.stop()
        }
        if (customCommand.customAction == "play") {
            if (session.player.playbackState == STATE_IDLE) {
                session.player.prepare()
            }
            session.player.play()
        }

        if (customCommand.customAction == SET_REPEAT_MODE) {
            val mode = args.getString("mode")
            val convertedMode = when (mode) {
                "off" -> REPEAT_MODE_OFF
                "one" -> REPEAT_MODE_ONE
                "all" -> REPEAT_MODE_ALL
                else -> REPEAT_MODE_OFF
            }
            if (session.player is CastPlayer) {
                playerChangeNotifier?.onRepeatChanged(convertedMode)
            }else {
                session.player.repeatMode = convertedMode
            }
        }

        if (customCommand.customAction == "cast_next_media") {
            val json = args.getString("media")
            val gson = GsonBuilder().create()
            val mediaListType = object : TypeToken<Media>() {}.type
            val media: Media = gson.fromJson(json, mediaListType)
            session.player.setMediaItem(mediaService.createMediaItem(media))
        }

        if (customCommand.customAction == PLAY_FROM_QUEUE_METHOD) {
            if (session.player is CastPlayer) {
                PlayerSingleton.getMediaFromQueue(args.getInt(POSITION_ARGUMENT))
            } else {
                mediaService.playFromQueue(
                    args.getInt(POSITION_ARGUMENT), args.getLong(TIME_POSITION_ARGUMENT),
                    args.getBoolean(
                        LOAD_ONLY_ARGUMENT
                    ),
                )
            }
        }
        if (customCommand.customAction == "notification_previous" || customCommand.customAction == "previous") {
            if (session.player is CastPlayer) {
                PlayerSingleton.getPreviousMedia()
            } else {
                if (session.player.hasPreviousMediaItem()) {
                    session.player.seekToPreviousMediaItem()
                } else {
                    session.player.seekToPrevious()
                }
            }
        }
        if (customCommand.customAction == "notification_next" || customCommand.customAction == "next") {
            if (session.player is CastPlayer) {
                PlayerSingleton.getNextMedia()
            } else {
                session.player.seekToNextMediaItem()
            }
        }

        if (customCommand.customAction == "pause") {
            session.player.pause()
        }

        if (customCommand.customAction == UPDATE_MEDIA_URI) {
            val newUri = args.getString(NEW_URI_ARGUMENT)
            val id = args.getInt(ID_URI_ARGUMENT)
            session.player.let {
                for (i in 0 until it.mediaItemCount) {
                    val mediaItem = it.getMediaItemAt(i)
                    if (mediaItem.mediaId == id.toString()) {
                        mediaService.updateMediaUri(i, newUri)
                        break
                    }
                }
            }
        }

        if (customCommand.customAction == UPDATE_FAVORITE) {
            val isFavorite = args.getBoolean(IS_FAVORITE_ARGUMENT)
            val id = args.getInt(ID_FAVORITE_ARGUMENT)
            session.player.let {
                for (i in 0 until it.mediaItemCount) {
                    val mediaItem = it.getMediaItemAt(i)
                    if (mediaItem.mediaId == id.toString()) {
                        updateFavoriteMetadata(it, i, mediaItem, isFavorite)
                        if (id.toString() == session.player.currentMediaItem?.mediaId) {
                            buildIcons()
                        }
                        break
                    }
                }
            }
            PlayerSingleton.favorite(isFavorite)
        }
        if (customCommand.customAction == "ads_playing") {
            mediaService.removeNotification()
        }
        if (customCommand.customAction == ENQUEUE_METHOD) {
            val json = args.getString("json")
            val gson = GsonBuilder().create()
            val mediaListType = object : TypeToken<List<Media>>() {}.type
            val mediaList: List<Media> = gson.fromJson(json, mediaListType)
            buildIcons()
            mediaService.enqueue(
                mediaList,
                args.getBoolean("autoPlay"),
            )
        }
        return Futures.immediateFuture(
            SessionResult(SessionResult.RESULT_SUCCESS)
        )
    }

    private fun updateFavoriteMetadata(
        player: Player,
        i: Int,
        mediaItem: MediaItem,
        isFavorite: Boolean
    ) {
        player.replaceMediaItem(
            i,
            mediaItem.buildUpon().setMediaMetadata(
                mediaItem.mediaMetadata.buildUpon().setExtras(
                    Bundle().apply {
                        putBoolean(IS_FAVORITE_ARGUMENT, isFavorite)
                    }
                ).build()
            ).build()
        )
    }

    fun buildIcons() {
        val isFavorite =
            mediaService.smPlayer?.currentMediaItem?.mediaMetadata?.extras?.getBoolean(
                IS_FAVORITE_ARGUMENT
            ) ?: false

        val baseList = mutableListOf(
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
                .build()
        )

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            baseList.add(
                CommandButton.Builder()
                    .setDisplayName("notification_next")
                    .setIconResId(drawable.media3_icon_next)
                    .setSessionCommand(SessionCommand("notification_next", Bundle.EMPTY))
                    .setEnabled(true)
                    .build()
            )
            baseList.add(
                CommandButton.Builder()
                    .setDisplayName("notification_previous")
                    .setIconResId(drawable.media3_icon_previous)
                    .setSessionCommand(SessionCommand("notification_previous", Bundle.EMPTY))
                    .setEnabled(true)
                    .build()
            )
        }
        return mediaService.mediaSession.setCustomLayout(baseList)
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
                    if (session.player.isPlaying) {
                        PlayerSingleton.pause()
                    } else {
                        PlayerSingleton.play()
                    }
                }

                KeyEvent.KEYCODE_MEDIA_NEXT -> {
                    Log.d("Player", "Player: Key Code : Next")
//                    session.player.seekToNext()
                    PlayerSingleton.next()
                }

                KeyEvent.KEYCODE_MEDIA_PREVIOUS -> {
                    Log.d("Player", "Player: Key Code : Previous")
//                    session.player.seekToPrevious()
                    PlayerSingleton.previous()
                }

                KeyEvent.KEYCODE_MEDIA_STOP -> {
                    PlayerSingleton.stop()
                }
            }
        } else if (intent.hasExtra(FAVORITE)) {
            PlayerSingleton.favorite(intent.getBooleanExtra(FAVORITE, false))
        }
        return
    }
}


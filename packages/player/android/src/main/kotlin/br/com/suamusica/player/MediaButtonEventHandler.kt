package br.com.suamusica.player

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.util.Log
import android.view.KeyEvent
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.common.Player
import androidx.media3.common.Player.COMMAND_PLAY_PAUSE
import androidx.media3.common.Player.COMMAND_SEEK_TO_NEXT
import androidx.media3.common.Player.COMMAND_SEEK_TO_NEXT_MEDIA_ITEM
import androidx.media3.common.Player.COMMAND_SEEK_TO_PREVIOUS
import androidx.media3.common.Player.COMMAND_SEEK_TO_PREVIOUS_MEDIA_ITEM
import androidx.media3.common.util.UnstableApi
import androidx.media3.session.CommandButton
import androidx.media3.session.MediaSession
import androidx.media3.session.SessionCommand
import androidx.media3.session.SessionResult
import com.google.common.collect.ImmutableList
import com.google.common.util.concurrent.Futures
import com.google.common.util.concurrent.ListenableFuture
import java.io.File

@UnstableApi
class MediaButtonEventHandler(
    private val mediaService: MediaService?,
) : MediaSession.Callback {
    override fun onConnect(
        session: MediaSession,
        controller: MediaSession.ControllerInfo
    ): MediaSession.ConnectionResult {
        Log.d("Player", "onConnect")
        val sessionCommands = MediaSession.ConnectionResult.DEFAULT_SESSION_COMMANDS.buildUpon()
            .add(SessionCommand("next", Bundle.EMPTY))
            .add(SessionCommand("seek", session.token.extras))
            .add(SessionCommand("previous", Bundle.EMPTY))
//            .add(SessionCommand("pause", Bundle.EMPTY))
            .add(SessionCommand("favoritar", Bundle()))
            .add(SessionCommand("prepare", session.token.extras))
//            .add(SessionCommand("play", Bundle.EMPTY))
            .add(SessionCommand("remove_notification", Bundle.EMPTY))
            .add(SessionCommand("send_notification", session.token.extras))
            .add(SessionCommand("ads_playing", Bundle.EMPTY))
            .add(SessionCommand("onTogglePlayPause", Bundle.EMPTY))
            .build()

        val playerCommands =
            MediaSession.ConnectionResult.DEFAULT_PLAYER_COMMANDS.buildUpon()
//                .remove(COMMAND_SEEK_TO_NEXT)
//                .remove(COMMAND_SEEK_TO_NEXT_MEDIA_ITEM)
//                .remove(COMMAND_SEEK_TO_PREVIOUS)
//                .remove(COMMAND_SEEK_TO_PREVIOUS_MEDIA_ITEM)
                .removeAll()
                .build()

        return MediaSession.ConnectionResult.AcceptedResultBuilder(session)
            .setAvailableSessionCommands(sessionCommands)
            .setAvailablePlayerCommands(playerCommands)
            .build()
    }

//    override fun onPostConnect(session: MediaSession, controller: MediaSession.ControllerInfo) {
//        super.onPostConnect(session, controller)
//        if (notificationPlayerCustomCommandButtons.isNotEmpty()) {
//            /* Setting custom player command buttons to mediaLibrarySession for player notification. */
//            mediaLibrarySession.setCustomLayout(notificationPlayerCustomCommandButtons)
//        }
//    }

//    override fun onPlaybackResumption(
//        mediaSession: MediaSession,
//        controller: MediaSession.ControllerInfo
//    ): ListenableFuture<MediaSession.MediaItemsWithStartPosition> {
//        Log.d("Player", "TESTE1 onPlaybackResumption")
//        return super.onPlaybackResumption(mediaSession, controller)
//    }


//    override fun onSetMediaItems(
//        mediaSession: MediaSession,
//        controller: MediaSession.ControllerInfo,
//        mediaItems: MutableList<MediaItem>,
//        startIndex: Int,
//        startPositionMs: Long
//    ): ListenableFuture<MediaSession.MediaItemsWithStartPosition> {
//        Log.d("Player", "TESTE1 onSetMediaItems")
//        return super.onSetMediaItems(
//            mediaSession,
//            controller,
//            mediaItems,
//            startIndex,
//            startPositionMs
//        )
//    }

//    override fun onAddMediaItems(
//        mediaSession: MediaSession,
//        controller: MediaSession.ControllerInfo,
//        mediaItems: MutableList<MediaItem>
//    ): ListenableFuture<MutableList<MediaItem>> {
//        Log.d("Player", "TESTE1 onAddMediaItems")
//        return super.onAddMediaItems(mediaSession, controller, mediaItems)
//    }


    override fun onCustomCommand(
        session: MediaSession,
        controller: MediaSession.ControllerInfo,
        customCommand: SessionCommand,
        args: Bundle
    ): ListenableFuture<SessionResult> {
        Log.d("Player", "TESTE1 CUSTOM_COMMAND: ${customCommand.customAction} | $args")
//        if (session.player.mediaMetadata.title == "Propaganda") {
//            buildSetCustomLayout(session, false, mediaService)
//            return Futures.immediateFuture(
//                SessionResult(SessionResult.RESULT_SUCCESS)
//            )
//        }

        if (customCommand.customAction == "ads_playing") {
            mediaService?.adsPlaying()
        }

        if (customCommand.customAction == "onTogglePlayPause") {
            mediaService?.togglePlayPause()
        }

        if (customCommand.customAction == "send_notification") {
            args.let {
                val name = it.getString(PlayerPlugin.NAME_ARGUMENT)!!
                val author = it.getString(PlayerPlugin.AUTHOR_ARGUMENT)!!
                val url = it.getString(PlayerPlugin.URL_ARGUMENT)!!
                val coverUrl = it.getString(PlayerPlugin.COVER_URL_ARGUMENT)!!
                val isPlaying = it.getBoolean(PlayerPlugin.IS_PLAYING_ARGUMENT)
                val isFavorite = it.getBoolean(PlayerPlugin.IS_FAVORITE_ARGUMENT)
                val bigCoverUrl = it.getString(PlayerPlugin.BIG_COVER_URL_ARGUMENT)
//                buildSetCustomLayout(session, isFavorite, mediaService)
                mediaService?.sendNotification(
                    Media(
                        name,
                        author,
                        url,
                        coverUrl,
                        bigCoverUrl,
                        isFavorite,
                    ),
                    isPlaying,
                )
            }
        }
        if (customCommand.customAction == "play") {
            mediaService?.play()
        }
        if (customCommand.customAction == "pause") {
            mediaService?.pause()
        }
        if (customCommand.customAction == "remove_notification") {
            val metadataBuilder = MediaMetadata.Builder()
            metadataBuilder.apply {
                setArtist("Propaganda")
                setTitle("Propaganda")
                setDisplayTitle("Propaganda")
            }
            val url =
                session.player.mediaMetadata.extras?.getString(PlayerPlugin.URL_ARGUMENT) ?: ""
            val uri = if (url.startsWith("/")) Uri.fromFile(File(url)) else Uri.parse(url)
            val a =
                MediaItem.Builder().setMediaMetadata(metadataBuilder.build()).setUri(uri).build()
            session.player.replaceMediaItem(0, a)

//            session.player.removeMediaItem(0)
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
                Log.d(
                    "Player",
                    "TESTE1 bigCoverUrl: $bigCoverUrl"
                )
//                buildSetCustomLayout(session, isFavorite ?: false, mediaService)
                mediaService?.prepare(
                    cookie,
                    Media(name, author, url, coverUrl, bigCoverUrl, isFavorite)
                )
            }
        }
        return Futures.immediateFuture(
            SessionResult(SessionResult.RESULT_SUCCESS)
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
        } else if (intent.hasExtra(FAVORITE)) {
            PlayerSingleton.favorite(intent.getBooleanExtra(FAVORITE, false))
        }

    }


}


@UnstableApi
fun buildSetCustomLayout(
    session: MediaSession,
    shouldFavorite: Boolean,
    mediaService: MediaService,
) {

    mediaService.mediaSession?.setCustomLayout(
        session.mediaNotificationControllerInfo!!,
        ImmutableList.of(

            CommandButton.Builder()
                .setDisplayName("Save to favorites")
                .setIconResId(
                    if (shouldFavorite) {
                        R.drawable.ic_unfavorite_notification_player
                    } else {
                        R.drawable.ic_favorite_notification_player
                    }
                )
                .setSessionCommand(
                    SessionCommand(
                        "favoritar",
                        session.player.mediaMetadata.extras ?: Bundle.EMPTY
                    )
                )
                .build(),
            CommandButton.Builder()
                .setDisplayName("previous")
                .setIconResId(androidx.media3.session.R.drawable.media3_notification_seek_to_previous)
                .setSessionCommand(SessionCommand("previous", Bundle.EMPTY))
                .build(),
            CommandButton.Builder()
                .setDisplayName("NEXT")
                .setIconResId(androidx.media3.session.R.drawable.media3_notification_seek_to_next)
                .setSessionCommand(SessionCommand("next", Bundle.EMPTY))
                .build(),
        )
    )
}
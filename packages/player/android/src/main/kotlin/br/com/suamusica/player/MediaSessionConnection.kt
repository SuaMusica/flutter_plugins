package br.com.suamusica.player

import android.content.ComponentName
import android.content.Context
import android.os.Bundle
import android.util.Log
import androidx.media3.common.util.UnstableApi
import androidx.media3.session.MediaController
import androidx.media3.session.SessionCommand
import androidx.media3.session.SessionToken
import br.com.suamusica.player.PlayerPlugin.Companion.DISABLE_REPEAT_MODE
import br.com.suamusica.player.PlayerPlugin.Companion.ENQUEUE_METHOD
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
import br.com.suamusica.player.PlayerPlugin.Companion.UPDATE_MEDIA_URI
import com.google.common.util.concurrent.ListenableFuture
import com.google.common.util.concurrent.MoreExecutors
import com.google.gson.Gson
import java.util.concurrent.Executors

@UnstableApi
class MediaSessionConnection(
    private val context: Context,
) {
    companion object {
        private const val TAG = "MediaSessionConnection"
    }

    var releaseMode: Int
        get() = ReleaseMode.RELEASE.ordinal
        set(value) {
            val bundle = Bundle().apply {
                putInt("release_mode", value)
            }
            sendCommand("set_release_mode", bundle)
        }

    var currentPosition = 0L
    var duration = 0L

    private var mediaController: MediaController? = null
    private var controllerFuture: ListenableFuture<MediaController>? = null
    private val executor = MoreExecutors.listeningDecorator(Executors.newSingleThreadExecutor())

    init {
        initializeController()
    }

    private fun initializeController() {
        try {
            val sessionToken = SessionToken(
                context,
                ComponentName(context, MediaLibrarySession::class.java)
            )

            controllerFuture = MediaController.Builder(context, sessionToken)
                .buildAsync()

            controllerFuture?.addListener({
                try {
                    mediaController = controllerFuture?.get()
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to initialize MediaController", e)
                    mediaController = null
                }
            }, MoreExecutors.directExecutor())

        } catch (e: Exception) {
            Log.e(TAG, "Failed to create MediaController future", e)
        }
    }

    fun enqueue(medias: String, autoPlay: Boolean) {
        val bundle = Bundle().apply {
            putString("json", medias)
            putBoolean("autoPlay", autoPlay)
        }
        sendCommand(ENQUEUE_METHOD, bundle)
    }

    fun playFromQueue(index: Int, timePosition: Long, loadOnly: Boolean) {
        val bundle = Bundle().apply {
            putInt(POSITION_ARGUMENT, index)
            putLong(TIME_POSITION_ARGUMENT, timePosition)
            putBoolean(LOAD_ONLY_ARGUMENT, loadOnly)
        }
        sendCommand(PLAY_FROM_QUEUE_METHOD, bundle)
    }

    fun play() {
        sendCommand("play")
    }

    fun cast(id: String) {
        val bundle = Bundle().apply {
            putString("cast_id", id)
        }
        sendCommand("cast", bundle)
    }

    fun setCastMedia(media: String) {
        val bundle = Bundle().apply {
            putString("media", media)
        }
        sendCommand("cast_next_media", bundle)
    }

    fun setRepeatMode(mode: String) {
        val bundle = Bundle().apply {
            putString("mode", mode)
        }
        sendCommand(SET_REPEAT_MODE, bundle)
    }

    fun reorder(oldIndex: Int, newIndex: Int, positionsList: List<Map<String, Int>>) {
        val bundle = Bundle().apply {
            putInt("oldIndex", oldIndex)
            putInt("newIndex", newIndex)
            putString(POSITIONS_LIST, Gson().toJson(positionsList))
        }
        sendCommand(REORDER, bundle)
    }

    fun togglePlayPause() {
        sendCommand("onTogglePlayPause")
    }

    fun adsPlaying() {
        sendCommand("ads_playing")
    }

    fun pause() {
        sendCommand("pause")
    }

    fun updateFavorite(isFavorite: Boolean, idFavorite: Int) {
        val bundle = Bundle().apply {
            putBoolean(IS_FAVORITE_ARGUMENT, isFavorite)
            putInt(ID_FAVORITE_ARGUMENT, idFavorite)
        }
        sendCommand(UPDATE_FAVORITE, bundle)
    }

    fun updateMediaUri(id: Int, newUri: String?) {
        val bundle = Bundle().apply {
            putString(NEW_URI_ARGUMENT, newUri)
            putInt(ID_URI_ARGUMENT, id)
        }
        sendCommand(UPDATE_MEDIA_URI, bundle)
    }

    fun removeAll() {
        sendCommand(REMOVE_ALL)
    }

    fun removeIn(indexes: List<Int>) {
        val bundle = Bundle().apply {
            putIntegerArrayList(INDEXES_TO_REMOVE, ArrayList(indexes))
        }
        sendCommand(REMOVE_IN, bundle)
    }

    fun next() {
        sendCommand("next")
    }

    fun toggleShuffle(positionsList: List<Map<String, Int>>) {
        val bundle = Bundle().apply {
            putString(POSITIONS_LIST, Gson().toJson(positionsList))
        }
        sendCommand(TOGGLE_SHUFFLE, bundle)
    }

    fun repeatMode() {
        sendCommand(REPEAT_MODE)
    }

    fun disableRepeatMode() {
        sendCommand(DISABLE_REPEAT_MODE)
    }

    fun previous() {
        sendCommand("previous")
    }

    fun favorite(shouldFavorite: Boolean) {
        val bundle = Bundle().apply {
            putBoolean(IS_FAVORITE_ARGUMENT, shouldFavorite)
        }
        sendCommand(PlayerPlugin.FAVORITE, bundle)
    }

    fun stop() {
        sendCommand("stop")
    }

    fun seek(position: Long, playWhenReady: Boolean) {
        val bundle = Bundle().apply {
            putLong("position", position)
            putBoolean("playWhenReady", playWhenReady)
        }
        sendCommand(SEEK_METHOD, bundle)
    }

    fun release() {
        sendCommand("release")
        cleanup()
    }

    fun removeNotification() {
        sendCommand("remove_notification")
    }

    private fun sendCommand(command: String, bundle: Bundle? = null) {
        val controller = mediaController
        if (controller != null && controller.isConnected) {
            val commandBundle = bundle ?: Bundle()
            val sessionCommand = SessionCommand(command, commandBundle)
            controller.sendCustomCommand(sessionCommand, commandBundle)
            Log.d(TAG, "Command sent: $command")
        } else {
            Log.w(TAG, "MediaController not connected, cannot send command: $command")
            // Optionally retry connection if needed
            if (mediaController == null) {
                initializeController()
            }
        }
    }

    private fun cleanup() {
        try {
            controllerFuture?.let { future ->
                if (!future.isDone) {
                    future.cancel(true)
                }
            }
            controllerFuture?.let { MediaController.releaseFuture(it) }
            executor.shutdown()
        } catch (e: Exception) {
            Log.e(TAG, "Error during cleanup", e)
        } finally {
            mediaController = null
            controllerFuture = null
        }
    }
}
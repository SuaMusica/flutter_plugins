package br.com.suamusica.player

import android.content.ComponentName
import android.content.Context
import android.os.Bundle
import android.os.ResultReceiver
import android.support.v4.media.MediaBrowserCompat
import android.support.v4.media.MediaMetadataCompat
import android.support.v4.media.session.MediaControllerCompat
import android.support.v4.media.session.PlaybackStateCompat
import android.util.Log
import br.com.suamusica.player.PlayerPlugin.Companion.DISABLE_REPEAT_MODE
import br.com.suamusica.player.PlayerPlugin.Companion.ENQUEUE
import br.com.suamusica.player.PlayerPlugin.Companion.ID_FAVORITE_ARGUMENT
import br.com.suamusica.player.PlayerPlugin.Companion.ID_URI_ARGUMENT
import br.com.suamusica.player.PlayerPlugin.Companion.INDEXES_TO_REMOVE
import br.com.suamusica.player.PlayerPlugin.Companion.IS_FAVORITE_ARGUMENT
import br.com.suamusica.player.PlayerPlugin.Companion.LOAD_ONLY
import br.com.suamusica.player.PlayerPlugin.Companion.NEW_URI_ARGUMENT
import br.com.suamusica.player.PlayerPlugin.Companion.PLAY_FROM_QUEUE_METHOD
import br.com.suamusica.player.PlayerPlugin.Companion.POSITIONS_LIST
import br.com.suamusica.player.PlayerPlugin.Companion.POSITION_ARGUMENT
import br.com.suamusica.player.PlayerPlugin.Companion.REMOVE_ALL
import br.com.suamusica.player.PlayerPlugin.Companion.REMOVE_IN
import br.com.suamusica.player.PlayerPlugin.Companion.REORDER
import br.com.suamusica.player.PlayerPlugin.Companion.REPEAT_MODE
import br.com.suamusica.player.PlayerPlugin.Companion.SET_REPEAT_MODE
import br.com.suamusica.player.PlayerPlugin.Companion.TIME_POSITION_ARGUMENT
import br.com.suamusica.player.PlayerPlugin.Companion.TOGGLE_SHUFFLE
import br.com.suamusica.player.PlayerPlugin.Companion.UPDATE_FAVORITE
import br.com.suamusica.player.PlayerPlugin.Companion.UPDATE_MEDIA_URI
import com.google.gson.Gson
import java.lang.ref.WeakReference

class MediaSessionConnection(
    context: Context,
    val playerChangeNotifier: PlayerChangeNotifier
) {
    val TAG = "Player"

    var releaseMode: Int
        get() {
            return ReleaseMode.RELEASE.ordinal
        }
        set(value) {
            val bundle = Bundle()
            bundle.putInt("release_mode", value)
            sendCommand("set_release_mode", bundle)
        }
    var currentPosition = 0L

    var duration = 0L

    private val weakContext = WeakReference(context)
    private val weakServiceComponent =
        WeakReference(ComponentName(context, MediaService::class.java))

    private val mediaBrowserConnectionCallback = MediaBrowserConnectionCallback(context)
    private var mediaBrowser: MediaBrowserCompat? = null
    private var mediaController: MediaControllerCompat? = null

    init {
        ensureMediaBrowser {
        }
    }

    fun enqueue(medias: String, autoPlay: Boolean,shouldNotifyTransition:Boolean) {
        val bundle = Bundle()
        bundle.putString("json", medias)
        bundle.putBoolean("autoPlay", autoPlay)
        bundle.putBoolean("shouldNotifyTransition", shouldNotifyTransition)
        sendCommand(ENQUEUE, bundle)
    }

    fun playFromQueue(index: Int, timePosition: Long, loadOnly: Boolean) {
        val bundle = Bundle()
        bundle.putInt(POSITION_ARGUMENT, index)
        bundle.putLong(TIME_POSITION_ARGUMENT, timePosition)
        bundle.putBoolean(LOAD_ONLY, loadOnly)
        sendCommand(PLAY_FROM_QUEUE_METHOD, bundle)
    }

    fun play(shouldPrepare: Boolean = false) {
        val bundle = Bundle()
        bundle.putBoolean("shouldPrepare", shouldPrepare)
        sendCommand("play", bundle)
    }

    fun setRepeatMode(mode: String) {
        val bundle = Bundle()
        bundle.putString("mode", mode)
        sendCommand(SET_REPEAT_MODE, bundle)
    }

    fun reorder(oldIndex: Int, newIndex: Int, positionsList: List<Map<String, Int>>) {
        val bundle = Bundle()
        bundle.putInt("oldIndex", oldIndex)
        bundle.putInt("newIndex", newIndex)
        val json = Gson().toJson(positionsList)
        bundle.putString(POSITIONS_LIST, json)
        sendCommand(REORDER, bundle)
    }

    fun togglePlayPause() {
        sendCommand("togglePlayPause", null)
    }

    fun adsPlaying() {
        sendCommand("ads_playing", null)
    }

    fun pause() {
        sendCommand("pause", null)
    }

    fun updateFavorite(isFavorite: Boolean, idFavorite: Int) {
        val bundle = Bundle()
        bundle.putBoolean(IS_FAVORITE_ARGUMENT, isFavorite)
        bundle.putInt(ID_FAVORITE_ARGUMENT, idFavorite)
        sendCommand(UPDATE_FAVORITE, bundle)
    }

    fun updateMediaUri(id:Int,newUri:String?){
        val bundle = Bundle()
        bundle.putString(NEW_URI_ARGUMENT,newUri)
        bundle.putInt(ID_URI_ARGUMENT,id)
        sendCommand(UPDATE_MEDIA_URI, bundle)
    }

    fun removeAll() {
        sendCommand(REMOVE_ALL, null)
    }

    fun removeIn(indexes: List<Int>) {
        val bundle = Bundle()
        bundle.putIntegerArrayList(INDEXES_TO_REMOVE, ArrayList(indexes))
        sendCommand(REMOVE_IN, bundle)
    }

    fun next() {
        sendCommand("next", null)
    }

    fun toggleShuffle(positionsList: List<Map<String, Int>>) {
        val bundle = Bundle()
        //API33
//        bundle.putSerializable(POSITIONS_LIST, ArrayList(positionsList))
        val json = Gson().toJson(positionsList)
        bundle.putString(POSITIONS_LIST, json)
        sendCommand(TOGGLE_SHUFFLE, bundle)
    }

    fun repeatMode() {
        sendCommand(REPEAT_MODE, null)
    }

    fun disableRepeatMode() {
        sendCommand(DISABLE_REPEAT_MODE, null)
    }

    fun previous() {
        sendCommand("previous", null)
    }

    fun favorite(shouldFavorite: Boolean) {
        val bundle = Bundle()
        bundle.putBoolean(IS_FAVORITE_ARGUMENT, shouldFavorite)
        sendCommand(PlayerPlugin.FAVORITE, bundle)
    }

    fun stop() {
        sendCommand("stop", null)
    }

    fun seek(position: Long, playWhenReady: Boolean) {
        val bundle = Bundle()
        bundle.putLong("position", position)
        bundle.putBoolean("playWhenReady", playWhenReady)
        sendCommand("seek", bundle)
    }

    fun release() {
        sendCommand("release", null)
    }

    fun removeNotification() {
        sendCommand("remove_notification", null)
    }

    private fun sendCommand(
        command: String,
        bundle: Bundle? = null,
        callbackHandler: ResultReceiver? = null
    ) {
        ensureMediaBrowser {
            ensureMediaController {
                it.sendCommand(command, bundle, callbackHandler)
            }
        }
    }

    private fun ensureMediaBrowser(callable: (mediaBrowser: MediaBrowserCompat) -> Unit) {
        try {
            if (mediaBrowser == null) {
                val context = weakContext.get()
                val serviceComponent = weakServiceComponent.get()
                mediaBrowser = MediaBrowserCompat(
                    context, serviceComponent,
                    mediaBrowserConnectionCallback, null
                )
            }

            mediaBrowser?.let {
                if (it.isConnected.not()) {
                    it.disconnect()
                    it.connect()
                } else {
                    callable(mediaBrowser!!)
                }
            }
        } catch (e: Exception) {
            if (e.message?.contains("connect() called while neither disconnecting nor disconnected") == true)
                Log.i(
                    "Player",
                    "MediaBrowser is CONNECT_STATE_CONNECTING(2) or CONNECT_STATE_CONNECTED(3) or CONNECT_STATE_SUSPENDED(4)"
                )
            else
                Log.e("Player", "Failed", e)
        }
    }

    private fun ensureMediaController(callable: (mediaController: MediaControllerCompat) -> Unit) {
        mediaController?.let(callable)
    }

    private inner class MediaBrowserConnectionCallback(private val context: Context) :
        MediaBrowserCompat.ConnectionCallback() {
        override fun onConnected() {
            Log.i(TAG, "MediaBrowserConnectionCallback.onConnected : STARTED")
            mediaBrowser?.let { mediaBrowser ->
                if (mediaBrowser.isConnected.not())
                    return

                mediaController = MediaControllerCompat(context, mediaBrowser.sessionToken)
            }
            Log.i(TAG, "MediaBrowserConnectionCallback.onConnected : ENDED")
        }

        override fun onConnectionSuspended() {
            Log.i(TAG, "MediaBrowserConnectionCallback.onConnectionSuspended : STARTED")

            mediaController = null

            Log.i(TAG, "MediaBrowserConnectionCallback.onConnectionSuspended : ENDED")
        }

        override fun onConnectionFailed() {
            Log.i(TAG, "MediaBrowserConnectionCallback.onConnectionFailed : STARTED")

            mediaController = null

            Log.i(TAG, "MediaBrowserConnectionCallback.onConnectionFailed : ENDED")
        }
    }
}
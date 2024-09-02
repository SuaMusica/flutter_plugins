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

    fun enqueue(cookie: String, medias: String, autoPlay:Boolean) {
        val bundle = Bundle()
        bundle.putString("cookie", cookie)
        bundle.putString("json", medias)
        bundle.putBoolean("autoPlay", autoPlay)
        sendCommand("enqueue", bundle)
    }

    fun playFromQueue(index: Int) {
        val bundle = Bundle()
        bundle.putInt("position", index)
        sendCommand("playFromQueue", bundle)
    }

    fun play(index: Int? = null) {
        val bundle = Bundle()
        if (index != null) {
            bundle.putInt("index", index)
        }
        sendCommand("play", bundle)
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
    fun next() {
        sendCommand("next", null)
    }

    fun favorite(shouldFavorite: Boolean) {
        val bundle = Bundle()
        bundle.putBoolean(PlayerPlugin.IS_FAVORITE_ARGUMENT, shouldFavorite)
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
                mediaController?.registerCallback(object : MediaControllerCompat.Callback() {
                    var lastState = PlaybackStateCompat.STATE_NONE - 1
                    override fun onPlaybackStateChanged(state: PlaybackStateCompat) {
                        if (lastState != state.state) {
                            Log.i(TAG, "onPlaybackStateChanged2: $state")
                            lastState = state.state
//                            playerChangeNotifier.notifyStateChange(state.state)
                        }
                    }

                    override fun onExtrasChanged(extras: Bundle) {
                        if (extras.containsKey("type")) {
                            when (extras.getString("type")) {
                                "position" -> {
                                    val position = extras.getLong("position")
                                    this@MediaSessionConnection.currentPosition = position
                                    val duration = extras.getLong("duration")
                                    this@MediaSessionConnection.duration = duration
                                    playerChangeNotifier.notifyPositionChange(position, duration)
                                }

                                "error" -> {
                                    val error = extras.getString("error")
                                    playerChangeNotifier.notifyStateChange(
                                        PlaybackStateCompat.STATE_ERROR,
                                        error
                                    )
                                }

                                "seek-end" -> {
                                    playerChangeNotifier.notifySeekEnd()
                                }

                                "next" -> {
                                    playerChangeNotifier.notifyNext()
                                }

                                "previous" -> {
                                    playerChangeNotifier.notifyPrevious()
                                }
                            }
                        }
                        super.onExtrasChanged(extras)
                    }

                    override fun onMetadataChanged(metadata: MediaMetadataCompat) {
//                        Log.i(TAG, "onMetadataChanged: $metadata duration: ${metadata.duration}")
                    }
                })
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
package br.com.suamusica.player

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.*
import android.support.v4.media.MediaBrowserCompat
import android.support.v4.media.MediaMetadataCompat
import android.support.v4.media.session.MediaControllerCompat
import android.support.v4.media.session.PlaybackStateCompat
import android.util.Log
import java.lang.ref.WeakReference

class MediaSessionConnection(
        context: Context,
        serviceComponent: ComponentName,
        val playerStateChangeNotifier: PlayerStateChangeNotifier
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
    val currentPosition: Long
        get() {
            return 0L
        }
    val duration: Long
        get() {
            return 0L
        }
    private val weakContext = WeakReference(context)
    private val weakServiceComponent = WeakReference(serviceComponent)

    private val mediaBrowserConnectionCallback = MediaBrowserConnectionCallback(context)
    private var mediaBrowser: MediaBrowserCompat? = null
    private var mediaController: MediaControllerCompat? = null

    init {
        ensureMediaBrowser {
        }
    }

    fun prepare(cookie: String, media: Media, callbackHandler: ResultReceiver) {
        val bundle = Bundle()
        bundle.putString("cookie", cookie)
        bundle.putString("name", media.name)
        bundle.putString("author", media.author)
        bundle.putString("url", media.url)
        bundle.putString("coverUrl", media.coverUrl)
        sendCommand("prepare", bundle, callbackHandler)
    }

    fun play() {
        sendCommand("play", null)
    }

    fun pause() {
        sendCommand("pause", null)
    }

    fun next() {
        sendCommand("next", null)
    }

    fun previous() {
        sendCommand("prev", null)
    }

    fun stop() {
        sendCommand("stop", null)
    }

    fun seek(position: Long) {
        val bundle = Bundle()
        bundle.putLong("position", position)
        sendCommand("seek", bundle)
    }

    fun release() {
        sendCommand("release", null)
    }

    fun sendNotification() {
        sendCommand("send_notification", null)
    }

    fun removeNotification() {
        sendCommand("remove_notification", null)
    }

    private fun sendCommand(command: String, bundle: Bundle? = null, callbackHandler: ResultReceiver? = null) {
        val receiver = callbackHandler
                ?: if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP)
                    ResultReceiver(null)
                else null

        ensureMediaBrowser {
            ensureMediaController {
                it.sendCommand(command, bundle, receiver)
            }
        }
    }

    private fun ensureMediaBrowser(callable: (mediaBrowser: MediaBrowserCompat) -> Unit) {
        try {
            if (mediaBrowser == null) {
                val context = weakContext.get()
                val serviceComponent = weakServiceComponent.get()
                mediaBrowser = MediaBrowserCompat(context, serviceComponent,
                        mediaBrowserConnectionCallback, null)
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
                Log.i("Player", "MediaBrowser is CONNECT_STATE_CONNECTING(2) or CONNECT_STATE_CONNECTED(3) or CONNECT_STATE_SUSPENDED(4)")
            else
                Log.e("Player", "Failed", e)
        }
    }

    private fun ensureMediaController(callable: (mediaController: MediaControllerCompat) -> Unit) {
        mediaController?.let(callable)
    }

    private inner class MediaBrowserConnectionCallback(private val context: Context)
        : MediaBrowserCompat.ConnectionCallback() {
        override fun onConnected() {
            Log.i(TAG, "MediaBrowserConnectionCallback.onConnected : STARTED")
            mediaBrowser?.let { mediaBrowser ->
                if (mediaBrowser.isConnected.not())
                    return

                mediaController = MediaControllerCompat(context, mediaBrowser.sessionToken)
                mediaController?.registerCallback(object : MediaControllerCompat.Callback() {
                    override fun onPlaybackStateChanged(state: PlaybackStateCompat) {
                        Log.i(TAG, "onPlaybackStateChanged: $state")
                        playerStateChangeNotifier.notify(state.state)
                    }

                    override fun onMetadataChanged(metadata: MediaMetadataCompat) {
                        Log.i(TAG, "onMetadataChanged: $metadata duration: ${metadata.duration}")
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
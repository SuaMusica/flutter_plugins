package br.com.suamusica.player

import android.content.ComponentName
import android.content.Context
import android.os.Build
import android.os.Bundle
import android.os.ResultReceiver
import android.support.v4.media.MediaBrowserCompat
import android.support.v4.media.session.MediaControllerCompat
import android.util.Log
import java.lang.ref.WeakReference

class MediaSessionConnection(
        context: Context,
        serviceComponent: ComponentName
) {
    val TAG = "Player"
    var releaseMode: Int
        get() {
            TODO()
        }
        set(value) {
            TODO()
        }
    val currentPosition: Long
        get() {
            TODO()
        }
    val duration: Long
        get() {
            TODO()
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

    fun prepare(cookie: String, name: String, author: String, url: String, coverUrl: String) {
        val bundle = Bundle()
        bundle.putString("cookie", cookie)
        bundle.putString("name", name)
        bundle.putString("author", author)
        bundle.putString("url", url)
        bundle.putString("coverUrl", coverUrl)
        sendCommand("prepare", bundle)
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

    }

    fun release() {

    }

    fun sendNotification() {
    }

    fun removeNotification() {

    }

    private fun sendCommand(command: String, bundle: Bundle? = null) {
        val receiver = if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP)
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
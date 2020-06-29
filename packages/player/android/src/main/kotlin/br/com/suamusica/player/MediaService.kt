package br.com.suamusica.player

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.ResultReceiver
import android.support.v4.media.MediaBrowserCompat
import android.util.Log

class MediaService : androidx.media.MediaBrowserServiceCompat() {
    var player: WrappedExoPlayer? = null
    private val TAG = "Player"
    private var packageValidator: PackageValidator? = null
    private val BROWSABLE_ROOT = "/"
    private val EMPTY_ROOT = "@empty@"
    private val CALLBACK_HANDLER = "player-handler"

    enum class MessageType {
        STATE_CHANGE,
        POSITION_CHANGE,
        NEXT,
        PREVIOUS
    }

    init {
        Log.i(TAG, "MediaService.init")
    }

    override fun onCreate() {
        super.onCreate()
        packageValidator = PackageValidator(this, R.xml.allowed_media_browser_callers)
        player = WrappedExoPlayer(this, Handler())
        player?.let {
            sessionToken = it.sessionToken
        }
    }

    override fun onGetRoot(clientPackageName: String, clientUid: Int, rootHints: Bundle?): BrowserRoot? {
        val isKnowCaller = packageValidator?.isKnownCaller(clientPackageName, clientUid) ?: false

        return if (isKnowCaller) {
            BrowserRoot(BROWSABLE_ROOT, null)
        } else {
            BrowserRoot(EMPTY_ROOT, null)
        }
    }

    override fun onLoadChildren(parentId: String, result: Result<MutableList<MediaBrowserCompat.MediaItem>>) {
        result.sendResult(mutableListOf())
    }
}
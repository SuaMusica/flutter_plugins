package br.com.suamusica.player

import android.R
import android.content.Context
import android.content.Intent
import android.media.MediaRouter.RouteInfo.DEVICE_TYPE_TV
import android.net.Uri
import android.util.Log
import androidx.media3.cast.SessionAvailabilityListener
import androidx.media3.common.MediaItem
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.ExoPlayer
import androidx.mediarouter.media.MediaControlIntent.CATEGORY_LIVE_AUDIO
import androidx.mediarouter.media.MediaControlIntent.CATEGORY_LIVE_VIDEO
import androidx.mediarouter.media.MediaControlIntent.CATEGORY_REMOTE_PLAYBACK
import androidx.mediarouter.media.MediaRouteSelector
import androidx.mediarouter.media.MediaRouter
import androidx.mediarouter.media.MediaRouter.UNSELECT_REASON_DISCONNECTED
import br.com.suamusica.player.PlayerPlugin.Companion.cookie
import com.google.android.gms.cast.*
import com.google.android.gms.cast.Cast
import com.google.android.gms.cast.framework.CastContext
import com.google.android.gms.cast.framework.CastState
import com.google.android.gms.cast.framework.CastStateListener
import com.google.android.gms.cast.framework.Session
import com.google.android.gms.cast.framework.SessionManager
import com.google.android.gms.cast.framework.SessionManagerListener
import com.google.android.gms.common.api.PendingResult
import com.google.android.gms.common.api.Status
import com.google.android.gms.common.images.WebImage
import java.util.WeakHashMap
import java.util.concurrent.Executors


@UnstableApi
class Cast(
    private val context: Context,
    private val player: ExoPlayer? = null,
    private val cookie: String = "",
    private val mediaItemMediaAssociations: WeakHashMap<MediaItem, Media> = WeakHashMap(),

    ) :
    SessionAvailabilityListener,
    CastStateListener,
    Cast.Listener(),
    SessionManagerListener<Session>,
    PendingResult.StatusListener {
    companion object {
        const val TAG = "Chromecast"


    }

    private var mediaRouter = MediaRouter.getInstance(context)
    private var isConnected = false
    private var castContext: CastContext? = null
    private var sessionManager: SessionManager? = null
    private var mediaRouterCallback: MediaRouter.Callback? = null

    init {
        castContext =  CastContext.getSharedInstance(context)
        castContext?.addCastStateListener(this)
        sessionManager = castContext?.sessionManager

        mediaRouterCallback = object : MediaRouter.Callback() {
            override fun onRouteAdded(router: MediaRouter, route: MediaRouter.RouteInfo) {
                super.onRouteAdded(router, route)
                Log.d(TAG, "#NATIVE LOGS ==> CAST: Route added: " + route.getName())
            }

            override fun onRouteRemoved(router: MediaRouter, route: MediaRouter.RouteInfo) {
                super.onRouteRemoved(router, route)
                Log.d(TAG, "#NATIVE LOGS ==> CAST: Route removed: " + route.getName())
            }

            override fun onRouteChanged(router: MediaRouter, route: MediaRouter.RouteInfo) {
                super.onRouteChanged(router, route)
                Log.d(TAG, "#NATIVE LOGS ==> CAST: Route changed: " + route.getName())
                player?.seekTo(3,0)
                loadMedia(player?.currentMediaItem?.associatedMedia?.name!!, "Artist", Uri.parse(player.currentMediaItem?.associatedMedia?.coverUrl!!), 0, player.currentMediaItem?.associatedMedia?.url!!, cookie)
            }

            override fun onRouteSelected(router: MediaRouter, route: MediaRouter.RouteInfo) {
                super.onRouteSelected(router, route)
                Log.d(TAG, "#NATIVE LOGS ==> CAST: Route selected: " + route.getName())
            }

            override fun onRouteUnselected(
                router: MediaRouter,
                route: MediaRouter.RouteInfo,
                reason: Int
            ) {
                super.onRouteUnselected(router, route, reason)
                Log.d(
                    TAG,
                    "#NATIVE LOGS ==> CAST: Route unselected: " + route.getName() + ", reason: " + reason
                )
            }
        }

        val selector: MediaRouteSelector.Builder = MediaRouteSelector.Builder()
            .addControlCategory(CATEGORY_LIVE_AUDIO)
            .addControlCategory(CATEGORY_LIVE_VIDEO)
            .addControlCategory(CATEGORY_REMOTE_PLAYBACK)

        mediaRouter.addCallback(
            selector.build(), mediaRouterCallback!!,
            MediaRouter.CALLBACK_FLAG_PERFORM_ACTIVE_SCAN
        )
    }

    fun discoveryCast(): List<Map<String, String>> {
        val casts = mutableListOf<Map<String, String>>()
        if (castContext?.castState != CastState.NO_DEVICES_AVAILABLE) {
            mediaRouter.routes.forEach {
                if (it.deviceType == DEVICE_TYPE_TV && it.id.isNotEmpty()) {
                    casts.add(
                        mapOf(
                            "name" to it.name,
                            "id" to it.id,
                        )
                    )
                }
            }
        }
        return casts
    }

    fun connectToCast(idCast: String) {
        val item = mediaRouter.routes.firstOrNull {
            it.id.contains(idCast)
        }
        if (!isConnected) {
            if (item != null) {
                mediaRouter.selectRoute(item)
                return
            }
        } else {
            mediaRouter.unselect(UNSELECT_REASON_DISCONNECTED)
        }
    }

    fun loadMedia(
        title: String,
        artist: String,
        image: Uri?,
        playPosition: Long,
        url: String,
        cookie: String
    ) {
        val intent = Intent(context, CastContext::class.java)

        castContext?.sessionManager?.startSession(intent)
        val musictrackMetaData = MediaMetadata(MediaMetadata.MEDIA_TYPE_MUSIC_TRACK)
        musictrackMetaData.putString(MediaMetadata.KEY_TITLE, title)
        musictrackMetaData.putString(MediaMetadata.KEY_ARTIST, artist)
        musictrackMetaData.putString(MediaMetadata.KEY_ALBUM_TITLE, "albumName")
        musictrackMetaData.putString("images", image.toString())

        image?.let {
            musictrackMetaData.addImage(WebImage(it))
        }

        val mediaInfo =
            MediaInfo.Builder(url).setContentUrl(url)
                .setStreamType(MediaInfo.STREAM_TYPE_BUFFERED)
                .setMetadata(musictrackMetaData)
                .build()

        val cookieok = cookie.replace("CloudFront-Policy=", "{\"CloudFront-Policy\": \"")
            .replace(";CloudFront-Key-Pair-Id=", "\", \"CloudFront-Key-Pair-Id\": \"")
            .replace(";CloudFront-Signature=", "\", \"CloudFront-Signature\": \"") + "\"}"

        val options = MediaLoadOptions.Builder()
            .setPlayPosition(playPosition)
            .setCredentials(
                cookieok
            )
            .build()

        val request =
            sessionManager?.currentCastSession?.remoteMediaClient?.load(mediaInfo, options)
        request?.addStatusListener(this)
    }


    //CAST STATE LISTENER
    override fun onCastStateChanged(state: Int) {
        Log.d(
            TAG,
            "#NATIVE LOGS ==> CAST: RECEIVER UPDATE AVAILABLE $state ${state != CastState.NO_DEVICES_AVAILABLE}"
        )
        isConnected = state == CastState.CONNECTED
    }

    //SessionAvailabilityListener
    override fun onCastSessionAvailable() {
        Log.d(TAG, "#NATIVE LOGS ==> CAST - SessionAvailabilityListener: onCastSessionAvailable")
    }

    override fun onCastSessionUnavailable() {
        Log.d(TAG, "#NATIVE LOGS ==> CAST - SessionAvailabilityListener: onCastSessionUnavailable")
    }

    //PendingResult.StatusListener
    override fun onComplete(status: Status) {
        Log.d(TAG, "#NATIVE LOGS ==> CAST: onComplete $status")
    }


    //SESSION MANAGER LISTENER
    override fun onSessionEnded(p0: Session, p1: Int) {
        Log.d(TAG, "#NATIVE LOGS ==> CAST: onSessionEnded")
    }

    override fun onSessionEnding(p0: Session) {
        Log.d(TAG, "#NATIVE LOGS ==> CAST: onSessionEnding")
    }

    override fun onSessionResumeFailed(p0: Session, p1: Int) {
        Log.d(TAG, "#NATIVE LOGS ==> CAST: onSessionResumeFailed")
    }

    override fun onSessionResumed(p0: Session, p1: Boolean) {
        Log.d(TAG, "#NATIVE LOGS ==> CAST: onSessionResumed")
    }

    override fun onSessionResuming(p0: Session, p1: String) {
        Log.d(TAG, "#NATIVE LOGS ==> CAST: onSessionResuming")
    }

    override fun onSessionStartFailed(p0: Session, p1: Int) {
        Log.d(TAG, "#NATIVE LOGS ==> CAST: onSessionStartFailed $p0, $p1")
    }

    override fun onSessionStarted(p0: Session, p1: String) {
        Log.d(TAG, "#NATIVE LOGS ==> CAST: onCastSessionUnavailable")
    }

    override fun onSessionStarting(p0: Session) {
        Log.d(TAG, "#NATIVE LOGS ==> CAST: $p0 onSessionStarting")
//        OnePlayerSingleton.toggleCurrentPlayer(true)
    }

    override fun onSessionSuspended(p0: Session, p1: Int) {
        Log.d(TAG, "#NATIVE LOGS ==> CAST: onSessionSuspended")
    }
    var MediaItem.associatedMedia: Media?
        get() = mediaItemMediaAssociations[this]
        set(value) {
            mediaItemMediaAssociations[this] = value
        }
}
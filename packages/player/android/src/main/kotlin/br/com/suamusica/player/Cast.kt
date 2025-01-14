package br.com.suamusica.player

import android.content.Context
import android.util.Log
import androidx.media3.cast.SessionAvailabilityListener
import androidx.media3.common.util.UnstableApi
import androidx.mediarouter.media.MediaControlIntent
import androidx.mediarouter.media.MediaControlIntent.CATEGORY_LIVE_AUDIO
import androidx.mediarouter.media.MediaControlIntent.CATEGORY_LIVE_VIDEO
import androidx.mediarouter.media.MediaControlIntent.CATEGORY_REMOTE_PLAYBACK
import androidx.mediarouter.media.MediaRouteSelector
import androidx.mediarouter.media.MediaRouter
import androidx.mediarouter.media.MediaRouter.UNSELECT_REASON_DISCONNECTED
import androidx.mediarouter.media.RemotePlaybackClient
import com.google.android.gms.cast.*
import com.google.android.gms.cast.framework.CastContext
import com.google.android.gms.cast.framework.CastState
import com.google.android.gms.cast.framework.CastStateListener
import com.google.android.gms.cast.framework.Session
import com.google.android.gms.cast.framework.SessionManager
import com.google.android.gms.cast.framework.SessionManagerListener
import com.google.android.gms.common.api.PendingResult
import com.google.android.gms.common.api.Status


@UnstableApi

class CastManager(
    castContext: CastContext,
    context: Context,
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
    var isConnected = false
    private var sessionManager: SessionManager? = null
    private var mediaRouterCallback: MediaRouter.Callback? = null
    private var onConnectCallback: (() -> Unit)? = null
    private var onSessionEndedCallback: (() -> Unit)? = null
    private var alreadyConnected = false
    private var cookie: String = ""

    init {
        castContext.addCastStateListener(this)
        sessionManager = castContext.sessionManager

        //TODO: pode remover esse callback?
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
            }

            override fun onRouteSelected(
                router: MediaRouter,
                route: MediaRouter.RouteInfo,
                reason: Int
            ) {
                Log.d(
                    TAG,
                    "#NATIVE LOGS ==> CAST: Route selected: " + route.getName() + ", reason: " + reason
                )
            }

            override fun onRouteUnselected(
                router: MediaRouter,
                route: MediaRouter.RouteInfo,
                reason: Int
            ) {
                Log.d(
                    TAG,
                    "#NATIVE LOGS ==> CAST: Route unselected: " + route.getName() + ", reason: " + reason
                )
            }
        }

        val selector: MediaRouteSelector.Builder = MediaRouteSelector.Builder()
            .addControlCategory(CATEGORY_REMOTE_PLAYBACK)
        //TODO: remover?
        mediaRouterCallback?.let {
            mediaRouter.addCallback(
                selector.build(), it,
                MediaRouter.CALLBACK_FLAG_PERFORM_ACTIVE_SCAN
            )
        }
    }

//    fun discoveryCast(): List<Map<String, String>> {
//        val casts = mutableListOf<Map<String, String>>()
//        if (castContext.castState != CastState.NO_DEVICES_AVAILABLE) {
//            mediaRouter.routes.forEach {
//                if (it.deviceType == DEVICE_TYPE_TV && it.id.isNotEmpty()) {
//                    casts.add(
//                        mapOf(
//                            "name" to it.name,
//                            "id" to it.id,
//                        )
//                    )
//                }
//            }
//        }
//        return casts
//    }

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

    fun disconnect() {
        if (isConnected) {
            sessionManager?.endCurrentSession(true)
            onSessionEndedCallback?.invoke()
            isConnected = false
        }
    }

//    private fun createQueueItem(mediaItem: MediaItem): MediaQueueItem {
//        val mediaInfo = createMediaInfo(mediaItem)
//        return MediaQueueItem.Builder(mediaInfo).build()
//    }
//
//    fun queueLoadCast(mediaItems: List<MediaItem>) {
//        val mediaQueueItems = mediaItems.map { mediaItem ->
//            createQueueItem(mediaItem)
//        }
//
//        val cookieOk = cookie.replace("CloudFront-Policy=", "{\"CloudFront-Policy\": \"")
//            .replace(";CloudFront-Key-Pair-Id=", "\", \"CloudFront-Key-Pair-Id\": \"")
//            .replace(";CloudFront-Signature=", "\", \"CloudFront-Signature\": \"") + "\"}"
//
//
//        val credentials = JSONObject().put("credentials", cookieOk)
//
//
//        val request = sessionManager?.currentCastSession?.remoteMediaClient?.queueLoad(
//            mediaQueueItems.toTypedArray(),
//            player!!.currentMediaItemIndex,
//            1,
//            player.currentPosition,
//            credentials,
//        )
//
//        request?.addStatusListener(this)
//    }

//    fun loadMediaOld() {
//        val media = player!!.currentMediaItem
//        val url = media?.associatedMedia?.coverUrl!!
//
//        val musictrackMetaData = MediaMetadata(MediaMetadata.MEDIA_TYPE_MUSIC_TRACK)
//        musictrackMetaData.putString(MediaMetadata.KEY_TITLE, media.associatedMedia?.name!!)
//        musictrackMetaData.putString(MediaMetadata.KEY_ARTIST, media.associatedMedia?.author!!)
//        musictrackMetaData.putString(MediaMetadata.KEY_ALBUM_TITLE, "albumName")
//        musictrackMetaData.putString("images", url)
//
//        media.associatedMedia?.coverUrl?.let {
//            musictrackMetaData.addImage(WebImage(Uri.parse(it)))
//        }
//
//        val mediaInfo =
//            MediaInfo.Builder(media.associatedMedia?.url!!)
//                .setContentUrl(media.associatedMedia?.url!!)
//                .setStreamType(MediaInfo.STREAM_TYPE_BUFFERED)
//                .setMetadata(musictrackMetaData)
//                .build()
//
//        val cookieOk = cookie.replace("CloudFront-Policy=", "{\"CloudFront-Policy\": \"")
//            .replace(";CloudFront-Key-Pair-Id=", "\", \"CloudFront-Key-Pair-Id\": \"")
//            .replace(";CloudFront-Signature=", "\", \"CloudFront-Signature\": \"") + "\"}"
//
//        val options = MediaLoadOptions.Builder()
////            .setPlayPosition(player.currentPosition)
//            .setCredentials(
//                cookieOk
//            )
//            .build()
//
//        val request =
//            sessionManager?.currentCastSession?.remoteMediaClient?.load(mediaInfo, options)
//        request?.addStatusListener(this)
//    }

//    val remoteMediaClient: RemoteMediaClient?
//        get() = sessionManager?.currentCastSession?.remoteMediaClient


//    private fun createMediaInfo(mediaItem: MediaItem): MediaInfo {
//        val metadata = MediaMetadata(MediaMetadata.MEDIA_TYPE_MUSIC_TRACK).apply {
//            putString(MediaMetadata.KEY_TITLE, mediaItem.associatedMedia?.name ?: "Title")
//            putString(MediaMetadata.KEY_ARTIST, mediaItem.associatedMedia?.author ?: "Artist")
//            putString(
//                MediaMetadata.KEY_ALBUM_TITLE,
//                mediaItem.associatedMedia?.albumTitle ?: "Album"
//            )
//
//            mediaItem.associatedMedia?.coverUrl?.let {
//                putString("images", it)
//            }
//            mediaItem.associatedMedia?.coverUrl?.let { coverUrl ->
//                try {
//                    addImage(WebImage(Uri.parse(coverUrl.trim())))
//                } catch (e: Exception) {
//                    Log.e(TAG, "Failed to add cover image: ${e.message}")
//                }
//            }
//        }
//
//        return MediaInfo.Builder(mediaItem.associatedMedia?.url!!)
//            .setContentUrl(mediaItem.associatedMedia?.url!!)
//            .setStreamType(MediaInfo.STREAM_TYPE_BUFFERED)
//            .setMetadata(metadata)
//            .build()
//    }

    //CAST STATE LISTENER
    override fun onCastStateChanged(state: Int) {
        Log.d(
            TAG,
            "#NATIVE LOGS ==> CAST: RECEIVER UPDATE AVAILABLE ${CastState.toString(state)}"
        )

        if (alreadyConnected && state == CastState.NOT_CONNECTED) {
            alreadyConnected = false
        }

        if (!alreadyConnected) {
            isConnected = state == CastState.CONNECTED
            if (isConnected) {
                alreadyConnected = true
                onConnectCallback?.invoke()
            }
        }
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
        onSessionEndedCallback?.invoke()
    }

    override fun onSessionStarting(p0: Session) {
        Log.d(TAG, "#NATIVE LOGS ==> CAST: $p0 onSessionStarting")
//        OnePlayerSingleton.toggleCurrentPlayer(true)
    }

    override fun onSessionSuspended(p0: Session, p1: Int) {
        Log.d(TAG, "#NATIVE LOGS ==> CAST: onSessionSuspended")
    }

//    var MediaItem.associatedMedia: Media?
//        get() = mediaItemMediaAssociations[this]
//        set(value) {
//            mediaItemMediaAssociations[this] = value
//        }

    fun setOnConnectCallback(callback: () -> Unit) {
        onConnectCallback = callback
    }

    fun setOnSessionEndedCallback(callback: () -> Unit) {
        onSessionEndedCallback = callback
    }
}
package br.com.suamusica.player

import android.annotation.SuppressLint
import android.app.Notification
import android.app.PendingIntent
import android.app.Service
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.PowerManager
import android.support.v4.media.MediaBrowserCompat
import android.support.v4.media.MediaDescriptionCompat
import android.support.v4.media.MediaMetadataCompat
import android.support.v4.media.session.MediaControllerCompat
import android.support.v4.media.session.MediaSessionCompat
import android.support.v4.media.session.PlaybackStateCompat
import android.util.Log
import androidx.core.app.NotificationManagerCompat
import androidx.media.session.MediaButtonReceiver
import br.com.suamusica.player.media.parser.SMHlsPlaylistParserFactory
import com.bumptech.glide.Glide
import com.bumptech.glide.load.engine.DiskCacheStrategy
import com.bumptech.glide.request.FutureTarget
import com.bumptech.glide.request.RequestOptions
import com.google.android.exoplayer2.C
import com.google.android.exoplayer2.ExoPlayer
import com.google.android.exoplayer2.MediaItem
import com.google.android.exoplayer2.PlaybackException
import com.google.android.exoplayer2.PlaybackParameters
import com.google.android.exoplayer2.Player
import com.google.android.exoplayer2.Player.DISCONTINUITY_REASON_SEEK
import com.google.android.exoplayer2.Timeline
import com.google.android.exoplayer2.Tracks
import com.google.android.exoplayer2.audio.AudioAttributes
import com.google.android.exoplayer2.ext.mediasession.MediaSessionConnector
import com.google.android.exoplayer2.ext.mediasession.TimelineQueueNavigator
import com.google.android.exoplayer2.source.ProgressiveMediaSource
import com.google.android.exoplayer2.source.hls.HlsMediaSource
import com.google.android.exoplayer2.upstream.DataSource
import com.google.android.exoplayer2.upstream.DefaultHttpDataSource
import com.google.android.exoplayer2.upstream.FileDataSource
import com.google.android.exoplayer2.util.Util
import kotlinx.coroutines.DelicateCoroutinesApi
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File
import java.io.BufferedReader
import java.io.InputStreamReader
import java.io.IOException
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicReference

class MediaService : androidx.media.MediaBrowserServiceCompat() {
    private val TAG = "MediaService"
    private val userAgent =
        "SuaMusica/player (Linux; Android ${Build.VERSION.SDK_INT}; ${Build.BRAND}/${Build.MODEL})"
    private var packageValidator: PackageValidator? = null

    private var mediaSession: MediaSessionCompat? = null
    private var mediaController: MediaControllerCompat? = null
    private var mediaSessionConnector: MediaSessionConnector? = null

    private var media: Media? = null

    private var notificationBuilder: NotificationBuilder? = null
    private var notificationManager: NotificationManagerCompat? = null
    private var isForegroundService = false
    private var foregroundStartDenied = false
    private val foregroundStopHandler = Handler()
    private var pendingForegroundStop: Runnable? = null
    private var wifiLock: WifiManager.WifiLock? = null
    private var wakeLock: PowerManager.WakeLock? = null

    private val uAmpAudioAttributes = AudioAttributes.Builder()
        .setContentType(C.AUDIO_CONTENT_TYPE_MUSIC)
        .setUsage(C.USAGE_MEDIA)
        .build()

    private var player: ExoPlayer? = null

    private var progressTracker: ProgressTracker? = null

    private var previousState: Int = -1

    private val BROWSABLE_ROOT = "/"
    private val EMPTY_ROOT = "@empty@"
    private val FOREGROUND_STOP_DELAY_MS = 30_000L

    private val isSamsung = Build.MANUFACTURER.equals("samsung", ignoreCase = true)
    private val isHyperOS = !getProperty("ro.mi.os.version.name").isNullOrBlank()

    companion object {
        private val glideOptions = RequestOptions()
            .fallback(R.drawable.default_art)
            .diskCacheStrategy(DiskCacheStrategy.AUTOMATIC)
            .timeout(5000)

        private const val NOTIFICATION_LARGE_ICON_SIZE = 500 // px
        private const val LOCAL_COVER_PNG = "../app_flutter/covers/0.png" // px

        // Total remote attempts before we fall back to the local/default cover
        // for the *initial* callback. We still keep retrying in background after
        // that, but the user sees a cover immediately.
        private const val REMOTE_ART_MAX_ATTEMPTS = 4

        // Cached bitmap of the bundled default_art drawable. Kept alive for the
        // process lifetime so we don't re-decode it on every media change.
        @Volatile
        private var defaultArtBitmap: Bitmap? = null

        // Tracks the most-recent art URI the player is interested in. Background
        // retries check this before firing a late callback so we never override
        // the current track's cover with stale art from a previous track.
        private val currentArtUri = AtomicReference<String?>(null)

        private fun decodeDefaultArt(context: Context): Bitmap? {
            defaultArtBitmap?.let { return it }
            // Prefer Glide so the bundled drawable is sized to the notification
            // icon target (NOTIFICATION_LARGE_ICON_SIZE) and shares the same
            // bitmap pool as the remote path. BitmapFactory is a last-resort
            // fallback to guarantee we always have *something*.
            val viaGlide = try {
                Glide.with(context)
                    .asBitmap()
                    .load(R.drawable.default_art)
                    .submit(NOTIFICATION_LARGE_ICON_SIZE, NOTIFICATION_LARGE_ICON_SIZE)
                    .get()
            } catch (e: Exception) {
                Log.w("getArts", "Glide failed to load default_art: $e")
                null
            }
            if (viaGlide != null) {
                defaultArtBitmap = viaGlide
                return viaGlide
            }
            return try {
                BitmapFactory.decodeResource(context.resources, R.drawable.default_art)
                    ?.also { defaultArtBitmap = it }
            } catch (e: Exception) {
                Log.e("getArts", "Failed to decode default_art", e)
                null
            }
        }

        private fun loadRemote(context: Context, artUri: String): Bitmap? {
            val future: FutureTarget<Bitmap> = Glide.with(context)
                .applyDefaultRequestOptions(glideOptions)
                .asBitmap()
                .load(artUri)
                .submit(NOTIFICATION_LARGE_ICON_SIZE, NOTIFICATION_LARGE_ICON_SIZE)
            return try {
                future.get()
            } catch (e: Exception) {
                Log.i("getArts", "ART load failed for $artUri: $e")
                null
            }
        }

        private fun loadLocal(context: Context): Bitmap? {
            val file = File(context.filesDir, LOCAL_COVER_PNG)
            if (!file.exists()) return null
            return try {
                Glide.with(context)
                    .applyDefaultRequestOptions(glideOptions)
                    .asBitmap()
                    .load(Uri.fromFile(file))
                    .submit(NOTIFICATION_LARGE_ICON_SIZE, NOTIFICATION_LARGE_ICON_SIZE)
                    .get()
            } catch (e: Exception) {
                Log.i("getArts", "Local ART load failed: $e")
                try {
                    BitmapFactory.decodeFile(file.absolutePath)
                } catch (t: Exception) {
                    Log.e("getArts", "Local ART decode failed: $t")
                    null
                }
            }
        }

        @OptIn(DelicateCoroutinesApi::class)
        fun getArts(context: Context, artUri: String?, callback: (Bitmap?) -> Unit) {
            currentArtUri.set(artUri)
            GlobalScope.launch(Dispatchers.IO) {
                Log.i("getArts", " artUri: $artUri")

                // 1) First attempt for the remote URI, if any.
                val remoteFirst = if (!artUri.isNullOrBlank()) loadRemote(context, artUri) else null

                // 2) If remote was not available, fall back to the local cover
                //    (single file the app writes for the currently-playing track).
                // 3) As the ultimate fallback, decode the bundled default_art so the
                //    notification ALWAYS has a cover, even on first launch / offline.
                val initialBitmap = remoteFirst
                    ?: loadLocal(context)
                    ?: decodeDefaultArt(context)

                // Guard against a quick skip: if the user already moved to
                // another track, don't stamp this older track's cover on the
                // live notification.
                if (currentArtUri.get() != artUri) {
                    Log.i("getArts", "Dropping stale cover: track changed before initial callback ($artUri)")
                    return@launch
                }

                withContext(Dispatchers.Main) {
                    callback(initialBitmap)
                }

                // 4) If the remote cover did not load on the first pass, keep
                //    retrying in the background with exponential backoff so that
                //    slow networks / flaky phones eventually show the real art.
                //    We stop if the user has moved on to another track (the
                //    currentArtUri changed) to avoid flashing stale art.
                if (remoteFirst != null || artUri.isNullOrBlank()) return@launch

                for (attempt in 2..REMOTE_ART_MAX_ATTEMPTS) {
                    // 1s, 2s, 4s, 8s ...
                    delay(1000L * (1L shl (attempt - 2)))

                    if (currentArtUri.get() != artUri) {
                        Log.i("getArts", "Aborting late retry: track changed ($artUri)")
                        return@launch
                    }

                    val late = loadRemote(context, artUri) ?: continue

                    if (currentArtUri.get() != artUri) {
                        Log.i("getArts", "Late art arrived but track already changed ($artUri)")
                        return@launch
                    }

                    Log.i("getArts", "Late art success on attempt $attempt for $artUri")
                    withContext(Dispatchers.Main) {
                        callback(late)
                    }
                    return@launch
                }
            }
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "onStartCommand")
        return Service.START_STICKY

    }

    override fun onCreate() {
        super.onCreate()
        packageValidator = PackageValidator(applicationContext, R.xml.allowed_media_browser_callers)
        notificationBuilder = NotificationBuilder(this)
        notificationManager = NotificationManagerCompat.from(this)
        wifiLock = (applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager)
            .createWifiLock(WifiManager.WIFI_MODE_FULL_HIGH_PERF, "suamusica:wifiLock")
        wakeLock = (applicationContext.getSystemService(Context.POWER_SERVICE) as PowerManager)
            .newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK or PowerManager.ON_AFTER_RELEASE,
                "suamusica:wakeLock"
            )
        wifiLock?.setReferenceCounted(false)
        wakeLock?.setReferenceCounted(false)

        val sessionActivityPendingIntent =
            this.packageManager?.getLaunchIntentForPackage(this.packageName)?.let { sessionIntent ->
                PendingIntent.getActivity(this, 0, sessionIntent, PendingIntent.FLAG_IMMUTABLE)
            }

        val mediaButtonReceiver = ComponentName(this, MediaButtonReceiver::class.java)
        mediaSession = mediaSession?.let { it }
            ?: MediaSessionCompat(this, TAG, mediaButtonReceiver, null)
                .apply {
                    setSessionActivity(sessionActivityPendingIntent)
                    isActive = true
                }

        mediaSession?.setFlags(MediaSessionCompat.FLAG_HANDLES_QUEUE_COMMANDS)

        player = ExoPlayer.Builder(this).build().apply {
            setAudioAttributes(uAmpAudioAttributes, true)
            addListener(playerEventListener())
            // setWakeMode(C.WAKE_MODE_NETWORK)
            setHandleAudioBecomingNoisy(true)
        }
        mediaSession?.let { mediaSession ->
            val sessionToken = mediaSession.sessionToken
            // we must connect the service to the media session
            this.sessionToken = sessionToken

            val mediaControllerCallback = MediaControllerCallback()

            mediaController = MediaControllerCompat(this, sessionToken).also { mediaController ->
                mediaController.registerCallback(mediaControllerCallback)

                mediaSessionConnector = MediaSessionConnector(mediaSession).also { connector ->
                    connector.setPlayer(player)
                    connector.setPlaybackPreparer(MusicPlayerPlaybackPreparer(this))
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        if (isSamsung || isHyperOS) {
                            connector.setCustomActionProviders(
                                FavoriteModeActionProvider(applicationContext),
                                NextActionProvider(),
                                PreviousActionProvider(),
                            )
                        } else {
                            connector.setCustomActionProviders(
                                FavoriteModeActionProvider(applicationContext),
                                PreviousActionProvider(),
                                NextActionProvider(),
                            )
                        }
                    }
                    connector.setMediaButtonEventHandler(MediaButtonEventHandler())
                    connector.setEnabledPlaybackActions(
                        PlaybackStateCompat.ACTION_PLAY
                                or PlaybackStateCompat.ACTION_PAUSE
                                or PlaybackStateCompat.ACTION_REWIND
                                or PlaybackStateCompat.ACTION_FAST_FORWARD
                                or PlaybackStateCompat.ACTION_SEEK_TO
                    )
                }
            }
        }
    }

    override fun onTaskRemoved(rootIntent: Intent) {
        Log.d(TAG, "onTaskRemoved")
        super.onTaskRemoved(rootIntent)

        /**
         * By stopping playback, the player will transition to [Player.STATE_IDLE]. This will
         * cause a state change in the MediaSession, and (most importantly) call
         * [MediaControllerCallback.onPlaybackStateChanged]. Because the playback state will
         * be reported as [PlaybackStateCompat.STATE_NONE], the service will first remove
         * itself as a foreground service, and will then call [stopSelf].
         */
        player?.stop()
        stopService()
    }

    override fun onDestroy() {
        removeNotification()
        Log.d(TAG, "onDestroy")
//        mediaController?.unregisterCallback(mediaControllerCallback)
        releaseLock()
        mediaSessionConnector?.setPlayer(null)
        player?.release()
        stopSelf()

        mediaSession?.run {
            isActive = false
            release()
            Log.d("MusicService", "onDestroy(isActive: $isActive)")
        }

        releasePossibleLeaks()
        super.onDestroy()

    }

    private fun releasePossibleLeaks() {
        player?.release()
        notificationManager = null
        notificationBuilder = null
        packageValidator = null
        mediaSession = null
        mediaController = null
        mediaSessionConnector = null
        wifiLock = null
        wakeLock = null

    }

    private fun acquireLock(duration: Long) {
        wifiLock?.acquire()
        wakeLock?.acquire(duration)
    }

    private fun releaseLock() {
        try {
            if (wifiLock?.isHeld == true) wifiLock?.release()
            if (wakeLock?.isHeld == true) wakeLock?.release()
        } catch (e: Exception) {
            Log.e("MusicService", e.message, e)
        }
    }

    override fun onGetRoot(
        clientPackageName: String,
        clientUid: Int,
        rootHints: Bundle?
    ): BrowserRoot? {
        val isKnowCaller = packageValidator?.isKnownCaller(clientPackageName, clientUid) ?: false

        return if (isKnowCaller) {
            BrowserRoot(BROWSABLE_ROOT, null)
        } else {
            BrowserRoot(EMPTY_ROOT, null)
        }
    }

    override fun onLoadChildren(
        parentId: String,
        result: Result<MutableList<MediaBrowserCompat.MediaItem>>
    ) {
        result.sendResult(mutableListOf())
    }

    fun prepare(cookie: String, media: Media) {
        this.media = media

        val dataSourceFactory = DefaultHttpDataSource.Factory()
        dataSourceFactory.setReadTimeoutMs(15 * 1000)
        dataSourceFactory.setConnectTimeoutMs(10 * 1000)
        dataSourceFactory.setUserAgent(userAgent)
        dataSourceFactory.setAllowCrossProtocolRedirects(true)
        dataSourceFactory.setDefaultRequestProperties(mapOf("Cookie" to cookie))

        // Metadata Build
        val metadataBuilder = MediaMetadataCompat.Builder()
        val art = null
        metadataBuilder.apply {
            album = media.author
            albumArt = art
            title = media.name
            displayTitle = media.name
            putString(MediaMetadataCompat.METADATA_KEY_ARTIST, media.author)
            putString(MediaMetadataCompat.METADATA_KEY_DISPLAY_SUBTITLE, media.name)
            putBitmap(MediaMetadataCompat.METADATA_KEY_ART, art)
            putBitmap(MediaMetadataCompat.METADATA_KEY_DISPLAY_ICON, art)
        }
        val metadata = metadataBuilder.build()
        mediaSession?.setMetadata(metadata)
        mediaSessionConnector?.setMediaMetadataProvider {
            return@setMediaMetadataProvider metadata
        }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            val timelineQueueNavigator = object : TimelineQueueNavigator(mediaSession!!) {
                override fun getSupportedQueueNavigatorActions(player: Player): Long {
                    return PlaybackStateCompat.ACTION_SKIP_TO_PREVIOUS or
                            PlaybackStateCompat.ACTION_SKIP_TO_NEXT or
                            PlaybackStateCompat.ACTION_SEEK_TO
                }

                override fun getMediaDescription(
                    player: Player,
                    windowIndex: Int
                ): MediaDescriptionCompat {
                    player.let {
                        return MediaDescriptionCompat.Builder().apply {
                            setTitle(media.author)
                            setSubtitle(media.name)
                            setIconUri(Uri.parse(media.coverUrl))
                        }.build()
                    }
                }
            }
            mediaSessionConnector?.setQueueNavigator(timelineQueueNavigator)
        }
        val url = media.url
        Log.i(TAG, "Player: URL: $url")

        val uri = if (url.startsWith("/")) Uri.fromFile(File(url)) else Uri.parse(url)

        @C.ContentType val type = Util.inferContentType(uri)
        Log.i(TAG, "Player: Type: $type HLS: ${C.TYPE_HLS}")
        val source = when (type) {
            C.TYPE_HLS -> HlsMediaSource.Factory(dataSourceFactory)
                .setPlaylistParserFactory(SMHlsPlaylistParserFactory())
                .setAllowChunklessPreparation(true)
                .createMediaSource(MediaItem.fromUri(uri))
            C.TYPE_OTHER -> {
                Log.i(TAG, "Player: URI: $uri")
                val factory: DataSource.Factory =
                    if (uri.scheme != null && uri.scheme?.startsWith("http") == true) {
                        dataSourceFactory
                    } else {
                        FileDataSource.Factory()
                    }

                ProgressiveMediaSource.Factory(factory).createMediaSource(MediaItem.fromUri(uri))
            }
            else -> {
                throw IllegalStateException("Unsupported type: $type")
            }
        }
        player?.pause()
        player?.prepare(source)
    }

    fun play() {
        buildNotification(PlaybackStateCompat.STATE_PLAYING, true, null)?.let { notification ->
            shouldStartService(notification, "play command", force = true)
        }
        performAndEnableTracking {
            player?.play()
        }
    }
    fun adsPlaying() {
        this.media = Media("Propaganda", "", "", "",null,null )
        buildNotification(PlaybackStateCompat.STATE_PLAYING, true, null)?.let { notification ->
            shouldStartService(notification)
        }
        getArts(applicationContext,null) { bitmap ->
            val notification = buildNotification(PlaybackStateCompat.STATE_PLAYING, true, bitmap)
            notification?.let {
                if (isForegroundService) {
                    notifyNowPlaying(it)
                } else {
                    shouldStartService(it)
                }
            }
        }
    }
    fun sendCommand(type: String) {
        val extra = Bundle()
        extra.putString("type", type)
        mediaSession?.setExtras(extra)

    }

    fun setFavorite(favorite: Boolean?) {
        media?.let {
            this.media = Media(it.name, it.author, it.url, it.coverUrl, it.bigCoverUrl, favorite)
            sendNotification(this.media!!, null)
        }
    }

    fun sendNotification(media: Media, isPlayingExternal: Boolean?) {
        getArts(applicationContext, media.bigCoverUrl ?: media.coverUrl) { bitmap ->
            mediaSession?.let {
                val onGoing: Boolean = if (isPlayingExternal == null) {
                    val state = player?.playbackState ?: PlaybackStateCompat.STATE_NONE
                    state == PlaybackStateCompat.STATE_PLAYING || state == PlaybackStateCompat.STATE_BUFFERING
                } else {
                    isPlayingExternal
                }
                this.media = media
                val notification = notificationBuilder?.buildNotification(
                    it,
                    media,
                    onGoing,
                    isPlayingExternal,
                    media.isFavorite,
                    player?.duration,
                    bitmap
                )
                notification?.let { n->
                    notifyNowPlaying(n)
                    rebuildNotificationAndroid15Plus()
                }
            }
        }
    }
    private fun notifyNowPlaying(notification: Notification) {
        val manager = notificationManager ?: return
        if (!manager.areNotificationsEnabled()) {
            Log.w(TAG, "Skipping now playing notification update because notifications are disabled.")
            return
        }

        try {
            manager.notify(NOW_PLAYING_NOTIFICATION, notification)
        } catch (e: SecurityException) {
            Log.w(TAG, "Skipping now playing notification update because notification permission is missing.", e)
        }
    }

    private fun rebuildNotificationAndroid15Plus(){
        //Gambiarra on Android15+ to force rebuild notification.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.VANILLA_ICE_CREAM) {
            player?.currentPosition?.let { c ->
                player?.seekTo(c)
            }
        }
    }
    fun removeNotification() {
        exitForeground(removeNotification = true)
    }

    fun seek(position: Long, playWhenReady: Boolean) {
        if (playWhenReady) {
            buildNotification(PlaybackStateCompat.STATE_PLAYING, true, null)?.let { notification ->
                shouldStartService(notification, "seek with playWhenReady", force = true)
            }
        }
        player?.seekTo(position)
        player?.playWhenReady = playWhenReady
    }

    fun pause() {
        performAndDisableTracking {
            player?.pause()
        }
    }

    fun stop() {
        performAndDisableTracking {
            player?.stop()
        }
    }

    fun togglePlayPause() {
        performAndDisableTracking {
            if (player?.isPlaying == true) {
                player?.pause()
            } else {
                buildNotification(PlaybackStateCompat.STATE_PLAYING, true, null)?.let { notification ->
                    shouldStartService(notification, "togglePlayPause command", force = true)
                }
                player?.play()
            }
        }
    }

    fun release() {
        performAndDisableTracking {
            player?.stop()
        }
    }

    private fun removeNowPlayingNotification() {
        Log.d(TAG, "removeNowPlayingNotification")
        Thread(Runnable {
            notificationManager?.cancel(NOW_PLAYING_NOTIFICATION)
        }).start()

    }


    private fun notifyPositionChange() {
        var position = player?.currentPosition ?: 0L
        val duration = player?.duration ?: 0L
        position = if (position > duration) duration else position

        if (duration > 0) {
            val extra = Bundle()
            extra.putString("type", "position")
            extra.putLong("position", position)
            extra.putLong("duration", duration)
            mediaSession?.setExtras(extra)
        }
    }

    private fun startTrackingProgress() {
        if (progressTracker != null) {
            return
        }
        this.progressTracker = ProgressTracker(Handler())
    }

    private fun stopTrackingProgress() {
        progressTracker?.stopTracking()
        progressTracker = null
    }

    private fun stopTrackingProgressAndPerformTask(callable: () -> Unit) {
        if (progressTracker != null) {
            progressTracker!!.stopTracking(callable)
        } else {
            callable()
        }
        progressTracker = null
    }

    private fun performAndEnableTracking(callable: () -> Unit) {
        callable()
        startTrackingProgress()
    }

    private fun performAndDisableTracking(callable: () -> Unit) {
        callable()
        stopTrackingProgress()
    }

    private fun buildNotification(
        updatedState: Int,
        onGoing: Boolean,
        art: Bitmap?
    ): Notification? {
        return if (updatedState != PlaybackStateCompat.STATE_NONE) {
            mediaSession?.let {
                notificationBuilder?.buildNotification(
                    it,
                    media,
                    onGoing,
                    null,
                    media?.isFavorite,
                    player?.duration,
                    art
                )
            }
        } else {
            null
        }
    }

    private fun playerEventListener(): Player.Listener {
        return object : Player.Listener {
            override fun onTimelineChanged(timeline: Timeline, reason: Int) {
                Log.i(TAG, "onTimelineChanged: timeline: $timeline reason: $reason")
            }

            override fun onTracksChanged(tracks: Tracks) {
                Log.i(TAG, "onTracksChanged: ")
            }

            override fun onLoadingChanged(isLoading: Boolean) {
                Log.i(TAG, "onLoadingChanged: isLoading: $isLoading")
            }

            override fun onPlayerStateChanged(playWhenReady: Boolean, playbackState: Int) {
                Log.i(
                    TAG,
                    "onPlayerStateChanged: playWhenReady: $playWhenReady playbackState: $playbackState currentPlaybackState: ${player?.playbackState}"
                )
                if (playWhenReady) {
                    val duration = player?.duration ?: 0L
                    acquireLock(
                        if (duration > 1L) duration + TimeUnit.MINUTES.toMillis(2) else TimeUnit.MINUTES.toMillis(
                            3
                        )
                    )
                } else
                    releaseLock()

                if (playWhenReady && playbackState == ExoPlayer.STATE_READY) {
                    //
                } else {
                    if (player?.playerError != null) {
                        //
                    } else {
                        when (playbackState) {
                            ExoPlayer.STATE_IDLE -> { // 1
                                //
                            }
                            ExoPlayer.STATE_BUFFERING -> { // 2
                                //
                            }
                            ExoPlayer.STATE_READY -> { // 3
                                val status =
                                    if (playWhenReady) PlayerState.PLAYING else PlayerState.PAUSED
                                if (previousState == -1) {
                                    // when we define that the track shall not "playWhenReady"
                                    // no position info is sent
                                    // therefore, we need to "emulate" the first position notification
                                    // by sending it directly
                                    notifyPositionChange()
                                } else {
                                    if (status == PlayerState.PAUSED) {
                                        stopTrackingProgressAndPerformTask {
                                            //
                                        }
                                    } else {
                                        //
                                    }

                                }
                            }
                            ExoPlayer.STATE_ENDED -> { // 4
                                stopTrackingProgressAndPerformTask {
                                    //
                                }
                            }
                        }
                    }
                }
                previousState = playbackState
            }

            override fun onRepeatModeChanged(repeatMode: Int) {
                Log.i(TAG, "onRepeatModeChanged: $repeatMode")
            }

            override fun onShuffleModeEnabledChanged(shuffleModeEnabled: Boolean) {
                Log.i(TAG, "onShuffleModeEnabledChanged: $shuffleModeEnabled")
            }

            override fun onPlayerError(error: PlaybackException) {
                Log.e(TAG, "onPLayerError: ${error.message}", error)
                val bundle = Bundle()
                bundle.putString("type", "error")
                bundle.putString(
                    "error",
                    if (error.cause.toString()
                            .contains("Permission denied")
                    ) "Permission denied" else error.message
                )
                mediaSession?.setExtras(bundle)
            }

            override fun onPositionDiscontinuity(reason: Int) {
                Log.i(TAG, "onPositionDiscontinuity: $reason")
                if (reason == DISCONTINUITY_REASON_SEEK) {
                    val bundle = Bundle()
                    bundle.putString("type", "seek-end")
                    mediaSession?.setExtras(bundle)
                }

            }

            override fun onPlaybackParametersChanged(playbackParameters: PlaybackParameters) {
                Log.i(TAG, "onPlaybackParametersChanged: $playbackParameters")
            }

        }
    }

    private inner class ProgressTracker(val handler: Handler) : Runnable {
        private val shutdownRequest = AtomicBoolean(false)
        private var shutdownTask: (() -> Unit)? = null

        init {
            handler.post(this)
        }

        override fun run() {
            if(previousState == PlaybackStateCompat.STATE_PLAYING) {
                notifyPositionChange()
            }

            if (!shutdownRequest.get()) {
                handler.postDelayed(this, 800 /* ms */)
            } else {
                shutdownTask?.let {
                    it()
                }
            }
        }

        fun stopTracking() {
            shutdownRequest.set(true)
        }

        fun stopTracking(callable: () -> Unit) {
            shutdownTask = callable
            stopTracking()
        }
    }

    fun shouldStartService(
        notification: Notification,
        reason: String = "notification update",
        force: Boolean = false
    ) {
        cancelPendingForegroundStop("foreground requested for $reason")
        if (!isForegroundService) {
            if (foregroundStartDenied && !force) {
                Log.i(
                    TAG,
                    "Skipping foreground promotion for $reason because the previous attempt was denied; keeping a regular notification update."
                )
                notifyNowPlaying(notification)
                return
            }

            Log.i(
                TAG,
                "Promoting MediaService to foreground for $reason; sdk=${Build.VERSION.SDK_INT}"
            )
            try {
                startForeground(NOW_PLAYING_NOTIFICATION, notification)
                isForegroundService = true
                foregroundStartDenied = false
            } catch (e: Exception) {
                if (
                    Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
                    e is android.app.ForegroundServiceStartNotAllowedException
                ) {
                    foregroundStartDenied = true
                    Log.w(
                        TAG,
                        "Foreground start was denied for $reason; keeping a regular notification update instead.",
                        e
                    )
                    notifyNowPlaying(notification)
                } else {
                    Log.e(TAG, "Failed to promote playback service to foreground.", e)
                }
            }

        }
    }

    private fun scheduleForegroundStop(reason: String) {
        if (!isForegroundService) {
            removeNowPlayingNotification()
            return
        }

        cancelPendingForegroundStop("rescheduling foreground stop")

        val stopRunnable = Runnable {
            pendingForegroundStop = null
            val state = mediaController?.playbackState?.state ?: PlaybackStateCompat.STATE_NONE
            val isPlaybackActive =
                state == PlaybackStateCompat.STATE_PLAYING || state == PlaybackStateCompat.STATE_BUFFERING

            if (isPlaybackActive) {
                Log.i(TAG, "Keeping foreground service because playback became active again; state=$state")
            } else if (isAdNotificationActive()) {
                Log.i(TAG, "Keeping foreground service because an ad is still active; rescheduling stop")
                scheduleForegroundStop("ad still active after $reason")
            } else {
                Log.i(TAG, "Stopping foreground service after delayed $reason; state=$state")
                stopService()
            }
        }

        pendingForegroundStop = stopRunnable
        Log.i(TAG, "Scheduling foreground stop in ${FOREGROUND_STOP_DELAY_MS}ms after $reason")
        foregroundStopHandler.postDelayed(stopRunnable, FOREGROUND_STOP_DELAY_MS)
    }

    private fun isAdNotificationActive(): Boolean {
        return media?.name?.contains("Propaganda") == true
    }

    private fun cancelPendingForegroundStop(reason: String) {
        pendingForegroundStop?.let {
            foregroundStopHandler.removeCallbacks(it)
            pendingForegroundStop = null
            Log.i(TAG, "Canceled pending foreground stop: $reason")
        }
    }

    fun stopService() {
        cancelPendingForegroundStop("stopService")
        if (isForegroundService) {
            stopForeground(STOP_FOREGROUND_REMOVE)
            isForegroundService = false
            foregroundStartDenied = false
            stopSelf()
            Log.i(TAG, "Stopping Service")
        }
    }

    private fun exitForeground(removeNotification: Boolean) {
        cancelPendingForegroundStop("exitForeground")
        if (isForegroundService) {
            val stopFlag = if (removeNotification) {
                STOP_FOREGROUND_REMOVE
            } else {
                STOP_FOREGROUND_DETACH
            }
            stopForeground(stopFlag)
            isForegroundService = false
            foregroundStartDenied = false
        }

        if (removeNotification) {
            removeNowPlayingNotification()
        }
    }

    private inner class MediaControllerCallback : MediaControllerCompat.Callback() {
        override fun onMetadataChanged(metadata: MediaMetadataCompat?) {
            Log.d(
                TAG,
                "onMetadataChanged: title: ${metadata?.title} duration: ${metadata?.duration}"
            )
        }

        override fun onPlaybackStateChanged(state: PlaybackStateCompat?) {
            Log.d(TAG, "onPlaybackStateChanged state: $state")
            updateNotification(state!!)
        }

        override fun onQueueChanged(queue: MutableList<MediaSessionCompat.QueueItem>?) {
            Log.d(TAG, "onQueueChanged queue: $queue")
        }

        @SuppressLint("WakelockTimeout")
        private fun updateNotification(state: PlaybackStateCompat) {
            if (mediaController?.metadata == null || mediaSession == null) {
                return
            }
            val immediateState = state.state
            val immediateOnGoing =
                immediateState == PlaybackStateCompat.STATE_PLAYING || immediateState == PlaybackStateCompat.STATE_BUFFERING

            // Promote the service immediately with a lightweight notification.
            // Artwork loading can block long enough for Android 12+ to revoke the
            // temporary foreground-start allowance.
            if (immediateOnGoing) {
                buildNotification(immediateState, immediateOnGoing, null)?.let { notification ->
                    shouldStartService(notification)
                }
            }

            getArts(applicationContext,media?.bigCoverUrl ?: media?.coverUrl) { bitmap ->
                val updatedState = mediaController?.playbackState?.state ?: state.state
                val onGoing =
                    updatedState == PlaybackStateCompat.STATE_PLAYING || updatedState == PlaybackStateCompat.STATE_BUFFERING
                // Skip building a notification when state is "none".
                val notification = if (updatedState != PlaybackStateCompat.STATE_NONE) {
                    buildNotification(updatedState, onGoing, bitmap)
                } else {
                    null
                }
                Log.d(TAG, "!!! updateNotification state: $updatedState $onGoing")

                when (updatedState) {
                    PlaybackStateCompat.STATE_BUFFERING,
                    PlaybackStateCompat.STATE_PLAYING -> {
                        Log.i(TAG, "updateNotification: STATE_BUFFERING or STATE_PLAYING")
                        if (notification != null) {
                            if (isForegroundService) {
                                notifyNowPlaying(notification)
                            } else {
                                shouldStartService(notification)
                            }
                        }
                    }
                    else -> {
                        if (updatedState == PlaybackStateCompat.STATE_NONE) {
                            if (isForegroundService) {
                                scheduleForegroundStop("STATE_NONE")
                            } else {
                                removeNowPlayingNotification()
                            }
                        } else if (notification != null) {
                            notifyNowPlaying(notification)
                        } else if (isForegroundService) {
                            removeNowPlayingNotification()
                        }
                    }
                }
            }
        }
    }

    // to get the property value from build.prop.
    private fun getProperty(property: String): String? {
        return try {
            Runtime.getRuntime().exec("getprop $property").inputStream.use { input ->
                BufferedReader(InputStreamReader(input), 1024).readLine()
            }
        } catch (e: IOException) {
            e.printStackTrace()
            null
        }
    }
}

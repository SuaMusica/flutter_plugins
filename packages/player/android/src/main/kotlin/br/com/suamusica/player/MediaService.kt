package br.com.suamusica.player

import android.app.ActivityManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.support.v4.media.session.PlaybackStateCompat
import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.common.MediaMetadata.PICTURE_TYPE_FRONT_COVER
import androidx.media3.common.PlaybackException
import androidx.media3.common.PlaybackParameters
import androidx.media3.common.Player
import androidx.media3.common.Player.DISCONTINUITY_REASON_SEEK
import androidx.media3.common.Player.MediaItemTransitionReason
import androidx.media3.common.Player.REPEAT_MODE_ALL
import androidx.media3.common.Player.REPEAT_MODE_OFF
import androidx.media3.common.Player.REPEAT_MODE_ONE
import androidx.media3.common.util.Log
import androidx.media3.common.util.UnstableApi
import androidx.media3.common.util.Util
import androidx.media3.datasource.DataSource
import androidx.media3.datasource.DataSourceBitmapLoader
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.datasource.FileDataSource
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.hls.HlsMediaSource
import androidx.media3.exoplayer.source.MediaSource
import androidx.media3.exoplayer.source.ProgressiveMediaSource
import androidx.media3.exoplayer.source.ShuffleOrder
import androidx.media3.exoplayer.source.ShuffleOrder.DefaultShuffleOrder
import androidx.media3.session.CacheBitmapLoader
import androidx.media3.session.CommandButton
import androidx.media3.session.DefaultMediaNotificationProvider
import androidx.media3.session.MediaController
import androidx.media3.session.MediaNotification
import androidx.media3.session.MediaSession
import androidx.media3.session.MediaSessionService
import br.com.suamusica.player.PlayerPlugin.Companion.IS_FAVORITE_ARGUMENT
import br.com.suamusica.player.PlayerPlugin.Companion.cookie
import br.com.suamusica.player.media.parser.SMHlsPlaylistParserFactory
import com.google.common.collect.ImmutableList
import com.google.common.util.concurrent.ListenableFuture
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.ByteArrayOutputStream
import java.io.File
import java.util.Collections
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean

const val NOW_PLAYING_CHANNEL: String = "br.com.suamusica.media.NOW_PLAYING"
const val NOW_PLAYING_NOTIFICATION: Int = 0xb339

@UnstableApi
class MediaService : MediaSessionService() {
    private val TAG = "MediaService"
    private val userAgent =
        "SuaMusica/player (Linux; Android ${Build.VERSION.SDK_INT}; ${Build.BRAND}/${Build.MODEL})"

    private var isForegroundService = false

    lateinit var mediaSession: MediaSession
    private var mediaController: ListenableFuture<MediaController>? = null

    private val uAmpAudioAttributes =
        AudioAttributes.Builder().setContentType(C.AUDIO_CONTENT_TYPE_MUSIC).setUsage(C.USAGE_MEDIA)
            .build()

    var player: ExoPlayer? = null

    private var progressTracker: ProgressTracker? = null

    private lateinit var dataSourceBitmapLoader: DataSourceBitmapLoader
    private lateinit var mediaButtonEventHandler: MediaButtonEventHandler
    private var shuffleOrder: DefaultShuffleOrder? = null

    private val artCache = HashMap<String, Bitmap>()
    private var shuffledIndices = mutableListOf<Int>()
    private var autoPlay: Boolean = true
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        super.onStartCommand(intent, flags, startId)
        return Service.START_STICKY
    }

    private fun getPendingIntent(): PendingIntent {
        val notifyIntent = Intent("SUA_MUSICA_FLUTTER_NOTIFICATION_CLICK").apply {
            addCategory(Intent.CATEGORY_DEFAULT)
            flags =
                Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }

        return PendingIntent.getActivity(
            applicationContext,
            0,
            notifyIntent,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT else PendingIntent.FLAG_UPDATE_CURRENT
        )
    }

    override fun onCreate() {
        super.onCreate()
        mediaButtonEventHandler = MediaButtonEventHandler(this)


        player = ExoPlayer.Builder(this).build().apply {
            setAudioAttributes(uAmpAudioAttributes, true)
            addListener(playerEventListener())
            setWakeMode(C.WAKE_MODE_NETWORK)
            setHandleAudioBecomingNoisy(true)
        }

        dataSourceBitmapLoader =
            DataSourceBitmapLoader(applicationContext)

        player?.let {
            mediaSession = MediaSession.Builder(this, it)
                .setBitmapLoader(CacheBitmapLoader(dataSourceBitmapLoader))
                .setCallback(mediaButtonEventHandler)
                .setSessionActivity(getPendingIntent())
                .build()
            this@MediaService.setMediaNotificationProvider(object : MediaNotification.Provider {
                override fun createNotification(
                    mediaSession: MediaSession,
                    customLayout: ImmutableList<CommandButton>,
                    actionFactory: MediaNotification.ActionFactory,
                    onNotificationChangedCallback: MediaNotification.Provider.Callback
                ): MediaNotification {
                    val defaultMediaNotificationProvider =
                        DefaultMediaNotificationProvider(applicationContext)
                            .apply {
                                setSmallIcon(R.drawable.ic_notification)
                            }

                    val customMedia3Notification =
                        defaultMediaNotificationProvider.createNotification(
                            mediaSession,
                            mediaSession.customLayout,
                            actionFactory,
                            onNotificationChangedCallback,
                        )

                    return MediaNotification(
                        NOW_PLAYING_NOTIFICATION,
                        customMedia3Notification.notification
                    )
                }

                override fun handleCustomCommand(
                    session: MediaSession,
                    action: String,
                    extras: Bundle
                ): Boolean {
                    Log.d(TAG, "#MEDIA3# - handleCustomCommand $action")
                    return false
                }
            })
        }
    }

    override fun onGetSession(
        controllerInfo: MediaSession.ControllerInfo
    ): MediaSession = mediaSession

    override fun onTaskRemoved(rootIntent: Intent?) {
        val player = mediaSession.player
        val shouldStopService = !player.playWhenReady
                || player.mediaItemCount == 0
                || player.playbackState == Player.STATE_ENDED
        if (shouldStopService) {
            stopSelf()
        }
        isServiceRunning()
    }

    override fun onDestroy() {
        mediaSession.run {
            releaseAndPerformAndDisableTracking()
            player.release()
            release()
            mediaSession.release()
        }
        releasePossibleLeaks()
        stopSelf()
        super.onDestroy()
    }

    private fun releasePossibleLeaks() {
        player?.release()
        mediaSession.release()
        mediaController = null
    }

    private fun isServiceRunning(): Boolean {
        val manager = getSystemService(ACTIVITY_SERVICE) as ActivityManager
        for (service in manager.getRunningServices(Int.MAX_VALUE)) {
            if ("br.com.suamusica.player.MediaService" == service.service.className) {
                return true
            }
        }
        return false
    }

    fun toggleShuffle(positionsList: List<Map<String, Int>>) {
        player?.shuffleModeEnabled = !(player?.shuffleModeEnabled ?: false)
        player?.shuffleModeEnabled?.let {
            if (it) {
                shuffledIndices.clear()
                for (e in positionsList) {
                    shuffledIndices.add(e["originalPosition"] ?: 0)
                }
                shuffleOrder = DefaultShuffleOrder(
                    shuffledIndices.toIntArray(),
                    System.currentTimeMillis()
                )
                player!!.setShuffleOrder(shuffleOrder!!)
            }
            PlayerSingleton.playerChangeNotifier?.onShuffleModeEnabled(it)
        }
    }

    private val channel = Channel<List<Media>>(Channel.BUFFERED)
    private val serviceScope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    // Function to add items to the channel
    private fun addToQueue(item: List<Media>) {
        serviceScope.launch {
            channel.send(item)
        }
    }

    // Function to process items (replace with your actual processing logic)
    private fun processItem(item: List<Media>) {
        createMediaSource(cookie, item, autoPlay)
    }

    private val consumer = serviceScope.launch {
        channel.receiveAsFlow().collect { item ->
            Log.i(TAG, "[TESTE QUEUE] processItem: ${item.size}")
            processItem(item)
        }
    }

    fun enqueue(
        cookie: String,
        medias: List<Media>,
        autoPlay: Boolean,
        isLastBatch: Boolean
    ) {
//        this.cookie = cookie
        this.autoPlay = autoPlay
        Log.i(TAG, "[TESTE QUEUE] enqueue: ${medias.size}")
        addToQueue(medias)
    }

    private fun createMediaSource(cookie: String, medias: List<Media>, autoPlay: Boolean) {
        var idSum = 0L
        val mediaSources: MutableList<MediaSource> = mutableListOf()
        if (medias.isNotEmpty()) {
//            val job = CoroutineScope(Dispatchers.Main).launch {
                for (i in medias.indices) {
                    Log.i(TAG, "[TESTE QUEUE]CoroutineScope: enqueue: ${medias[i].name}")
                    mediaSources.add(prepare(cookie, medias[i]))
                    idSum += medias[i].id
                }
                player?.addMediaSources(mediaSources)
//            }
//            job.invokeOnCompletion {
                player?.prepare()
                PlayerSingleton.playerChangeNotifier?.notifyItemTransition()
                Log.i(TAG, "CoroutineScope: enqueue job completation")
//            }
        }
    }

    private fun prepare(cookie: String, media: Media, coverBytes: ByteArray? = null): MediaSource {
        val dataSourceFactory = DefaultHttpDataSource.Factory()
        dataSourceFactory.setReadTimeoutMs(15 * 1000)
        dataSourceFactory.setConnectTimeoutMs(10 * 1000)
        dataSourceFactory.setUserAgent(userAgent)
        dataSourceFactory.setAllowCrossProtocolRedirects(true)
        dataSourceFactory.setDefaultRequestProperties(mapOf("Cookie" to cookie))
        val metadata = buildMetaData(media, coverBytes)
        val url = media.url
        val uri = if (url.startsWith("/")) Uri.fromFile(File(url)) else Uri.parse(url)
        val mediaItem = MediaItem.Builder().setUri(uri).setMediaMetadata(metadata)
            .setMediaId(media.id.toString()).build()
        @C.ContentType val type = Util.inferContentType(uri)

        return when (type) {
            C.CONTENT_TYPE_HLS -> {
                HlsMediaSource.Factory(dataSourceFactory)
                    .setPlaylistParserFactory(SMHlsPlaylistParserFactory())
                    .setAllowChunklessPreparation(true)
                    .createMediaSource(mediaItem)

            }

            C.CONTENT_TYPE_OTHER -> {
                val factory: DataSource.Factory =
                    if (uri.scheme != null && uri.scheme?.startsWith("http") == true) {
                        dataSourceFactory
                    } else {
                        FileDataSource.Factory()
                    }

                ProgressiveMediaSource.Factory(factory).createMediaSource(mediaItem)
            }

            else -> {
                throw IllegalStateException("Unsupported type: $type")
            }
        }
    }

    fun reorder(
        oldIndex: Int,
        newIndex: Int,
        positionsList: List<Map<String, Int>>
    ) {
        if (player?.shuffleModeEnabled == true) {
            val list = shuffledIndices.ifEmpty {
                positionsList.map { it["originalPosition"] ?: 0 }.toMutableList()
            }
            Collections.swap(list, oldIndex, newIndex)
            shuffleOrder =
                DefaultShuffleOrder(list.toIntArray(), System.currentTimeMillis())
            player?.setShuffleOrder(shuffleOrder!!)
        } else {
            player?.moveMediaItem(oldIndex, newIndex)
        }
    }

    fun removeIn(indexes: List<Int>) {
        if (indexes.isNotEmpty()) {
            indexes.forEach {
                player?.removeMediaItem(it)
                shuffleOrder?.cloneAndRemove(it, it)
                shuffledIndices.removeAt(it)
            }
        }
    }

    fun disableRepeatMode() {
        player?.repeatMode = REPEAT_MODE_OFF
    }

    fun repeatMode() {
        player?.let {
            when (it.repeatMode) {
                REPEAT_MODE_OFF -> {
                    it.repeatMode = REPEAT_MODE_ALL
                }

                REPEAT_MODE_ONE -> {
                    it.repeatMode = REPEAT_MODE_OFF
                }

                else -> {
                    it.repeatMode = REPEAT_MODE_ONE
                }
            }
        }
    }

    private fun buildMetaData(media: Media, coverBytes: ByteArray?): MediaMetadata {
        val metadataBuilder = MediaMetadata.Builder()

        val bundle = Bundle()
        bundle.putBoolean(IS_FAVORITE_ARGUMENT, media.isFavorite ?: false)
        metadataBuilder.apply {
            setAlbumTitle(media.name)
            setArtist(media.author)
//            if (coverBytes != null) {
//                setArtworkData(coverBytes, PICTURE_TYPE_FRONT_COVER)
//            }
            setArtworkUri(Uri.parse(media.bigCoverUrl))
            setArtist(media.author)
            setTitle(media.name)
            setDisplayTitle(media.name)
            setExtras(bundle)
        }
        val metadata = metadataBuilder.build()
        return metadata
    }

    private fun transformCoverInBytes(coverUrl: Uri): ByteArray {
        val stream = ByteArrayOutputStream()

        val art = artCache[coverUrl.toString()] ?: try {
            dataSourceBitmapLoader.loadBitmap(coverUrl)
                .get(5000, TimeUnit.MILLISECONDS).also {
                    artCache[coverUrl.toString()] = it
                }
        } catch (e: Exception) {
            BitmapFactory.decodeResource(resources, R.drawable.default_art)
        }

        art?.compress(Bitmap.CompressFormat.PNG, 95, stream)

        return stream.toByteArray()
    }

    fun play(shouldPrepare: Boolean = false) {
        performAndEnableTracking {
            if (shouldPrepare) {
                player?.prepare()
            }
            player?.play()
        }
    }

    fun playFromQueue(position: Int) {
        player?.seekTo(
            if (player?.shuffleModeEnabled == true) shuffledIndices[position] else position,
            0
        )
    }

    fun removeNotification() {
    }

    fun removeAll() {
        player?.stop()
        player?.clearMediaItems()
    }

    fun seek(position: Long, playWhenReady: Boolean) {
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
        if (player?.isPlaying == true) {
            pause()
        } else {
            play()
        }
    }

    private fun releaseAndPerformAndDisableTracking() {
        performAndDisableTracking {
            player?.stop()
        }
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
            mediaSession.setSessionExtras(extra)
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

    fun currentIndex(): Int {
        val position = if (player?.shuffleModeEnabled == true) {
            shuffledIndices.indexOf(
                player?.currentMediaItemIndex ?: 0
            )
        } else {
            player?.currentMediaItemIndex ?: 0
        }
        return position
    }

    private fun playerEventListener(): Player.Listener {
        return object : Player.Listener {
            override fun onPositionDiscontinuity(
                oldPosition: Player.PositionInfo,
                newPosition: Player.PositionInfo,
                reason: Int
            ) {
                if (reason == DISCONTINUITY_REASON_SEEK) {
                    val bundle = Bundle()
                    bundle.putString("type", "seek-end")
                    mediaSession.setSessionExtras(bundle)
                }
            }

            override fun onIsPlayingChanged(isPlaying: Boolean) {
                super.onIsPlayingChanged(isPlaying)
                if (isPlaying) {
                    PlayerSingleton.playerChangeNotifier?.notifyStateChange(PlaybackStateCompat.STATE_PLAYING)
                    startTrackingProgress()
                } else {
                    stopTrackingProgressAndPerformTask {}
                }
            }

            override fun onMediaItemTransition(
                mediaItem: MediaItem?,
                reason: @MediaItemTransitionReason Int
            ) {
                super.onMediaItemTransition(mediaItem, reason)
                PlayerSingleton.playerChangeNotifier?.currentMediaIndex(
                    currentIndex()
                )
                mediaButtonEventHandler.buildIcons()
                if (reason != Player.MEDIA_ITEM_TRANSITION_REASON_PLAYLIST_CHANGED) {
                    PlayerSingleton.playerChangeNotifier?.notifyItemTransition()
                }
            }

            override fun onPlaybackStateChanged(playbackState: @Player.State Int) {
                super.onPlaybackStateChanged(playbackState)
                PlayerSingleton.playerChangeNotifier?.notifyStateChange(playbackState)
                if (playbackState == Player.STATE_ENDED) {
                    stopTrackingProgressAndPerformTask {}
                }
            }

            override fun onRepeatModeChanged(repeatMode: @Player.RepeatMode Int) {
                super.onRepeatModeChanged(repeatMode)
                PlayerSingleton.playerChangeNotifier?.onRepeatChanged(repeatMode)
            }

            override fun onPlayerError(error: PlaybackException) {
                val bundle = Bundle()
                bundle.putString("type", "error")
                bundle.putString(
                    "error",
                    if (error.cause.toString()
                            .contains("Permission denied")
                    ) "Permission denied" else error.message
                )
                mediaSession.setSessionExtras(bundle)
            }

            override fun onPlaybackParametersChanged(playbackParameters: PlaybackParameters) {
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
            notifyPositionChange()

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
}

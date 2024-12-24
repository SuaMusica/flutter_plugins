package br.com.suamusica.player

import PlayerSwitcher
import android.app.ActivityManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.support.v4.media.session.PlaybackStateCompat
import androidx.media3.cast.CastPlayer
import androidx.media3.cast.DefaultMediaItemConverter
import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.common.PlaybackException
import androidx.media3.common.PlaybackParameters
import androidx.media3.common.Player
import androidx.media3.common.Player.DISCONTINUITY_REASON_SEEK
import androidx.media3.common.Player.MediaItemTransitionReason
import androidx.media3.common.Player.REPEAT_MODE_ALL
import androidx.media3.common.Player.REPEAT_MODE_OFF
import androidx.media3.common.Player.REPEAT_MODE_ONE
import androidx.media3.common.Player.STATE_ENDED
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
import androidx.media3.exoplayer.source.ShuffleOrder.DefaultShuffleOrder
import androidx.media3.session.CacheBitmapLoader
import androidx.media3.session.CommandButton
import androidx.media3.session.DefaultMediaNotificationProvider
import androidx.media3.session.MediaController
import androidx.media3.session.MediaNotification
import androidx.media3.session.MediaSession
import androidx.media3.session.MediaSessionService
import br.com.suamusica.player.PlayerPlugin.Companion.FALLBACK_URL
import br.com.suamusica.player.PlayerPlugin.Companion.IS_FAVORITE_ARGUMENT
import br.com.suamusica.player.PlayerPlugin.Companion.cookie
import br.com.suamusica.player.PlayerSingleton.playerChangeNotifier
import br.com.suamusica.player.media.parser.SMHlsPlaylistParserFactory
import com.google.android.gms.cast.framework.CastContext
import com.google.common.collect.ImmutableList
import com.google.common.util.concurrent.ListenableFuture
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.coroutines.launch
import java.io.File
import java.util.Collections
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

    var player: PlayerSwitcher? = null
    var exoPlayer: ExoPlayer? = null

    private lateinit var dataSourceBitmapLoader: DataSourceBitmapLoader
    private lateinit var mediaButtonEventHandler: MediaButtonEventHandler
    private var shuffleOrder: DefaultShuffleOrder? = null

    private var seekToLoadOnly: Boolean = false

    //    private var enqueueLoadOnly: Boolean = false
    private var autoPlay: Boolean = true

    private val channel = Channel<List<Media>>(Channel.BUFFERED)
    private val serviceScope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    //CAST
    private var cast: CastManager? = null
    private var castContext: CastContext? = null
    override fun onCreate() {
        super.onCreate()
        mediaButtonEventHandler = MediaButtonEventHandler(this)
        castContext = CastContext.getSharedInstance(this)
        exoPlayer = ExoPlayer.Builder(this).build().apply {
            setAudioAttributes(uAmpAudioAttributes, true)
//            addListener(playerEventListener())
            setWakeMode(C.WAKE_MODE_NETWORK)
            setHandleAudioBecomingNoisy(true)
            preloadConfiguration = ExoPlayer.PreloadConfiguration(
                10000000
            )
        }

        dataSourceBitmapLoader =
            DataSourceBitmapLoader(applicationContext)

        exoPlayer?.let {
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
        player = PlayerSwitcher(exoPlayer!!, mediaButtonEventHandler , applicationContext)
        castContext?.let {
            cast = CastManager(it, this, exoPlayer!!, mediaItemMediaAssociations)
        }
    }

    fun cast(castId: String?) {
        cast?.connectToCast(castId!!, cookie)
        cast?.setOnConnectCallback {
//            player?.pause()
            Log.d(CastManager.TAG, "#NATIVE LOGS ==> CAST: OnConnectCallback")
            val mediaItems = player!!.getAllMediaItems()
            cast?.queueLoadCast(mediaItems)
//            cast?.loadMediaOld()
        }
        cast?.setOnSessionEndedCallback {
//            cast?.remoteMediaClient.currentItem.
            player?.wrappedPlayer?.play()
        }
    }

    fun castWithCastPlayer(castId: String?) {
        if(cast?.isConnected == true) {
            cast?.disconnect()
            return
        }
        val items = player!!.getAllMediaItems()
        cast?.connectToCast(castId!!, cookie)
        var castPlayer : CastPlayer? = null
        cast?.setOnConnectCallback {
            val index = player?.wrappedPlayer?.currentMediaItemIndex ?: 0
            val currentPosition: Long = player?.wrappedPlayer?.currentPosition!!
            castPlayer = CastPlayer(castContext!!, DefaultMediaItemConverter())
            mediaSession.player = castPlayer!!
            player?.setCurrentPlayer(castPlayer!!)
            //o seek to foi mais rapido, testar
            player?.wrappedPlayer?.setMediaItems(items,index,currentPosition)
            player?.wrappedPlayer?.prepare()
            player?.wrappedPlayer?.play()
        }

        cast?.setOnSessionEndedCallback {
            val currentPosition = player?.wrappedPlayer?.currentPosition!!
            val index = player?.wrappedPlayer?.currentMediaItemIndex!!
            mediaSession.player = exoPlayer!!
            player?.setCurrentPlayer(exoPlayer!!)
            player?.wrappedPlayer?.prepare()
            player?.wrappedPlayer?.seekTo(index,currentPosition)
        }
    }

    fun removeNotification() {
        Log.d("Player", "removeNotification")
        player?.wrappedPlayer?.stop()
    }

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

    override fun onGetSession(
        controllerInfo: MediaSession.ControllerInfo
    ): MediaSession = mediaSession

    override fun onTaskRemoved(rootIntent: Intent?) {
        player?.wrappedPlayer?.clearMediaItems()
        Log.d(TAG, "onTaskRemoved")
        player?.wrappedPlayer?.stop()
        stopSelf()
        super.onTaskRemoved(rootIntent)
    }

    override fun onDestroy() {
        mediaSession.run {
            releaseAndPerformAndDisableTracking()
            player.release()
            release()
            mediaSession.release()
        }
        consumer.cancel()
        channel.cancel()
        releasePossibleLeaks()
        stopSelf()
        super.onDestroy()
    }

    private fun releasePossibleLeaks() {
        player?.wrappedPlayer?.release()
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

    fun updateMediaUri(index: Int, uri: String?) {
//        if (index != player?.currentMediaItemIndex) {
        val media = player?.wrappedPlayer?.getMediaItemAt(index)
        media?.associatedMedia?.let {
            player?.wrappedPlayer?.removeMediaItem(index)
            player?.addMediaSource(
                index, prepare(
                    cookie,
                    it,
                    uri ?: media.mediaMetadata.extras?.getString(FALLBACK_URL) ?: ""
                )
            )
//                player?.prepare()
        }
//        }
    }

    fun toggleShuffle(positionsList: List<Map<String, Int>>) {
        player?.wrappedPlayer?.shuffleModeEnabled = !(player?.shuffleModeEnabled ?: false)
        player?.wrappedPlayer?.shuffleModeEnabled?.let {
            if (it) {
                PlayerSingleton.shuffledIndices.clear()
                for (e in positionsList) {
                    PlayerSingleton.shuffledIndices.add(e["originalPosition"] ?: 0)
                }
                shuffleOrder = DefaultShuffleOrder(
                    PlayerSingleton.shuffledIndices.toIntArray(),
                    System.currentTimeMillis()
                )
                Log.d(
                    TAG,
                    "toggleShuffle - shuffleOrder is null: ${shuffleOrder == null} | shuffledIndices: ${PlayerSingleton.shuffledIndices.size} - ${player?.mediaItemCount}"
                )
                player!!.setShuffleOrder(shuffleOrder!!)
            }
            playerChangeNotifier?.onShuffleModeEnabled(it)
        }
    }

    private fun addToQueue(item: List<Media>) {
        serviceScope.launch {
            channel.send(item)
        }
    }

    private fun processItem(item: List<Media>) {
        createMediaSource(cookie, item)
    }

    private val consumer = serviceScope.launch {
        channel.receiveAsFlow().collect { item ->
            processItem(item)
        }
    }

    fun enqueue(
        medias: List<Media>,
        autoPlay: Boolean,
        shouldNotifyTransition: Boolean,
    ) {
        Log.d(
            TAG,
            "enqueue: mediaItemCount: ${player?.mediaItemCount} | autoPlay: $autoPlay"
        )
        this.autoPlay = autoPlay
        PlayerSingleton.shouldNotifyTransition = shouldNotifyTransition
        if (player?.wrappedPlayer?.mediaItemCount == 0) {
            player?.wrappedPlayer?.playWhenReady = autoPlay
        }
//        enqueueLoadOnly = autoPlay
        android.util.Log.d(
            "#NATIVE LOGS ==>",
            "enqueue  $autoPlay | mediaItemCount: ${player?.mediaItemCount} | shouldNotifyTransition: $shouldNotifyTransition"
        )
        addToQueue(medias)
    }

    private fun createMediaSource(cookie: String, medias: List<Media>) {
        val mediaSources: MutableList<MediaSource> = mutableListOf()
        if (medias.isNotEmpty()) {
            for (i in medias.indices) {
                mediaSources.add(prepare(cookie, medias[i], ""))
            }
            player?.addMediaSources(mediaSources)
            player?.wrappedPlayer?.prepare()
//            PlayerSingleton.playerChangeNotifier?.notifyItemTransition("createMediaSource")
//            playerChangeNotifier?.currentMediaIndex(
//                currentIndex(),
//                "createMediaSource",
//            )
        }
        if (PlayerSingleton.shouldNotifyTransition) {
            playerChangeNotifier?.notifyItemTransition("Enqueue - createMediaSource")
        }
    }

    private fun prepare(cookie: String, media: Media, urlToPrepare: String): MediaSource {
        val dataSourceFactory = DefaultHttpDataSource.Factory()
        dataSourceFactory.setReadTimeoutMs(15 * 1000)
        dataSourceFactory.setConnectTimeoutMs(10 * 1000)
        dataSourceFactory.setUserAgent(userAgent)
        dataSourceFactory.setAllowCrossProtocolRedirects(true)
        dataSourceFactory.setDefaultRequestProperties(mapOf("Cookie" to cookie))
        val metadata = buildMetaData(media)
        val uri = if (urlToPrepare.isEmpty()) {
            val url = media.url
            if (url.startsWith("/")) Uri.fromFile(File(url)) else Uri.parse(url)
        } else {
            Uri.parse(urlToPrepare)
        }
        val mediaItem = MediaItem.Builder()
            .setUri(uri)
            .setMediaMetadata(metadata)
            .setMediaId(media.id.toString())
            .setMimeType("audio/mpeg")
            .build()
        mediaItem.associatedMedia = media
        return when (@C.ContentType val type = Util.inferContentType(uri)) {
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
            val list = PlayerSingleton.shuffledIndices.ifEmpty {
                positionsList.map { it["originalPosition"] ?: 0 }.toMutableList()
            }
            Collections.swap(list, oldIndex, newIndex)
            shuffleOrder =
                DefaultShuffleOrder(list.toIntArray(), System.currentTimeMillis())
            player?.setShuffleOrder(shuffleOrder!!)
        } else {
            player?.wrappedPlayer?.moveMediaItem(oldIndex, newIndex)
        }
    }

    fun removeIn(indexes: List<Int>) {
        val sortedIndexes = indexes.sortedDescending()
        if (sortedIndexes.isNotEmpty()) {
            sortedIndexes.forEach {
                player?.removeMediaItem(it)
                if (PlayerSingleton.shuffledIndices.isNotEmpty()) {
                    PlayerSingleton.shuffledIndices.removeAt(
                        PlayerSingleton.shuffledIndices.indexOf(
                            player?.wrappedPlayer?.currentMediaItemIndex ?: 0
                        )
                    )
                }
            }
        }
        if (player?.shuffleModeEnabled == true) {
            shuffleOrder = DefaultShuffleOrder(
                PlayerSingleton.shuffledIndices.toIntArray(),
                System.currentTimeMillis()
            )
            player?.setShuffleOrder(shuffleOrder!!)
        }
    }

    fun disableRepeatMode() {
        player?.wrappedPlayer?.repeatMode = REPEAT_MODE_OFF
    }

    fun repeatMode() {
        player?.wrappedPlayer?.let {
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

    private fun buildMetaData(media: Media): MediaMetadata {
        val metadataBuilder = MediaMetadata.Builder()

        val bundle = Bundle()
        bundle.putBoolean(IS_FAVORITE_ARGUMENT, media.isFavorite ?: false)
        bundle.putString(FALLBACK_URL, media.fallbackUrl)
        metadataBuilder.apply {
            setAlbumTitle(media.name)
            setArtist(media.author)
            //TODO: verificar cover sem internet e null e empty
            setArtworkUri(Uri.parse(media.bigCoverUrl))
            setArtist(media.author)
            setTitle(media.name)
            setDisplayTitle(media.name)
            setExtras(bundle)
        }
        val metadata = metadataBuilder.build()
        return metadata
    }

    fun play(shouldPrepare: Boolean = false) {
//        PlayerSingleton.performAndEnableTracking {
            if (shouldPrepare) {
                player?.wrappedPlayer?.prepare()
            }
            player?.wrappedPlayer?.play()
//        }
    }

    fun setRepeatMode(mode: String) {
        player?.wrappedPlayer?.repeatMode = when (mode) {
            "off" -> REPEAT_MODE_OFF
            "one" -> REPEAT_MODE_ONE
            "all" -> REPEAT_MODE_ALL
            else -> REPEAT_MODE_OFF
        }
    }

    fun playFromQueue(position: Int, timePosition: Long, loadOnly: Boolean = false) {
        player?.wrappedPlayer?.playWhenReady = !loadOnly

        if (loadOnly) {
            seekToLoadOnly = true
        }

        player?.wrappedPlayer?.seekTo(
            if (player?.wrappedPlayer?.shuffleModeEnabled == true) PlayerSingleton.shuffledIndices[position] else position,
            timePosition,
        )
        if (!loadOnly) {
            player?.wrappedPlayer?.prepare()
            playerChangeNotifier?.notifyItemTransition("playFromQueue")
        }
    }

    fun removeAll() {
        player?.wrappedPlayer?.stop()
        player?.wrappedPlayer?.clearMediaItems()
    }


    fun seek(position: Long, playWhenReady: Boolean) {
        player?.wrappedPlayer?.seekTo(position)
        player?.wrappedPlayer?.playWhenReady = playWhenReady
    }

    fun pause() {
        player?.wrappedPlayer?.pause()
    }

    fun stop() {
        player?.wrappedPlayer?.stop()
    }

    fun togglePlayPause() {
        if (player?.wrappedPlayer?.isPlaying == true) {
            pause()
        } else {
            play()
        }
    }

    private fun releaseAndPerformAndDisableTracking() {
        player?.wrappedPlayer?.stop()
    }

}

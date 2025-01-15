package br.com.suamusica.player

import PlayerSwitcher
import android.app.ActivityManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.AudioManager.OnAudioFocusChangeListener
import android.net.Uri
import android.os.Build
import android.os.Bundle
import androidx.media.AudioFocusRequestCompat
import androidx.media.AudioManagerCompat
import androidx.media3.cast.CastPlayer
import androidx.media3.cast.DefaultMediaItemConverter
import androidx.media3.cast.MediaItemConverter
import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.common.Player.REPEAT_MODE_ALL
import androidx.media3.common.Player.REPEAT_MODE_OFF
import androidx.media3.common.Player.REPEAT_MODE_ONE
import androidx.media3.common.Player.STATE_IDLE
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
import br.com.suamusica.player.PlayerPlugin.Companion.FALLBACK_URL_ARGUMENT
import br.com.suamusica.player.PlayerPlugin.Companion.IS_FAVORITE_ARGUMENT
import br.com.suamusica.player.PlayerPlugin.Companion.SEEK_METHOD
import br.com.suamusica.player.PlayerPlugin.Companion.cookie
import br.com.suamusica.player.PlayerSingleton.playerChangeNotifier
import br.com.suamusica.player.media.parser.SMHlsPlaylistParserFactory
import com.google.android.gms.cast.MediaQueueItem
import com.google.android.gms.cast.framework.CastContext
import com.google.common.collect.ImmutableList
import com.google.common.util.concurrent.ListenableFuture
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.coroutines.launch
import org.json.JSONObject
import java.io.File
import java.util.Collections


const val NOW_PLAYING_CHANNEL: String = "br.com.suamusica.media.NOW_PLAYING"
const val NOW_PLAYING_NOTIFICATION: Int = 0xb339

@UnstableApi
class MediaService : MediaSessionService(){
    private val TAG = "MediaService"
    private val userAgent =
        "SuaMusica/player (Linux; Android ${Build.VERSION.SDK_INT}; ${Build.BRAND}/${Build.MODEL})"

    private var isForegroundService = false

    lateinit var mediaSession: MediaSession
    private var mediaController: ListenableFuture<MediaController>? = null

    private val uAmpAudioAttributes = AudioAttributes.Builder()
        .setContentType(C.AUDIO_CONTENT_TYPE_MUSIC)
        .setUsage(C.USAGE_MEDIA)
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

    private val smPlayer get() = player?.wrappedPlayer

    override fun onCreate() {
        super.onCreate()
        mediaButtonEventHandler = MediaButtonEventHandler(this)
        castContext = CastContext.getSharedInstance(this)

        //TODO: nao cai aqui, e o que resolveu (justAudio) foi o setContentType do uAmpAudioAttributes

        // val mAudioManager = getSystemService(AUDIO_SERVICE) as AudioManager

        // val audioFocusListener = OnAudioFocusChangeListener { focusChange ->
        //     Log.d("onAudioFocusChangeTeste", focusChange.toString())
        //     when (focusChange) {
        //         AudioManager.AUDIOFOCUS_LOSS -> {
        //             Log.d("onAudioFocusChangeTeste", "AUDIOFOCUS_LOSS")
        //             pause()
        //         }
        //         AudioManager.AUDIOFOCUS_LOSS_TRANSIENT -> {
        //             Log.d("onAudioFocusChangeTeste", "AUDIOFOCUS_LOSS_TRANSIENT")
        //             pause()
        //         }
        //         AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK -> {
        //             Log.d("onAudioFocusChangeTeste", "AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK")
        //             smPlayer?.volume = 0.2f
        //         }
        //         AudioManager.AUDIOFOCUS_GAIN -> {
        //             Log.d("onAudioFocusChangeTeste", "AUDIOFOCUS_GAIN")
        //             smPlayer?.volume = 1.0f
        //             play()
        //         }
        //     }
        // }

        // mAudioManager.requestAudioFocus(
        //     audioFocusListener,
        //     AudioManager.STREAM_MUSIC,
        //     AudioManager.AUDIOFOCUS_GAIN
        // )


        exoPlayer = ExoPlayer.Builder(this).build().apply {
            setAudioAttributes(uAmpAudioAttributes, true)
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
        player = PlayerSwitcher(exoPlayer!!, mediaButtonEventHandler)
        castContext?.let {
            cast = CastManager(it, this)
        }
    }

    fun castWithCastPlayer(castId: String?) {
        if (cast?.isConnected == true) {
            cast?.disconnect()
            return
        }
        val items = player?.getAllMediaItems()
        cast?.connectToCast(castId!!)
        var castPlayer: CastPlayer?
        cast?.setOnConnectCallback {
            val index = smPlayer?.currentMediaItemIndex ?: 0
            val currentPosition: Long = smPlayer?.currentPosition ?: 0
            castPlayer = CastPlayer(castContext!!, CustomMediaItemConverter())
            mediaSession.player = castPlayer!!
            player?.setCurrentPlayer(castPlayer!!,castContext?.sessionManager?.currentCastSession?.remoteMediaClient)
            if (items != null) {
                smPlayer?.setMediaItems(items, index, currentPosition)
                smPlayer?.prepare()
                smPlayer?.play()
            }
        }

        cast?.setOnSessionEndedCallback {
            val currentPosition = smPlayer?.currentPosition ?: 0L
            val index = smPlayer?.currentMediaItemIndex ?: 0
            exoPlayer?.let {
                mediaSession.player = it
                player?.setCurrentPlayer(it)
                smPlayer?.prepare()
                smPlayer?.seekTo(index, currentPosition)
            }
        }
    }
    //TODO: testar se vai dar o erro de startForeground no caso de audioAd
    fun removeNotification() {
        Log.d("Player", "removeNotification")
        smPlayer?.stop()
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
        smPlayer?.clearMediaItems()
        Log.d(TAG, "onTaskRemoved")
        smPlayer?.stop()
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
        smPlayer?.release()
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

    class CustomMediaItemConverter : MediaItemConverter {
        override fun toMediaQueueItem(mediaItem: MediaItem): MediaQueueItem {
            val queueItem = DefaultMediaItemConverter().toMediaQueueItem(mediaItem)
            queueItem.Writer().setCustomData(JSONObject().put("credentials", cookie))
            return queueItem
        }

        override fun toMediaItem(mediaQueueItem: MediaQueueItem): MediaItem {
            return DefaultMediaItemConverter().toMediaItem(mediaQueueItem)
        }

    }

    fun updateMediaUri(index: Int, uri: String?) {
//        if (index != player?.currentMediaItemIndex) {
        val media = smPlayer?.getMediaItemAt(index)
        media?.associatedMedia?.let {
            smPlayer?.removeMediaItem(index)
            player?.addMediaSource(
                index, prepare(
                    cookie,
                    it,
                    uri ?: media.mediaMetadata.extras?.getString(FALLBACK_URL_ARGUMENT) ?: ""
                )
            )
//                player?.prepare()
        }
//        }
    }

    fun toggleShuffle(positionsList: List<Map<String, Int>>) {
        //TODO: AJUSTAR COM CAST
        if(smPlayer is CastPlayer){
            player?.remoteMediaClient?.queueShuffle(JSONObject())
            val queue = player?.remoteMediaClient?.mediaQueue
            val items = queue?.getItemAtIndex(0)
            return
        }
        smPlayer?.shuffleModeEnabled = !(smPlayer?.shuffleModeEnabled ?: false)
        smPlayer?.shuffleModeEnabled?.let {
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
                    "toggleShuffle - shuffledIndices: ${PlayerSingleton.shuffledIndices.size} - ${player?.mediaItemCount}"
                )
                player?.setShuffleOrder(shuffleOrder!!)
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
        if (smPlayer?.mediaItemCount == 0) {
            smPlayer?.playWhenReady = autoPlay
        }
//        enqueueLoadOnly = autoPlay
        Log.d(
            TAG,
            "#NATIVE LOGS MEDIA SERVICE ==> enqueue  $autoPlay | mediaItemCount: ${player?.mediaItemCount} | shouldNotifyTransition: $shouldNotifyTransition"
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
            smPlayer?.prepare()
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
            .setMediaId(media.id.toString())
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
        //TODO: Criei issue no media3 pq esta crashando no reorder do cast
        if(smPlayer is CastPlayer){
            val mediaItems = player?.remoteMediaClient?.mediaQueue
            val mediaIds = mediaItems?.itemIds
            val reorderedIds = mediaIds?.toMutableList()
            if (reorderedIds != null) {
                val item = reorderedIds.removeAt(oldIndex)
                reorderedIds.add(newIndex, item)
            }

            player?.remoteMediaClient?.queueReorderItems(reorderedIds?.toIntArray()!!, newIndex, JSONObject())
            return
        }

        if (smPlayer?.shuffleModeEnabled == true) {
            val list = PlayerSingleton.shuffledIndices.ifEmpty {
                positionsList.map { it["originalPosition"] ?: 0 }.toMutableList()
            }
            Collections.swap(list, oldIndex, newIndex)
            shuffleOrder =
                DefaultShuffleOrder(list.toIntArray(), System.currentTimeMillis())
            player?.setShuffleOrder(shuffleOrder!!)
        } else {
            smPlayer?.moveMediaItem(oldIndex, newIndex)
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
                            smPlayer?.currentMediaItemIndex ?: 0
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
        smPlayer?.repeatMode = REPEAT_MODE_OFF
    }

    fun repeatMode() {
        smPlayer?.let {
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
        bundle.putString(FALLBACK_URL_ARGUMENT, media.fallbackUrl)
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

    fun play() {
//        PlayerSingleton.performAndEnableTracking {
        if (smPlayer?.playbackState == STATE_IDLE ) {
            smPlayer?.prepare()
        }
        smPlayer?.play()
//        }
    }

    fun setRepeatMode(mode: String) {
        smPlayer?.repeatMode = when (mode) {
            "off" -> REPEAT_MODE_OFF
            "one" -> REPEAT_MODE_ONE
            "all" -> REPEAT_MODE_ALL
            else -> REPEAT_MODE_OFF
        }
    }

    fun playFromQueue(position: Int, timePosition: Long, loadOnly: Boolean = false) {
        smPlayer?.playWhenReady = !loadOnly

        if (loadOnly) {
            seekToLoadOnly = true
        }

        smPlayer?.seekTo(
            if (smPlayer?.shuffleModeEnabled == true) PlayerSingleton.shuffledIndices[position] else position,
            timePosition,
        )
        if (!loadOnly) {
            smPlayer?.prepare()
            playerChangeNotifier?.notifyItemTransition("playFromQueue")
        }
    }

    fun removeAll() {
        smPlayer?.stop()
        smPlayer?.clearMediaItems()
    }


    fun seek(position: Long, playWhenReady: Boolean, shouldNotifyTransition:Boolean) {
        smPlayer?.seekTo(position)
        smPlayer?.playWhenReady = playWhenReady
        if(shouldNotifyTransition){
            playerChangeNotifier?.notifyItemTransition(SEEK_METHOD)
        }
    }

    fun pause() {
        smPlayer?.pause()
    }

    fun stop() {
        smPlayer?.stop()
    }

    fun togglePlayPause() {
        if (smPlayer?.isPlaying == true) {
            pause()
        } else {
            play()
        }
    }

    private fun releaseAndPerformAndDisableTracking() {
        smPlayer?.stop()
    }
}

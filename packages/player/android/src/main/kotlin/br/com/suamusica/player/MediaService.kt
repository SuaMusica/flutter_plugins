package br.com.suamusica.player

import PlayerSwitcher
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import androidx.media3.cast.CastPlayer
import androidx.media3.cast.DefaultMediaItemConverter
import androidx.media3.cast.MediaItemConverter
import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.common.Player.REPEAT_MODE_OFF
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


const val NOW_PLAYING_NOTIFICATION: Int = 0xb339

@UnstableApi
class MediaService : MediaSessionService() {
    private val TAG = "MediaService"
    private val userAgent =
        "SuaMusica/player (Linux; Android ${Build.VERSION.SDK_INT}; ${Build.BRAND}/${Build.MODEL})"
    lateinit var mediaSession: MediaSession
    private var mediaController: ListenableFuture<MediaController>? = null
    private val uAmpAudioAttributes = AudioAttributes.Builder()
        .setContentType(C.AUDIO_CONTENT_TYPE_MUSIC)
        .setUsage(C.USAGE_MEDIA)
        .build()

    private var playerSwitcher: PlayerSwitcher? = null
    private var exoPlayer: ExoPlayer? = null
    private var castPlayer: CastPlayer? = null

    private lateinit var dataSourceBitmapLoader: DataSourceBitmapLoader
    private lateinit var mediaButtonEventHandler: MediaButtonEventHandler
    private var shuffleOrder: DefaultShuffleOrder? = null
    private var autoPlay: Boolean = true
    private val channel = Channel<List<Media>>(Channel.BUFFERED)
    private val serviceScope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    //CAST
    private var cast: CastManager? = null
    private var castContext: CastContext? = null

    val smPlayer get() = exoPlayer

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
        playerSwitcher = PlayerSwitcher(exoPlayer!!, mediaButtonEventHandler)
        castContext?.let {
            cast = CastManager(it, this)
        }
    }

    fun castWithCastPlayer(castId: String?) {
        if (cast?.isConnected == true) {
            cast?.disconnect()
            return
        }
        val items = smPlayer?.getAllMediaItems()
        if (!items.isNullOrEmpty()) {
            cast?.connectToCast(castId!!)
            cast?.setOnConnectCallback {
                val index = smPlayer?.currentMediaItemIndex ?: 0
                val currentPosition: Long = smPlayer?.currentPosition ?: 0
                //TODO: verificar playback error do exoplayer ao conectar castPlayer
                castPlayer = CastPlayer(castContext!!, CustomMediaItemConverter())
                mediaSession.player = castPlayer!!
                playerSwitcher?.setCurrentPlayer(
                    castPlayer!!,
                    castContext?.sessionManager?.currentCastSession?.remoteMediaClient
                )
                smPlayer?.setMediaItem(items[index])
                smPlayer?.seekTo(currentPosition)
                smPlayer?.prepare()
                smPlayer?.play()
            }

            cast?.setOnSessionEndedCallback {
                val currentPosition = smPlayer?.currentPosition ?: 0L
                val index = smPlayer?.currentMediaItemIndex ?: 0
                exoPlayer?.let {
                    mediaSession.player = it
                    playerSwitcher?.setCurrentPlayer(it)
                    smPlayer?.prepare()
                    smPlayer?.seekTo(index, currentPosition)
                }
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
        exoPlayer?.release()
        exoPlayer = null
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
        val media = smPlayer?.getMediaItemAt(index)
        media?.associatedMedia?.let {
            smPlayer?.removeMediaItem(index)
            smPlayer?.addMediaSource(
                index, prepare(
                    cookie,
                    it,
                    uri ?: media.mediaMetadata.extras?.getString(FALLBACK_URL_ARGUMENT) ?: ""
                )
            )
        }
    }

    fun toggleShuffle(positionsList: List<Map<String, Int>>) {
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
                    "toggleShuffle - shuffledIndices: ${PlayerSingleton.shuffledIndices.size}"
                )
                if(mediaSession.player !is CastPlayer){
                    shuffleOrder?.let { shuffleOrder ->
                        smPlayer?.setShuffleOrder(shuffleOrder)
                    }
                }
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
    ) {
        this.autoPlay = autoPlay
        if (smPlayer?.mediaItemCount == 0) {
            smPlayer?.playWhenReady = autoPlay
        }
        Log.d(
            TAG,
            "#NATIVE LOGS MEDIA SERVICE ==> enqueue  $autoPlay | mediaItemCount: ${smPlayer?.mediaItemCount}"
        )
        addToQueue(medias)
    }

    private fun createMediaSource(cookie: String, medias: List<Media>) {
        val mediaSources: MutableList<MediaSource> = mutableListOf()
        if (medias.isNotEmpty()) {
            for (i in medias.indices) {
                mediaSources.add(prepare(cookie, medias[i], ""))
            }
            smPlayer?.addMediaSources(mediaSources)
            smPlayer?.prepare()
        }
    }

    fun createMediaItem(media: Media, uri: Uri? = null): MediaItem {
        val metadata = buildMetaData(media)
        return MediaItem.Builder()
            .setMediaId(media.id.toString())
            .setUri(uri ?: Uri.parse(media.url))
            .setMediaMetadata(metadata)
            .setMimeType("audio/mpeg")
            .build()
            .also { it.associatedMedia = media }
    }

    private fun prepare(cookie: String, media: Media, urlToPrepare: String): MediaSource {
        val dataSourceFactory = DefaultHttpDataSource.Factory()
        dataSourceFactory.setReadTimeoutMs(15 * 1000)
        dataSourceFactory.setConnectTimeoutMs(10 * 1000)
        dataSourceFactory.setUserAgent(userAgent)
        dataSourceFactory.setAllowCrossProtocolRedirects(true)
        dataSourceFactory.setDefaultRequestProperties(mapOf("Cookie" to cookie))

        val uri = if (urlToPrepare.isEmpty()) {
            val url = media.url
            if (url.startsWith("/")) Uri.fromFile(File(url)) else Uri.parse(url)
        } else {
            Uri.parse(urlToPrepare)
        }

        val mediaItem = createMediaItem(media, uri)

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
        if (mediaSession.player !is CastPlayer) {
            if (smPlayer?.shuffleModeEnabled == true) {
                val list = PlayerSingleton.shuffledIndices.ifEmpty {
                    positionsList.map { it["originalPosition"] ?: 0 }.toMutableList()
                }
                Collections.swap(list, oldIndex, newIndex)
                shuffleOrder =
                    DefaultShuffleOrder(list.toIntArray(), System.currentTimeMillis())
                smPlayer?.setShuffleOrder(shuffleOrder!!)
            } else {
                smPlayer?.moveMediaItem(oldIndex, newIndex)
            }
        }
    }

    fun removeIn(indexes: List<Int>) {
        val sortedIndexes = indexes.sortedDescending()
        if (sortedIndexes.isNotEmpty()) {
            sortedIndexes.forEach {
                smPlayer?.removeMediaItem(it)
                if (PlayerSingleton.shuffledIndices.isNotEmpty()) {
                    PlayerSingleton.shuffledIndices.removeAt(
                        PlayerSingleton.shuffledIndices.indexOf(
                            smPlayer?.currentMediaItemIndex ?: 0
                        )
                    )
                }
            }
        }
        if (smPlayer?.shuffleModeEnabled == true) {
            shuffleOrder = DefaultShuffleOrder(
                PlayerSingleton.shuffledIndices.toIntArray(),
                System.currentTimeMillis()
            )
            smPlayer?.setShuffleOrder(shuffleOrder!!)
        }
    }

    fun disableRepeatMode() {
        smPlayer?.repeatMode = REPEAT_MODE_OFF
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

    fun playFromQueue(position: Int, timePosition: Long, loadOnly: Boolean = false) {
        smPlayer?.playWhenReady = !loadOnly
        PlayerSingleton.shouldNotifyTransition = smPlayer?.playWhenReady ?: false
        smPlayer?.seekTo(
            if (smPlayer?.shuffleModeEnabled == true) PlayerSingleton.shuffledIndices[position] else position,
            timePosition,
        )

        if (!loadOnly) {
            smPlayer?.prepare()
        }
    }

    fun removeAll() {
        smPlayer?.stop()
        smPlayer?.clearMediaItems()
    }

    fun seek(position: Long, playWhenReady: Boolean) {
        smPlayer?.seekTo(position)
        smPlayer?.playWhenReady = playWhenReady
    }

    private fun releaseAndPerformAndDisableTracking() {
        smPlayer?.stop()
    }
}

package com.suamusica.smads

import android.content.Context
import android.media.MediaCodecList
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.view.ViewGroup
import androidx.annotation.RequiresApi
import com.google.ads.interactivemedia.v3.api.*
import com.google.android.exoplayer2.*
import com.google.android.exoplayer2.drm.DrmSessionManager
import com.google.android.exoplayer2.drm.FrameworkMediaCrypto
import com.google.android.exoplayer2.ext.ima.ImaAdsLoader
import com.google.android.exoplayer2.mediacodec.MediaCodecSelector
import com.google.android.exoplayer2.source.MediaSourceFactory
import com.google.android.exoplayer2.source.ProgressiveMediaSource
import com.google.android.exoplayer2.source.ads.AdsMediaSource
import com.google.android.exoplayer2.source.dash.DashMediaSource
import com.google.android.exoplayer2.source.hls.HlsMediaSource
import com.google.android.exoplayer2.source.smoothstreaming.SsMediaSource
import com.google.android.exoplayer2.ui.PlayerView
import com.google.android.exoplayer2.upstream.DataSource
import com.google.android.exoplayer2.upstream.DefaultDataSourceFactory
import com.google.android.exoplayer2.util.Util
import com.google.android.exoplayer2.video.VideoRendererEventListener
import com.suamusica.smads.input.LoadMethodInput
import io.reactivex.subjects.PublishSubject
import timber.log.Timber


@RequiresApi(Build.VERSION_CODES.LOLLIPOP)
class AdPlayerManager(
        context: Context,
        private val input: LoadMethodInput
) {
    private val adsLoader: ImaAdsLoader = ImaAdsLoader(context, Uri.parse(input.adTagUrl))
    private val dataSourceFactory: DataSource.Factory
    private var player: SimpleExoPlayer? = null
    private var adsManager: AdsManager? = null
    private var contentPosition: Long = 0

    val errorEventDispatcher = PublishSubject.create<AdErrorEvent>()
    val adEventDispatcher = PublishSubject.create<AdEvent>()
    var isAudioAd = false
        private set

    init {
        dataSourceFactory = DefaultDataSourceFactory(context, Util.getUserAgent(context, "AdPlayer"))
        if (true) {
            val renderersFactory =  DefaultRenderersFactory(context)

//                val renderersFactory: RenderersFactory = object : DefaultRenderersFactory(context) {
//                override fun buildVideoRenderers(context: Context, extensionRendererMode: Int, mediaCodecSelector: MediaCodecSelector, drmSessionManager: DrmSessionManager<FrameworkMediaCrypto>?, playClearSamplesWithoutKeys: Boolean, enableDecoderFallback: Boolean, eventHandler: Handler, eventListener: VideoRendererEventListener, allowedVideoJoiningTimeMs: Long, out: java.util.ArrayList<Renderer>) {
//                    out.add(
//                            SMMediaCodecVideoRenderer(
//                                    context,
//                                    mediaCodecSelector,
//                                    drmSessionManager,
//                                    playClearSamplesWithoutKeys,
//                                    enableDecoderFallback,
//                                    eventHandler,
//                                    eventListener,
//                                    allowedVideoJoiningTimeMs,
//                                    MAX_DROPPED_VIDEO_FRAME_COUNT_TO_NOTIFY))
//                }
//            }




            renderersFactory.setMediaCodecSelector(BlackListMediaCodecSelector());
            player = SimpleExoPlayer.Builder(context,renderersFactory)
                    .build();
        } else {
            player = SimpleExoPlayer.Builder(context).build()
        }
    }

    private fun getMediaSourceFactory(uri: Uri): MediaSourceFactory {
        Timber.v("getMediaSourceFactory")
        @C.ContentType
        val type = Util.inferContentType(uri)

        return when (type) {
            C.TYPE_DASH -> DashMediaSource.Factory(dataSourceFactory)
            C.TYPE_SS -> SsMediaSource.Factory(dataSourceFactory)
            C.TYPE_HLS -> HlsMediaSource.Factory(dataSourceFactory)
            C.TYPE_OTHER -> ProgressiveMediaSource.Factory(dataSourceFactory)
            else -> throw  IllegalStateException("Unsupported type: $type")
        }
    }

    fun load(playerView: PlayerView, companionAdSlotView: ViewGroup) {
        Timber.v("load")
        setupAdsLoader()
        setupCompanionAd(companionAdSlotView)
        playerView.player = player
        playerView.useController = false
        playerView.hideController()

        val contentUri = Uri.parse(input.contentUrl)
        val mediaSourceFactory = getMediaSourceFactory(contentUri)
        val contentMediaSource = mediaSourceFactory.createMediaSource(contentUri)
        val mediaSourceWithAds = AdsMediaSource(
                contentMediaSource,
                mediaSourceFactory,
                adsLoader,
                playerView
        )

        player?.prepare(mediaSourceWithAds)
    }

//    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
//    fun getCodecsType(): ArrayList<String>? {
//        val result: ArrayList<String> = ArrayList()
//        Timber.v("CODEC: %s " ,MediaCodecList(MediaCodecList.REGULAR_CODECS).codecInfos.size)
//        Timber.v("CODEC: %s %s" ,Build.DEVICE,Build.MODEL)
//
//
//        for (codec in MediaCodecList(MediaCodecList.REGULAR_CODECS).codecInfos) {
//            Timber.v("CODEC: %s, isEncoder: %s, supporttedTypes: %s" ,codec.name,codec.isEncoder,codec.supportedTypes.joinToString("//"))
//
////            if (!codec.isEncoder) {
////                for (type in codec.supportedTypes) {
////                    if (type.contains(CodecType!!)) {
////                        result.add(codec.name)
////                    }
////                }
////            }
//        }
//        return result
//    }

    fun play() {
        Timber.v("play")
        player?.playWhenReady = true
    }

    fun pause() {
        Timber.v("pause")
        player?.playWhenReady = false
    }

    fun isPaused(): Boolean = player?.playWhenReady?.not() ?: true

    fun adsDuration() = player?.duration ?: 0L

    fun adsCurrentPosition() = player?.currentPosition ?: 0L

    fun release() {
        Timber.v("release")
        player?.let { p ->
            p.release()
            player = null
        }
        adsManager?.destroy()
        adsLoader.release()
        adsLoader.setPlayer(null)
    }

    private fun setupCompanionAd(companionAdView: ViewGroup) {
        Timber.v("setupCompanionAd")
        val companionAdSlot = ImaSdkFactory.getInstance().createCompanionAdSlot()
        companionAdSlot.container = companionAdView
        companionAdSlot.setSize(300, 250)
        val companionAdSlots = ArrayList<CompanionAdSlot>()
        companionAdSlots.add(companionAdSlot)
        adsLoader.adDisplayContainer.companionSlots = companionAdSlots
    }

    private fun setupAdsLoader() {
        Timber.v("setupAdsLoader2")

        adsLoader.setPlayer(player)
        adsLoader.adsLoader.run {
            addAdErrorListener {
                Timber.d("onAdErrorEvent($it)")
                errorEventDispatcher.onNext(it)
            }
            addAdsLoadedListener { adsManagerLoadedEvent ->
                Timber.d("onAdsManagerLoaded2($adsManagerLoadedEvent)")
                adsManager = adsManagerLoadedEvent.adsManager
                Timber.d("adsManager: $adsManager")
                adsManager?.addAdErrorListener { errorEventDispatcher.onNext(it) }
                adsManager?.addAdEventListener {
                    setContentType(it)
                    adEventDispatcher.onNext(it)
                }
                val adsRenderingSettings: AdsRenderingSettings = ImaSdkFactory.getInstance().createAdsRenderingSettings()
                adsRenderingSettings.enablePreloading = true
                adsManager?.init(adsRenderingSettings)
            }
        }
    }

    private fun setContentType(adEvent: AdEvent) {
        if (adEvent.type == AdEvent.AdEventType.LOADED) {
            isAudioAd = adEvent.ad?.contentType?.contains("audio") ?: false
        }
    }
}
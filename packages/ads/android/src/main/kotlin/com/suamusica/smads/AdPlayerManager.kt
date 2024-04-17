package com.suamusica.smads

import android.content.Context
import android.media.MediaCodecList
import android.net.Uri
import android.os.Build
import android.os.Build.VERSION

import android.view.ViewGroup
import com.google.ads.interactivemedia.v3.api.*
import com.google.android.exoplayer2.C
import com.google.android.exoplayer2.ExoPlayer
import com.google.android.exoplayer2.audio.AudioAttributes
import com.google.android.exoplayer2.ext.ima.ImaAdsLoader
import com.google.android.exoplayer2.source.ProgressiveMediaSource
import com.google.android.exoplayer2.source.SilenceMediaSource
import com.google.android.exoplayer2.source.ads.AdsMediaSource
import com.google.android.exoplayer2.ui.StyledPlayerView
import com.google.android.exoplayer2.upstream.*
import com.suamusica.smads.input.LoadMethodInput
import io.reactivex.subjects.PublishSubject
import timber.log.Timber


class AdPlayerManager(
    private var context: Context,
    input: LoadMethodInput,
) {
    private var adsLoader: ImaAdsLoader? = null
    private val adTagUrl = Uri.parse(input.adTagUrl)
    private val dataSourceFactory: DataSource.Factory
    private var player: ExoPlayer? = null
    private var adsManager: AdsManager? = null
    private var supportedMimeTypes: List<String>? = null
    private val uAmpAudioAttributes = AudioAttributes.Builder()
        .setContentType(C.AUDIO_CONTENT_TYPE_MOVIE)
        .setUsage(C.USAGE_MEDIA)
        .build()

    val errorEventDispatcher = PublishSubject.create<AdErrorEvent>()
    val adEventDispatcher = PublishSubject.create<AdEvent>()
    private var _adsID = 0
    var isAudioAd = false
        private set

    init {
        val userAgent =
            "OnePlayer (Linux; Android ${VERSION.SDK_INT}; ${Build.BRAND}/${Build.MODEL})"
        dataSourceFactory = DefaultDataSource.Factory(
            context, DefaultHttpDataSource.Factory().apply {
                setReadTimeoutMs(15 * 1000)
                setConnectTimeoutMs(10 * 1000)
                setUserAgent(userAgent)
                setAllowCrossProtocolRedirects(true)
            }
        )

        player = ExoPlayer.Builder(context)
            .setAudioAttributes(uAmpAudioAttributes, true)
            .setHandleAudioBecomingNoisy(true)
            .build()

        supportedMimeTypes = this.getCodecsType()
    }

    private fun getCodecsType(): List<String> {
        val result: ArrayList<String> = ArrayList()
        for (codec in MediaCodecList(MediaCodecList.REGULAR_CODECS).codecInfos) {
            if (!codec.isEncoder) {
                for (type in codec.supportedTypes) {
                    result.add(type)
                }
            }
        }
        return result.distinct()
    }

    private fun getAdsRenderingSettings(): AdsRenderingSettings {
        val adsRenderingSettings: AdsRenderingSettings =
            ImaSdkFactory.getInstance().createAdsRenderingSettings()
        if (supportedMimeTypes != null && supportedMimeTypes!!.isNotEmpty()) {
            adsRenderingSettings.mimeTypes = supportedMimeTypes
        }
        adsRenderingSettings.enablePreloading = true
        return adsRenderingSettings
    }

    private fun setupAdsLoader() {
        Timber.d("setupAdsLoader")
        adsLoader?.setPlayer(player)
        adsLoader?.adsLoader?.addAdsLoadedListener {
            Timber.d("onAdsManagerLoaded($it)")
            adsManager = it.adsManager
            Timber.d("adsManager: $adsManager")
            adsManager?.init(getAdsRenderingSettings())
        }
    }

    fun load(playerView: StyledPlayerView, companionAdSlotView: ViewGroup, ppID: String? = null) {
        Timber.d("load")
        val companionAdSlot = ImaSdkFactory.getInstance().createCompanionAdSlot()
        companionAdSlot.container = companionAdSlotView
        companionAdSlot.setSize(300, 250)
        val companionAdSlots = ArrayList<CompanionAdSlot>()
        companionAdSlots.add(companionAdSlot)
        adsLoader = ImaAdsLoader.Builder(context).apply {
            setAdEventListener {
                setContentType(it)
                adEventDispatcher.onNext(it)
            }
            setAdErrorListener {
                errorEventDispatcher.onNext(it)
            }
            setCompanionAdSlots(companionAdSlots)
            if (ppID != null) {
                setImaSdkSettings(ImaSdkFactory.getInstance().createImaSdkSettings().apply {
                    ppid = ppID
                })
            }
        }.build()
        val dataSpec = DataSpec(adTagUrl)
        adsLoader?.requestAds(dataSpec, ++_adsID, playerView)
        playerView.player = player
        playerView.useController = false
        playerView.hideController()



        setupAdsLoader()

        player?.setMediaSource(

            AdsMediaSource(
                SilenceMediaSource(100),
                dataSpec,
                _adsID,
                ProgressiveMediaSource.Factory(dataSourceFactory),
                adsLoader!!,
                playerView
            )
        )
        player?.prepare()
    }

    fun skipAd() {
        Timber.d("Skip")
        adsLoader?.skipAd()
    }

    fun play() {
        Timber.d("play")
        player?.play()
    }

    fun pause() {
        Timber.d("pause")
        player?.pause()
    }

    fun isPaused(): Boolean = player?.playWhenReady?.not() ?: true

    fun adsDuration() = player?.duration ?: 0L

    fun adsCurrentPosition() = player?.currentPosition ?: 0L

    fun release() {
        Timber.d("release")
        player?.let { p ->
            p.release()
            player = null
        }
        adsManager?.destroy()
        adsLoader?.release()
        adsLoader?.setPlayer(null)
    }

    private fun setContentType(adEvent: AdEvent) {
        if (adEvent.type == AdEvent.AdEventType.LOADED) {
            isAudioAd = adEvent.ad?.contentType?.contains("audio") ?: false
        }
    }
}
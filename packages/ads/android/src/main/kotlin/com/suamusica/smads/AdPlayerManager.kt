package com.suamusica.smads

import android.content.Context
import android.media.MediaCodecList
import android.net.Uri
import android.os.Build
import android.view.ViewGroup
import androidx.annotation.RequiresApi
import com.google.ads.interactivemedia.v3.api.*
import com.google.android.exoplayer2.SimpleExoPlayer
import com.google.android.exoplayer2.ext.ima.ImaAdsLoader
import com.google.android.exoplayer2.source.ProgressiveMediaSource
import com.google.android.exoplayer2.source.SilenceMediaSource
import com.google.android.exoplayer2.source.ads.AdsMediaSource
import com.google.android.exoplayer2.ui.PlayerView
import com.google.android.exoplayer2.upstream.DataSource
import com.google.android.exoplayer2.upstream.DataSpec
import com.google.android.exoplayer2.upstream.DefaultDataSourceFactory
import com.google.android.exoplayer2.util.Util
import com.suamusica.smads.input.LoadMethodInput
import io.reactivex.subjects.PublishSubject
import timber.log.Timber


@RequiresApi(Build.VERSION_CODES.LOLLIPOP)
class AdPlayerManager(
        context: Context,
        input: LoadMethodInput
) {
    private val adsLoader: ImaAdsLoader =
            ImaAdsLoader.Builder(context).apply {
                setAdEventListener {
                    setContentType(it)
                    adEventDispatcher.onNext(it)
                }
                setAdErrorListener {
                    errorEventDispatcher.onNext(it)
                }
            }.build()
    private val adTagUrl = Uri.parse(input.adTagUrl)
    private val dataSourceFactory: DataSource.Factory
    private var player: SimpleExoPlayer? = null
    private var adsManager: AdsManager? = null
    private var supportedMimeTypes: List<String>? = null

    val errorEventDispatcher = PublishSubject.create<AdErrorEvent>()
    val adEventDispatcher = PublishSubject.create<AdEvent>()
    var isAudioAd = false
        private set

    init {
        dataSourceFactory = DefaultDataSourceFactory(context, Util.getUserAgent(context, "AdPlayer"))
        player = SimpleExoPlayer.Builder(context).build()
        supportedMimeTypes = this.getCodecsType()
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    fun getCodecsType(): List<String> {
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
        val adsRenderingSettings: AdsRenderingSettings = ImaSdkFactory.getInstance().createAdsRenderingSettings()
        if (supportedMimeTypes != null && supportedMimeTypes!!.isNotEmpty()) {
            adsRenderingSettings.mimeTypes = supportedMimeTypes
        }
        adsRenderingSettings.enablePreloading = true
        return adsRenderingSettings
    }

    private fun setupAdsLoader(playerView: PlayerView) {
        Timber.d("setupAdsLoader")
        adsLoader.setPlayer(player)
        adsLoader.adsLoader?.addAdsLoadedListener {
            Timber.d("onAdsManagerLoaded($it)")
            adsManager = it.adsManager
            Timber.d("adsManager: $adsManager")
            adsManager?.init(getAdsRenderingSettings())
        }
    }

    fun load(playerView: PlayerView, companionAdSlotView: ViewGroup) {
        Timber.d("load")
        adsLoader.requestAds(DataSpec(adTagUrl),playerView)
        playerView.player = player
        playerView.useController = false
        playerView.hideController()

        val companionAdSlot = ImaSdkFactory.getInstance().createCompanionAdSlot()
        companionAdSlot.container = companionAdSlotView
        companionAdSlot.setSize(300, 250)
        val companionAdSlots = ArrayList<CompanionAdSlot>()
        companionAdSlots.add(companionAdSlot)
        adsLoader.adDisplayContainer?.companionSlots = companionAdSlots

        setupAdsLoader(playerView)

        player?.setMediaSource(AdsMediaSource(
                SilenceMediaSource(100),
                // DataSpec(adTagUrl),
                ProgressiveMediaSource.Factory(dataSourceFactory),
                adsLoader,
                playerView
        ))
        player?.prepare()
    }

    fun skipAd(){
        Timber.d("Skip")
        adsLoader.skipAd()
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
        adsLoader.release()
        adsLoader.setPlayer(null)
    }

    private fun setContentType(adEvent: AdEvent) {
        if (adEvent.type == AdEvent.AdEventType.LOADED) {
            isAudioAd = adEvent.ad?.contentType?.contains("audio") ?: false
        }
    }
}
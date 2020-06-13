package com.suamusica.smads

import android.content.Context
import android.net.Uri
import android.view.ViewGroup
import com.google.ads.interactivemedia.v3.api.AdErrorEvent
import com.google.ads.interactivemedia.v3.api.AdEvent
import com.google.ads.interactivemedia.v3.api.AdsManager
import com.google.ads.interactivemedia.v3.api.CompanionAdSlot
import com.google.ads.interactivemedia.v3.api.ImaSdkFactory
import com.google.android.exoplayer2.C
import com.google.android.exoplayer2.SimpleExoPlayer
import com.google.android.exoplayer2.ext.ima.ImaAdsLoader
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
import io.reactivex.subjects.PublishSubject
import timber.log.Timber

class AdPlayerManager(
        context: Context,
        adTagUrl: String
) {

    private val adsLoader: ImaAdsLoader = ImaAdsLoader(context, Uri.parse(adTagUrl))
    private val dataSourceFactory: DataSource.Factory

    private var player: SimpleExoPlayer? = null
    private var viewAdCompanion: ViewGroup? = null
    private var adsManager: AdsManager? = null
    private var contentPosition: Long = 0

    val errorEventDispatcher = PublishSubject.create<AdErrorEvent>()
    val adEventDispatcher = PublishSubject.create<AdEvent>()
    var isAudioAd = false
        private set

    init {
        dataSourceFactory = DefaultDataSourceFactory(context, Util.getUserAgent(context, "AdPlayer"))
        player = SimpleExoPlayer.Builder(context).build()
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

    fun start(playerView: PlayerView,
              companionAdSlotView: ViewGroup?,
              contentUrl: String
    ) {
        Timber.v("start")
        setupAdsLoader()
        setupCompanionAd(companionAdSlotView)

        playerView.player = player
        playerView.useController = false
        playerView.hideController()

        val contentUri = Uri.parse(contentUrl)
        val mediaSourceFactory = getMediaSourceFactory(contentUri)
        val contentMediaSource = mediaSourceFactory.createMediaSource(contentUri)
        val mediaSourceWithAds = AdsMediaSource(
                contentMediaSource,
                mediaSourceFactory,
                adsLoader,
                playerView
        )

        player?.seekTo(contentPosition)

        player?.prepare(mediaSourceWithAds)
        player?.playWhenReady = true
    }

    fun play() {
        Timber.v("play")
        player?.playWhenReady = true
    }

    fun pause() {
        Timber.v("pause")
        player?.playWhenReady = false
    }

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
    }

    private fun setupCompanionAd(companionAdSlotView: ViewGroup?) {
        Timber.v("setupCompanionAd")
        viewAdCompanion = companionAdSlotView
        viewAdCompanion?.let { companionAdView ->
            val companionAdSlot = ImaSdkFactory.getInstance().createCompanionAdSlot()
            companionAdSlot.container = companionAdView
            companionAdSlot.setSize(300, 250)
            val companionAdSlots = ArrayList<CompanionAdSlot>()
            companionAdSlots.add(companionAdSlot)
            adsLoader.adDisplayContainer.companionSlots = companionAdSlots
        }
    }

    private fun setupAdsLoader() {
        Timber.v("setupAdsLoader")
        adsLoader.setPlayer(player)
        adsLoader.adsLoader.run {
            addAdErrorListener {
                Timber.d("onAdErrorEvent($it)")
                errorEventDispatcher.onNext(it)
            }
            addAdsLoadedListener { adsManagerLoadedEvent ->
                Timber.d("onAdsManagerLoaded($adsManagerLoadedEvent)")
                adsManager = adsManagerLoadedEvent.adsManager
                Timber.d("adsManager: $adsManager")
                adsManager?.addAdErrorListener { errorEventDispatcher.onNext(it) }
                adsManager?.addAdEventListener {
                    Timber.d("onAdEvent($it)")
                    isAudioAd = it.ad?.contentType?.contains("audio") ?: false
                    adEventDispatcher.onNext(it)
                }
                adsManager?.init()
            }
        }
    }
}
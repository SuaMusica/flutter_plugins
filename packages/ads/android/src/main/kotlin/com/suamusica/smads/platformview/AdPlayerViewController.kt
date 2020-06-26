package com.suamusica.smads.platformview

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.widget.LinearLayout
import android.widget.ProgressBar
import com.google.ads.interactivemedia.v3.api.AdErrorEvent
import com.google.ads.interactivemedia.v3.api.AdEvent
import com.google.android.exoplayer2.ui.PlayerView
import com.suamusica.smads.SmadsCallback
import com.suamusica.smads.extensions.gone
import com.suamusica.smads.extensions.hide
import com.suamusica.smads.extensions.show
import com.suamusica.smads.input.LoadMethodInput
import com.suamusica.smads.output.AdEventOutput
import io.reactivex.android.schedulers.AndroidSchedulers
import io.reactivex.disposables.CompositeDisposable
import io.reactivex.disposables.Disposable
import kotlinx.android.synthetic.main.layout_ad_player.view.companionAdSlot
import kotlinx.android.synthetic.main.layout_ad_player.view.progressBar
import kotlinx.android.synthetic.main.layout_ad_player.view.videoAdContainer
import timber.log.Timber
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.math.ceil

class AdPlayerViewController(
        private val context: Context,
        private val callback: SmadsCallback
) {
    private var adPlayerManager: AdPlayerManager? = null
    private val isCompleted = AtomicBoolean(false)
    private val compositeDisposable: CompositeDisposable = CompositeDisposable()
    private fun Disposable.compose() = compositeDisposable.add(this)
    private val handler = Handler(Looper.getMainLooper())
    var adPlayerView: AdPlayerView? = null
    private var videoAdContainer: PlayerView? = null
    private var companionAdSlot: LinearLayout? = null
    private var progressBar: ProgressBar? = null

    fun load(input: LoadMethodInput, adPlayerView: AdPlayerView) {
        Timber.v("load(input=%s)", input)
        this.adPlayerView = adPlayerView
        this.videoAdContainer = adPlayerView.videoAdContainer
        this.companionAdSlot = adPlayerView.companionAdSlot
        this.progressBar = adPlayerView.progressBar
        dispose()
        adPlayerManager = AdPlayerManager(context, input)
        configureAdPlayerEventObservers()
        adPlayerManager?.load(adPlayerView.videoAdContainer, adPlayerView.companionAdSlot)
    }

    fun play() {
        Timber.v("play()")
        adPlayerManager?.play()
    }

    fun pause() {
        Timber.v("pause()")
        adPlayerManager?.pause()
    }

    fun dispose() {
        Timber.v("dispose()")
        compositeDisposable.clear()
        adPlayerManager?.let {
            handler.post { it.release() }
        }
        isCompleted.set(false)
    }

    private fun configureAdPlayerEventObservers() {
        Timber.v("configureAdPlayerEventObservers")
        adPlayerManager?.let { adPlayerManager ->
            adPlayerManager.adEventDispatcher
                .observeOn(AndroidSchedulers.mainThread())
                .doOnNext { onAdEvent(it) }
                .doOnError { Timber.e(it) }
                .subscribe()
                .compose()

            adPlayerManager.errorEventDispatcher
                    .observeOn(AndroidSchedulers.mainThread())
                    .doOnNext { onAdError(it) }
                    .doOnError { Timber.e(it) }
                    .subscribe()
                    .compose()
        }
    }

    private fun onAdEvent(adEvent: AdEvent) {
        Timber.v("onAdEvent(adEvent: $adEvent)")
        Timber.d("adEventType %s", adEvent.type)
        when (adEvent.type) {
            AdEvent.AdEventType.COMPLETED,
            AdEvent.AdEventType.SKIPPED -> onComplete()
            AdEvent.AdEventType.LOADED -> onAdLoaded()
            AdEvent.AdEventType.STARTED -> showContent()
            AdEvent.AdEventType.PAUSED -> {
            }
            AdEvent.AdEventType.RESUMED -> {
            }
            AdEvent.AdEventType.ALL_ADS_COMPLETED -> onComplete()
            AdEvent.AdEventType.AD_PROGRESS -> {
            }
            else -> Timber.d("Unregistered: %s", adEvent.type)
        }

        val duration = adPlayerManager?.adsDuration()?.toDouble()?.let { ceil(it).toLong() } ?: 0L
        val position = adPlayerManager?.adsCurrentPosition()?.toDouble()?.let { ceil(it).toLong() } ?: 0L
        callback.onAddEvent(AdEventOutput.fromAdEvent(adEvent, duration, position))
    }

    private fun onAdError(adErrorEvent: AdErrorEvent) {
        Timber.v("onAdError($adErrorEvent)")
        Timber.d("adErrorEvent.error.errorCode(${adErrorEvent.error.errorCode})")
        Timber.d("adErrorEvent.error.errorType(${adErrorEvent.error.errorType})")
        Timber.d("adErrorEvent.error.errorCodeNumber: %s", adErrorEvent.error.errorCodeNumber)
        Timber.e(adErrorEvent.error.cause, "adErrorEvent.error.cause")
        onComplete()

        val code = adErrorEvent.error.errorCode.name
        val message = adErrorEvent.error.message ?: "unknown"
        callback.onAddEvent(AdEventOutput.error(code, message))
    }

    private fun onAdLoaded() {
        if (adPlayerManager?.isAudioAd == true) {
            companionAdSlot?.show()
            videoAdContainer?.hide()
        } else {
            companionAdSlot?.hide()
            videoAdContainer?.show()
        }
    }

    private fun showContent() {
        Timber.v("showContent")
        videoAdContainer?.show()
        progressBar?.gone()
    }

    private fun onComplete() {
        Timber.v("onComplete()")
        if (isCompleted.getAndSet(true)) return
        callback.onComplete()
    }
}
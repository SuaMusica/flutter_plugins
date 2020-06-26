package com.suamusica.smads.platformview

import android.content.Context
import android.os.Handler
import android.os.Looper
import com.google.ads.interactivemedia.v3.api.AdErrorEvent
import com.google.ads.interactivemedia.v3.api.AdEvent
import com.suamusica.smads.SmadsCallback
import com.suamusica.smads.extensions.gone
import com.suamusica.smads.extensions.hide
import com.suamusica.smads.extensions.show
import com.suamusica.smads.input.LoadMethodInput
import com.suamusica.smads.output.AdEventOutput
import io.reactivex.Single
import io.reactivex.android.schedulers.AndroidSchedulers
import io.reactivex.disposables.CompositeDisposable
import io.reactivex.disposables.Disposable
import io.reactivex.schedulers.Schedulers
import kotlinx.android.synthetic.main.layout_ad_player.view.companionAdSlot
import kotlinx.android.synthetic.main.layout_ad_player.view.progressBar
import kotlinx.android.synthetic.main.layout_ad_player.view.videoAdContainer
import timber.log.Timber
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.math.ceil

class AdPlayerViewController(
        private val context: Context,
        private val callback: SmadsCallback,
        adPlayerView: AdPlayerView
) {
    lateinit var adPlayerManager: AdPlayerManager
    private var timeoutShouldFinishAd = AtomicBoolean(true)
    private val isCompleted = AtomicBoolean(false)
    private val compositeDisposable: CompositeDisposable = CompositeDisposable()
    private fun Disposable.compose() = compositeDisposable.add(this)
    private val handler = Handler(Looper.getMainLooper())
    private val videoAdContainer = adPlayerView.videoAdContainer
    private val companionAdSlot = adPlayerView.companionAdSlot
    private val progressBar = adPlayerView.progressBar

    fun load(input: LoadMethodInput, adSize: AdSize) {
        Timber.v("load(input=%s, adSize=%s)", input, adSize)
        adPlayerManager = AdPlayerManager(context, input)
        configureAdPlayerEventObservers()
        adPlayerManager.load(videoAdContainer, companionAdSlot)
    }

    fun play() {
        Timber.v("play()")
        adPlayerManager.play()
    }

    fun pause() {
        Timber.v("pause()")
        adPlayerManager.pause()
    }

    fun dispose() {
        Timber.v("dispose()")
        handler.post { adPlayerManager.release() }
        compositeDisposable.clear()
    }

    private fun configureAdPlayerTimeoutJob() {
        Timber.v("configureAdPlayerTimeoutJob")
        Single.timer(5, TimeUnit.SECONDS)
                .observeOn(Schedulers.io())
                .filter { timeoutShouldFinishAd.get() }
                .subscribe({
                    Timber.d("Time reached")
                    onComplete()
                }, { e -> Timber.e(e) })
                .compose()
    }

    private fun configureAdPlayerEventObservers() {
        Timber.v("configureAdPlayerEventObservers")
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

    private fun onAdEvent(adEvent: AdEvent) {
        Timber.v("onAdEvent(adEvent: $adEvent)")
        Timber.d("adEventType %s", adEvent.type)
        when (adEvent.type) {
            AdEvent.AdEventType.COMPLETED,
            AdEvent.AdEventType.SKIPPED -> onComplete()
            AdEvent.AdEventType.LOADED -> {
                timeoutShouldFinishAd.set(false)
                onAdLoaded()
            }
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

        val duration = ceil(adPlayerManager.adsDuration().toDouble()).toLong()
        val position = ceil(adPlayerManager.adsCurrentPosition().toDouble()).toLong()
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
        if (adPlayerManager.isAudioAd) {
            companionAdSlot.show()
            videoAdContainer.hide()
        } else {
            companionAdSlot.hide()
            videoAdContainer.show()
        }
    }

    private fun showContent() {
        Timber.v("showContent")
        videoAdContainer.show()
        progressBar.gone()
    }

    private fun onComplete() {
        Timber.v("releaseVideoAd")
        if (isCompleted.getAndSet(true)) return
        callback.onComplete()
    }
}
package com.suamusica.smads

import android.content.Context
import android.view.View
import android.widget.LinearLayout
import android.widget.ProgressBar
import com.google.ads.interactivemedia.v3.api.AdErrorEvent
import com.google.ads.interactivemedia.v3.api.AdEvent
import com.google.android.exoplayer2.ui.StyledPlayerView
import com.suamusica.smads.extensions.gone
import com.suamusica.smads.extensions.hide
import com.suamusica.smads.extensions.show
import com.suamusica.smads.input.LoadMethodInput
import com.suamusica.smads.output.AdEventOutput
import com.suamusica.smads.platformview.AdPlayerView
import io.reactivex.android.schedulers.AndroidSchedulers
import io.reactivex.disposables.CompositeDisposable
import io.reactivex.disposables.Disposable
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
    var adPlayerView: AdPlayerView? = null
    private var view: View? = null
    private var videoAdContainer: StyledPlayerView? = null
    private var companionAdSlot: LinearLayout? = null
    private var progressBar: ProgressBar? = null
    private val ignorePausedEvent = AtomicBoolean(true)

    fun load(input: LoadMethodInput, adPlayerView: AdPlayerView) {
        Timber.d("load(input=%s)", input)
        dispose()
        this.adPlayerView = adPlayerView
        this.view = adPlayerView.binding.view
        this.videoAdContainer = adPlayerView.binding.videoAdContainer
        this.companionAdSlot = adPlayerView.binding.companionAdSlot
        this.progressBar = adPlayerView.binding.progressBar
        ignorePausedEvent.set(true)
        adPlayerManager = AdPlayerManager(context, input)
        configureAdPlayerEventObservers()
        adPlayerManager?.load(adPlayerView.binding.videoAdContainer, adPlayerView.binding.companionAdSlot)
    }

    fun play() {
        Timber.d("play()")
        ignorePausedEvent.set(false)
        adPlayerManager?.play()
    }

    fun skipAd(){
        Timber.d("skipAd()")
        adPlayerManager?.skipAd()

    }

    fun pause() {
        Timber.d("pause()")
        adPlayerManager?.pause()
    }

    fun dispose() {
        Timber.d("dispose()")
        compositeDisposable.clear()
        adPlayerManager?.release()
        isCompleted.set(false)
    }

    private fun configureAdPlayerEventObservers() {
        Timber.d("configureAdPlayerEventObservers")
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
        when (adEvent.type) {
            AdEvent.AdEventType.COMPLETED,
            AdEvent.AdEventType.SKIPPED -> onComplete()
            AdEvent.AdEventType.LOADED -> onAdLoaded()
            AdEvent.AdEventType.STARTED -> showContent()
            AdEvent.AdEventType.SKIPPABLE_STATE_CHANGED ->{

            }
            AdEvent.AdEventType.CONTENT_PAUSE_REQUESTED,
            AdEvent.AdEventType.PAUSED -> {
                if (ignorePausedEvent.get()) {
                    logIgnoredEvent(adEvent)
                    return
                }
            }
            AdEvent.AdEventType.RESUMED -> {
            }
            AdEvent.AdEventType.ALL_ADS_COMPLETED -> onComplete()
            AdEvent.AdEventType.AD_PROGRESS -> {
                if (adPlayerManager?.isPaused() != false) {
                    return
                }
            }
            else -> Timber.d("Unregistered: %s", adEvent.type)
        }

        Timber.d("onAdEvent(%s)", adEvent.type)
        if(adEvent.type == AdEvent.AdEventType.LOADED){
            Timber.d("onAdEvent(%s)", adEvent)
        }
        val duration = adPlayerManager?.adsDuration()?.toDouble()?.let { ceil(it).toLong() } ?: 0L
        val position = adPlayerManager?.adsCurrentPosition()?.toDouble()?.let { ceil(it).toLong() } ?: 0L
        Timber.d("onAdEvent(duration=%s, position=%s)", duration, position)
        callback.onAddEvent(AdEventOutput.fromAdEvent(adEvent, duration, position))
    }

    private fun logIgnoredEvent(adEvent: AdEvent) {
        Timber.d("Event(%s) ignored", adEvent.type)
    }

    private fun onAdError(adErrorEvent: AdErrorEvent) {
        Timber.d("onAdError($adErrorEvent)")
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
        progressBar?.gone()
    }
    private fun canSkip() {
        progressBar?.gone()
    }

    private fun showContent() {
        Timber.d("showContent")
        if (adPlayerManager?.isAudioAd == true) {
            Timber.d("adPlayerManager?.isAudioAd: true")
            this.view?.hide()
            videoAdContainer?.hide()
            companionAdSlot?.show()
        } else {
            Timber.d("adPlayerManager?.isAudioAd: false")
            view?.show()
            videoAdContainer?.show()
            companionAdSlot?.hide()
        }
    }

    private fun onComplete() {
        Timber.d("onComplete()")
        if (isCompleted.getAndSet(true)) return
        callback.onComplete()
    }
}
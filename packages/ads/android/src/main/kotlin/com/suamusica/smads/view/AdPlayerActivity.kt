package com.suamusica.smads.view

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import com.google.ads.interactivemedia.v3.api.AdErrorEvent
import com.google.ads.interactivemedia.v3.api.AdEvent
import com.jakewharton.rxbinding3.view.clicks
import com.suamusica.smads.MethodChannelBridge
import com.suamusica.smads.R
import com.suamusica.smads.extensions.hide
import com.suamusica.smads.extensions.show
import com.suamusica.smads.media.domain.MediaProgress
import com.suamusica.smads.output.AdEventOutput
import com.suamusica.smads.player.PlayerAction
import io.reactivex.Single
import io.reactivex.android.schedulers.AndroidSchedulers
import io.reactivex.disposables.CompositeDisposable
import io.reactivex.disposables.Disposable
import io.reactivex.schedulers.Schedulers
import kotlinx.android.synthetic.main.activity_ima_player.buttonHelp
import kotlinx.android.synthetic.main.activity_ima_player.buttonPlayPause
import kotlinx.android.synthetic.main.activity_ima_player.companionAdSlot
import kotlinx.android.synthetic.main.activity_ima_player.musicProgressView
import kotlinx.android.synthetic.main.activity_ima_player.progressBar
import kotlinx.android.synthetic.main.activity_ima_player.videoAdContainer
import timber.log.Timber
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.math.ceil

class AdPlayerActivity : AppCompatActivity() {

    private lateinit var adPlayerManager: AdPlayerManager
    private val compositeDisposable: CompositeDisposable = CompositeDisposable()
    private fun Disposable.compose() = compositeDisposable.add(this)
    private var timeoutShouldFinishAd = AtomicBoolean(true)
    private var lastTimePosition: Long = -1
    private var adStuckTimes = 0
    private val isCompleted = AtomicBoolean(false)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_ima_player)
        Timber.v("onCreate")
        adPlayerManager = AdPlayerManager(this, AdPlayerActivityExtras.fromIntent(intent))
        configureAdPlayerEventObservers()
        configureButtonClickListeners()
        adPlayerManager.start(videoAdContainer, companionAdSlot)
        loadingContent()
        configureAdPlayerTimeoutJob()
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

    private fun configureButtonClickListeners() {
        Timber.v("configureButtonClickListeners")
        buttonPlayPause?.clicks()
                ?.filter { buttonPlayPause.getTag(R.id.state) is PlayerAction }
                ?.map { buttonPlayPause.getTag(R.id.state) as PlayerAction }
                ?.observeOn(AndroidSchedulers.mainThread())
                ?.doOnNext { bindPlayPauseAction(it) }
                ?.doOnError { Timber.e(it) }
                ?.subscribe()
                ?.compose()

        buttonHelp?.clicks()
                ?.debounce(1, TimeUnit.SECONDS)
                ?.observeOn(AndroidSchedulers.mainThread())
                ?.doOnNext { showBottomSheetHelp() }
                ?.subscribe()
                ?.compose()
    }

    private fun showBottomSheetHelp() {
        TODO("Not yet implemented")
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
            AdEvent.AdEventType.STARTED -> {
                showContent()
                playingButtonState()
            }
            AdEvent.AdEventType.PAUSED -> pauseButtonState()
            AdEvent.AdEventType.RESUMED -> playingButtonState()
            AdEvent.AdEventType.ALL_ADS_COMPLETED -> onComplete()
            AdEvent.AdEventType.AD_PROGRESS -> onAdProgressAddEventType()
            else -> Timber.d("Unregistered: %s", adEvent.type)
        }

        MethodChannelBridge.callback?.onAddEvent(AdEventOutput.fromAdEvent(adEvent))
    }

    private fun onAdProgressAddEventType() {
        Timber.v("onAdProgressAddEventType")
        Timber.d("Progress - currentTime: ${adPlayerManager.adsCurrentPosition()}")
        Timber.d("Progress - durationTime: ${adPlayerManager.adsDuration()}")

        val currentTime = ceil(adPlayerManager.adsCurrentPosition().toDouble()).toLong()
        val durationTime = adPlayerManager.adsDuration()
        
        Timber.d("Progress(currentTime: $currentTime, durationTime: $durationTime)")
        if (durationTime < 0) return
        
        val mediaProgress = MediaProgress(currentTime, durationTime)
        musicProgressView.bind(mediaProgress = mediaProgress, thumbSeekBarUrl = null)
        musicProgressView.disableSeekBarTouch()

        updateAdStuckTimes(currentTime)

        if (isStuck(durationTime, currentTime)) {
            onComplete()
        }

        lastTimePosition = currentTime
    }

    private fun isStuck(durationTime: Long, currentTime: Long) =
            durationTime == 0L && currentTime == 0L && adStuckTimes > 10

    private fun updateAdStuckTimes(currentTime: Long) {
        if (lastTimePosition == currentTime)
            adStuckTimes++
        else
            adStuckTimes = 0
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
        MethodChannelBridge.callback?.onAddEvent(AdEventOutput.error(code, message))
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
        progressBar.hide()
    }

    private fun playingButtonState() {
        Timber.v("playingButtonState")
        buttonPlayPause?.setImageResource(R.drawable.ic_bt_player_pause)
        buttonPlayPause?.setTag(R.id.state, PlayerAction.Pause)
        buttonPlayPause?.show()
    }

    private fun pauseButtonState() {
        Timber.v("pauseButtonState")
        buttonPlayPause?.setImageResource(R.drawable.ic_bt_player_play)
        buttonPlayPause?.setTag(R.id.state, PlayerAction.Play)
        buttonPlayPause?.show()
    }

    private fun onComplete() {
        Timber.v("releaseVideoAd")
        if (isCompleted.getAndSet(true)) return
        MethodChannelBridge.callback?.onComplete()
        runOnUiThread { adPlayerManager.release() }
        finish()
    }

    private fun bindPlayPauseAction(playerAction: PlayerAction) {
        Timber.v("bindPlayPauseAction")
        if (playerAction == PlayerAction.Play) {
            adPlayerManager.play()
            playingButtonState()
        }
        else {
            adPlayerManager.pause()
            pauseButtonState()
        }
    }

    private fun loadingContent() {
        Timber.v("loadingContent")
        videoAdContainer.hide()
        progressBar.show()
    }

    override fun onResume() {
        Timber.d("onResume")
        if (adPlayerManager.isAudioAd.not())
            adPlayerManager.play()
        super.onResume()
    }

    override fun onPause() {
        Timber.d("onPause")
        if (adPlayerManager.isAudioAd.not())
            adPlayerManager.pause()
        super.onPause()
    }

    override fun onDestroy() {
        Timber.d("onDestroy")
        compositeDisposable.clear()
        super.onDestroy()
    }
}

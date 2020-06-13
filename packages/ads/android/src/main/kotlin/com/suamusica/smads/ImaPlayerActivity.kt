package com.suamusica.smads

import android.content.Context
import android.content.Intent
import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import com.google.ads.interactivemedia.v3.api.AdErrorEvent
import com.google.ads.interactivemedia.v3.api.AdEvent
import com.google.android.exoplayer2.Player
import com.jakewharton.rxbinding3.view.clicks
import com.suamusica.smads.extensions.hide
import com.suamusica.smads.extensions.show
import com.suamusica.smads.media.domain.MediaProgress
import com.suamusica.smads.player.PlayerAction
import io.reactivex.Observable
import io.reactivex.Single
import io.reactivex.android.schedulers.AndroidSchedulers
import io.reactivex.disposables.CompositeDisposable
import io.reactivex.disposables.Disposable
import io.reactivex.schedulers.Schedulers
import kotlinx.android.synthetic.main.activity_ima_player.buttonPlayPause
import kotlinx.android.synthetic.main.activity_ima_player.companionAdSlot
import kotlinx.android.synthetic.main.activity_ima_player.musicProgressView
import kotlinx.android.synthetic.main.activity_ima_player.progressBar
import kotlinx.android.synthetic.main.activity_ima_player.videoAdContainer
import timber.log.Timber
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.math.ceil

class ImaPlayerActivity : AppCompatActivity() {

    companion object {
        private const val AD_TAG_URL_KEY = "AD_URL_KEY"
        private const val CONTENT_URL_KEY = "CONTENT_URL_KEY"

        fun getIntent(context: Context, adUrl: String, contentUrl: String): Intent {
            val intent = Intent(context, ImaPlayerActivity::class.java)
            intent.putExtra(AD_TAG_URL_KEY, adUrl)
            intent.putExtra(CONTENT_URL_KEY, contentUrl)
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            return intent
        }
    }

    private lateinit var screenManager: ScreenManager
    private lateinit var adPlayerManager: AdPlayerManager
    private val compositeDisposable: CompositeDisposable = CompositeDisposable()
    private fun Disposable.compose() = compositeDisposable.add(this)
    private var timeoutShouldFinishAd = AtomicBoolean(true)
    private var shownEventSent = 0
    private var lastTimePosition: Long = -1
    private var adStuckTimes = 0

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_ima_player)
        val adTagUrl = intent.getStringExtra(AD_TAG_URL_KEY)
        val contentUrl = intent.getStringExtra(CONTENT_URL_KEY)
        Timber.v("onCreate")
        Timber.d("adTagUrl %s", adTagUrl)
        screenManager = ScreenManager(this)
        adPlayerManager = AdPlayerManager(this, adTagUrl)
        configureAdPlayerEventObservers()
        configureButtonClickListeners()
        adPlayerManager.start(videoAdContainer, companionAdSlot, contentUrl)
        loadingContent()
        configureAdPlayerTimeoutJob()
        configurePlayerStatusJob()
    }

    private fun configureAdPlayerTimeoutJob() {
        Timber.v("configureAdPlayerTimeoutJob")
        Single.timer(5, TimeUnit.SECONDS)
                .observeOn(Schedulers.io())
                .filter { timeoutShouldFinishAd.get() }
                .subscribe({
                    Timber.d("Time reached")
                    releaseVideoAd()
                }, { e -> Timber.e(e) })
                .compose()
    }

    private fun configurePlayerStatusJob() {
        Observable.interval(20, TimeUnit.MILLISECONDS)
                .observeOn(Schedulers.io())
                .subscribe({
                    runOnUiThread { updateProgressBar() }
                }, {})
                .compose()
    }

    private val playerStateDescription = mapOf(
        Player.STATE_IDLE to "IDLE",
        Player.STATE_BUFFERING to "BUFFERING",
        Player.STATE_READY to "READY",
        Player.STATE_ENDED to "ENDED"
    )

    private fun updateProgressBar() {

        Timber.d("Player State: ${playerStateDescription[adPlayerManager.getState()]}")

        when(adPlayerManager.getState()) {
            Player.STATE_IDLE,
            Player.STATE_BUFFERING,
            Player.STATE_READY -> {}
            Player.STATE_ENDED -> releaseVideoAd()
            else -> {}
        }

        Timber.d("Progress - currentTime: ${adPlayerManager.adsCurrentPosition()}, durationTime: ${adPlayerManager.adsDuration()} ")
        val currentTime = ceil(adPlayerManager.adsCurrentPosition().toDouble()).toLong()
        val durationTime = adPlayerManager.adsDuration()
        Timber.d("Progress(currentTime: $currentTime, durationTime: $durationTime)")
        if (durationTime < 0) return
        val mediaProgress = MediaProgress(currentTime, durationTime)
        musicProgressView.bind(mediaProgress, null)
        musicProgressView.disableSeekBarTouch()
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
    }

    private fun onAdEvent(adEvent: AdEvent) {
        Timber.v("onAdEvent(adEvent: $adEvent)")
        Timber.d("adEventType %s", adEvent.type)

        when (adEvent.type) {
            AdEvent.AdEventType.LOADED -> timeoutShouldFinishAd.set(false)
            AdEvent.AdEventType.STARTED -> {
                showContent()
                playingButtonState()
            }
            AdEvent.AdEventType.PAUSED -> {
                pauseButtonState()
            }
            AdEvent.AdEventType.RESUMED -> {
                playingButtonState()
            }
            AdEvent.AdEventType.SKIPPED -> {
//                releaseVideoAd()
            }
            AdEvent.AdEventType.CONTENT_PAUSE_REQUESTED -> adPlayerManager.play()
            AdEvent.AdEventType.ALL_ADS_COMPLETED -> {
//                releaseVideoAd()
            }
            AdEvent.AdEventType.AD_PROGRESS -> onAdProgressAddEventType()
            AdEvent.AdEventType.LOG -> {
                Timber.d("LOG - data: ${adEvent.adData}")
                if (adEvent.adData.filterKeys { it.contains("error") }.isNotEmpty())
                    releaseVideoAd()
            }
            else -> Timber.d("Unregistered: %s", adEvent.type)
        }
    }

    private fun onAdProgressAddEventType() {
        Timber.v("onAdProgressAddEventType")
        shownEventSent++
        Timber.d("Progress - currentTime: ${adPlayerManager.adsCurrentPosition()}, durationTime: ${adPlayerManager.adsDuration()} ")
        val currentTime = ceil(adPlayerManager.adsCurrentPosition().toDouble()).toLong()
        val durationTime = adPlayerManager.adsDuration()
        Timber.d("Progress(currentTime: $currentTime, durationTime: $durationTime)")
        if (durationTime < 0) return
//        val mediaProgress = MediaProgress(currentTime, durationTime)
//        musicProgressView.bind(mediaProgress, null)
//        musicProgressView.disableSeekBarTouch()

        if (lastTimePosition == currentTime)
            adStuckTimes++
        else
            adStuckTimes = 0

        if (durationTime == 0L && currentTime == 0L && adStuckTimes > 10) {
            releaseVideoAd()
        }

        if (adPlayerManager.isAudioAd
                && screenManager.areInBackground()
                && adStuckTimes > 4
                && currentTime.toFloat().div(durationTime) > 0.94) {
            releaseVideoAd()
        }

        if (adPlayerManager.isAudioAd) {
            companionAdSlot.show()
            videoAdContainer.hide()
        } else {
            companionAdSlot.hide()
            videoAdContainer.show()
        }

        lastTimePosition = currentTime
    }

    private fun onAdError(adErrorEvent: AdErrorEvent) {
        Timber.v("onAdError($adErrorEvent)")
        Timber.d("adErrorEvent.error.errorCode: %s", adErrorEvent.error.errorCode)
        Timber.d("adErrorEvent.error.errorType: %s", adErrorEvent.error.errorType)
        Timber.d("adErrorEvent.error.errorCodeNumber: %s", adErrorEvent.error.errorCodeNumber)
        Timber.e(adErrorEvent.error.cause, "adErrorEvent.error.cause")
        releaseVideoAd()
    }

    private fun showContent() {
        Timber.v("showContent")
        videoAdContainer.show()
        progressBar.hide()
    }

    private fun playingButtonState() {
        Timber.v("playingButtonState")
        buttonPlayPause?.setImageResource(R.drawable.ic_pause_player)
        buttonPlayPause?.setTag(R.id.state, PlayerAction.Pause)
        buttonPlayPause?.show()
    }

    private fun pauseButtonState() {
        Timber.v("pauseButtonState")
        buttonPlayPause?.setImageResource(R.drawable.ic_play_player)
        buttonPlayPause?.setTag(R.id.state, PlayerAction.Play)
        buttonPlayPause?.show()
    }

    private fun releaseVideoAd() {
        Timber.v("releaseVideoAd")
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
//    lateinit var adsLoader: ImaAdsLoader
//    private var player: SimpleExoPlayer? = null


//    override fun onCreate(savedInstanceState: Bundle?) {
//        super.onCreate(savedInstanceState)
//        setContentView(R.layout.activity_ima_player)
//        val adUrl = intent.getStringExtra(AD_URL_KEY)
//        Log.d(tag, "adUrl: $adUrl")
//        adsLoader = ImaAdsLoader(this, Uri.parse(adUrl))
//    }
//
//    private fun releasePlayer() {
//        adsLoader.setPlayer(null)
//        videoAdContainer.player = null
//        player?.release()
//        player = null
//    }
//
//    private fun initializePlayer() {
//        val contentUrl = intent.getStringExtra(CONTENT_URL_KEY)
//        Log.d(tag, "contentUrl: $contentUrl")
//        player = SimpleExoPlayer.Builder(this).build()
//        videoAdContainer.player = player
//        adsLoader.setPlayer(player)
//        val dataSourceFactory =  DefaultDataSourceFactory(this, Util.getUserAgent(this, "ima_test"))
//        val mediaSourceFactory = ProgressiveMediaSource.Factory(dataSourceFactory)
//        val mediaSource = mediaSourceFactory.createMediaSource(Uri.parse(contentUrl))
//        val adsMediaSource = AdsMediaSource(mediaSource, dataSourceFactory, adsLoader, videoAdContainer)
//
//        player?.prepare(adsMediaSource)
//        player?.playWhenReady = true
//    }
//
//    override fun onStart() {
//        super.onStart()
//        if (Util.SDK_INT > 23) {
//            initializePlayer()
//            if (videoAdContainer != null) {
//                videoAdContainer.onResume()
//            }
//        }
//    }
//
//    override fun onResume() {
//        super.onResume()
//        if (Util.SDK_INT <= 23 || player == null) {
//            initializePlayer()
//            if (videoAdContainer != null) {
//                videoAdContainer.onResume()
//            }
//        }
//    }
//
//    override fun onPause() {
//        super.onPause()
//        if (Util.SDK_INT <= 23) {
//            if (videoAdContainer != null) {
//                videoAdContainer.onPause()
//            }
//            releasePlayer()
//        }
//    }
//
//    override fun onStop() {
//        super.onStop()
//        if (Util.SDK_INT > 23) {
//            if (videoAdContainer != null) {
//                videoAdContainer.onPause()
//            }
//            releasePlayer()
//        }
//    }
//
//    override fun onDestroy() {
//        super.onDestroy()
//        adsLoader.release()
//    }
}

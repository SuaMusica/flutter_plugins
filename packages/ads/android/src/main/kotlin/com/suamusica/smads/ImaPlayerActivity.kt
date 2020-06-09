package com.suamusica.smads

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.util.Log
import androidx.appcompat.app.AppCompatActivity
import com.google.android.exoplayer2.SimpleExoPlayer
import com.google.android.exoplayer2.ext.ima.ImaAdsLoader
import com.google.android.exoplayer2.source.ProgressiveMediaSource
import com.google.android.exoplayer2.source.ads.AdsMediaSource
import com.google.android.exoplayer2.upstream.DefaultDataSourceFactory
import com.google.android.exoplayer2.util.Util
import kotlinx.android.synthetic.main.activity_ima_player.playerView

class ImaPlayerActivity : AppCompatActivity() {

    companion object {
        private const val tag = "ImaPlayerActivity"
        private const val AD_URL_KEY = "AD_URL_KEY"
        private const val CONTENT_URL_KEY = "CONTENT_URL_KEY"

        fun getIntent(context: Context, adUrl: String, contentUrl: String): Intent {
            val intent = Intent(context, ImaPlayerActivity::class.java)
            intent.putExtra(AD_URL_KEY, adUrl)
            intent.putExtra(CONTENT_URL_KEY, contentUrl)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            return intent
        }
    }

    lateinit var adsLoader: ImaAdsLoader
    private var player: SimpleExoPlayer? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_ima_player)
        val adUrl = intent.getStringExtra(AD_URL_KEY)
        Log.d(tag, "adUrl: $adUrl")
        adsLoader = ImaAdsLoader(this, Uri.parse(adUrl))
    }

    private fun releasePlayer() {
        adsLoader.setPlayer(null)
        playerView.player = null
        player?.release()
        player = null
    }

    private fun initializePlayer() {
        val contentUrl = intent.getStringExtra(CONTENT_URL_KEY)
        Log.d(tag, "contentUrl: $contentUrl")
        player = SimpleExoPlayer.Builder(this).build()
        playerView.player = player
        adsLoader.setPlayer(player)
        val dataSourceFactory =  DefaultDataSourceFactory(this, Util.getUserAgent(this, "ima_test"))
        val mediaSourceFactory = ProgressiveMediaSource.Factory(dataSourceFactory)
        val mediaSource = mediaSourceFactory.createMediaSource(Uri.parse(contentUrl))
        val adsMediaSource = AdsMediaSource(mediaSource, dataSourceFactory, adsLoader, playerView)

        player?.prepare(adsMediaSource)
        player?.playWhenReady = true
    }

    override fun onStart() {
        super.onStart()
        if (Util.SDK_INT > 23) {
            initializePlayer()
            if (playerView != null) {
                playerView.onResume()
            }
        }
    }

    override fun onResume() {
        super.onResume()
        if (Util.SDK_INT <= 23 || player == null) {
            initializePlayer()
            if (playerView != null) {
                playerView.onResume()
            }
        }
    }

    override fun onPause() {
        super.onPause()
        if (Util.SDK_INT <= 23) {
            if (playerView != null) {
                playerView.onPause()
            }
            releasePlayer()
        }
    }

    override fun onStop() {
        super.onStop()
        if (Util.SDK_INT > 23) {
            if (playerView != null) {
                playerView.onPause()
            }
            releasePlayer()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        adsLoader.release()
    }
}

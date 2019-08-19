package br.com.suamusica.player

import android.content.Context
import android.net.Uri
import android.util.Log
import com.google.android.exoplayer2.*
import com.google.android.exoplayer2.audio.AudioAttributes
import com.google.android.exoplayer2.source.TrackGroupArray
import com.google.android.exoplayer2.source.smoothstreaming.SsMediaSource
import com.google.android.exoplayer2.trackselection.TrackSelectionArray
import com.google.android.exoplayer2.upstream.DefaultDataSourceFactory
import com.google.android.exoplayer2.upstream.DefaultHttpDataSourceFactory
import java.util.*
import com.google.android.exoplayer2.source.ProgressiveMediaSource
import com.google.android.exoplayer2.source.MediaSource
import com.google.android.exoplayer2.source.hls.HlsMediaSource
import com.google.android.exoplayer2.upstream.DataSource
import com.google.android.exoplayer2.upstream.FileDataSourceFactory
import com.google.android.exoplayer2.util.Util


class WrappedExoPlayer(val playerId: String, override val context: Context, override val cookie: String) : Player {
    override var volume = 1.0
    override val duration = 0
    override val currentPosition = 0
    override var releaseMode = ReleaseMode.RELEASE
    override var stayAwake: Boolean = false

    private val uAmpAudioAttributes = AudioAttributes.Builder()
            .setContentType(C.CONTENT_TYPE_MUSIC)
            .setUsage(C.USAGE_MEDIA)
            .build()

    private fun playerEventListener(): com.google.android.exoplayer2.Player.EventListener {
        return object : com.google.android.exoplayer2.Player.EventListener {
            override fun onTimelineChanged(timeline: Timeline?, manifest: Any?, reason: Int) {
                Log.i("MusicService", "onTimelineChanged: timeline: $timeline manifest: $manifest reason: $reason")
            }

            override fun onTracksChanged(trackGroups: TrackGroupArray?, trackSelections: TrackSelectionArray?) {
                Log.i("MusicService", "onTimelineChanged: trackGroups: $trackGroups trackSelections: $trackSelections")
            }

            override fun onLoadingChanged(isLoading: Boolean) {
                Log.i("MusicService", "onLoadingChanged: isLoading: $isLoading")
            }

            override fun onPlayerStateChanged(playWhenReady: Boolean, playbackState: Int) {
                Log.i("MusicService", "onPlayerStateChanged: playWhenReady: $playWhenReady playbackState: $playbackState")
            }

            override fun onRepeatModeChanged(repeatMode: Int) {
                Log.i("MusicService", "onRepeatModeChanged: $repeatMode")
            }

            override fun onShuffleModeEnabledChanged(shuffleModeEnabled: Boolean) {
                Log.i("MusicService", "onShuffleModeEnabledChanged: $shuffleModeEnabled")
            }

            override fun onPlayerError(error: ExoPlaybackException?) {
                Log.e("MusicService", "onPLayerError: ${error?.message}", error)
            }

            override fun onPositionDiscontinuity(reason: Int) {
                Log.i("MusicService", "onPositionDiscontinuity: $reason")
            }

            override fun onPlaybackParametersChanged(playbackParameters: PlaybackParameters?) {
                Log.i("MusicService", "onPlaybackParametersChanged: $playbackParameters")
            }

            override fun onSeekProcessed() {
                Log.i("MusicService", "onSeekProcessed")
            }
        }
    }

    val player = ExoPlayerFactory.newSimpleInstance(context).apply {
        setAudioAttributes(uAmpAudioAttributes, true)
        addListener(playerEventListener())
    }

    override fun prepare(url: String) {
        Log.i("SMPlayer", "Cookie=$cookie")

        val defaultHttpDataSourceFactory = DefaultHttpDataSourceFactory("mp.next")
        defaultHttpDataSourceFactory.defaultRequestProperties.set("Cookie", cookie)
        val dataSourceFactory = DefaultDataSourceFactory(context, null, defaultHttpDataSourceFactory)

        val uri = Uri.parse(url)

        @C.ContentType val type = Util.inferContentType(uri)
        val source = when (type) {
            C.TYPE_HLS -> HlsMediaSource.Factory(dataSourceFactory)
                    .setAllowChunklessPreparation(true)
                    .createMediaSource(uri)
            C.TYPE_OTHER -> {
                val factory: DataSource.Factory =
                        if (uri.scheme != null && uri.scheme?.startsWith("http") == true) {
                            dataSourceFactory
                        } else {
                            FileDataSourceFactory()
                        }

                ProgressiveMediaSource.Factory(factory)
                        .createMediaSource(uri)
            }
            else -> {
                throw IllegalStateException("Unsupported type: $type")
            }
        }

//        val source = SsMediaSource.Factory(dataSourceFactory).createMediaSource(Uri.parse(url))
//        val source = ProgressiveMediaSource.Factory(dataSourceFactory)
//                .createMediaSource(Uri.parse(url))
        player.prepare(source)
    }

    override fun play() {
        player.playWhenReady = true
    }

    override fun seek(position: Int) {
    }

    override fun pause() {
    }

    override fun stop() {
    }

    override fun release() {
    }
}

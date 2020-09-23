package com.suamusica.smads

import android.content.Context
import android.os.Build
import android.os.Handler
import com.google.android.exoplayer2.drm.DrmSessionManager
import com.google.android.exoplayer2.drm.FrameworkMediaCrypto
import com.google.android.exoplayer2.mediacodec.MediaCodecSelector
import com.google.android.exoplayer2.video.MediaCodecVideoRenderer
import com.google.android.exoplayer2.video.VideoRendererEventListener
import timber.log.Timber


internal class SMMediaCodecVideoRenderer(context: Context, mediaCodecSelector: MediaCodecSelector, drmSessionManager: DrmSessionManager<FrameworkMediaCrypto>?, playClearSamplesWithoutKeys: Boolean, enableDecoderFallback: Boolean, eventHandler: Handler, eventListener: VideoRendererEventListener, allowedVideoJoiningTimeMs: Long, maxDroppedFrames: Int) : MediaCodecVideoRenderer(context, mediaCodecSelector,allowedVideoJoiningTimeMs,   drmSessionManager, playClearSamplesWithoutKeys, enableDecoderFallback, eventHandler, eventListener, maxDroppedFrames) {
    override fun codecNeedsSetOutputSurfaceWorkaround(name: String): Boolean {
        if(Build.VERSION.SDK_INT <= Build.VERSION_CODES.N_MR1){
            return true
        }
        return super.codecNeedsSetOutputSurfaceWorkaround(name)
    }

}

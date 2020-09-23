package com.suamusica.smads

import android.os.Build
import com.google.android.exoplayer2.mediacodec.MediaCodecInfo
import com.google.android.exoplayer2.mediacodec.MediaCodecSelector
import com.google.android.exoplayer2.mediacodec.MediaCodecUtil
import com.google.android.exoplayer2.mediacodec.MediaCodecUtil.DecoderQueryException

class BlackListMediaCodecSelector : MediaCodecSelector {
    @Throws(DecoderQueryException::class)
    override fun getDecoderInfos(mimeType: String, requiresSecureDecoder: Boolean, requiresTunnelingDecoder: Boolean): List<MediaCodecInfo> {
        val codecInfos = MediaCodecUtil.getDecoderInfos(
                mimeType, requiresSecureDecoder, requiresTunnelingDecoder)
        // filter codecs based on blacklist template
        val filteredCodecInfos: MutableList<MediaCodecInfo> = ArrayList()
        for (codecInfo in codecInfos) {
            var blacklisted = false
            for (blackListedCodec in BLACKLISTED_CODECS) {
                if (codecInfo.name.contains(blackListedCodec)) {
                    blacklisted = true
                    break
                }
            }
            if (!blacklisted) {
                filteredCodecInfos.add(codecInfo)
            }
        }
        return filteredCodecInfos
    }

    @Throws(DecoderQueryException::class)
    override fun getPassthroughDecoderInfo(): MediaCodecInfo? {
        return MediaCodecUtil.getPassthroughDecoderInfo()
    }

    companion object {
        // list of strings used in blacklisting codecs
        val BLACKLISTED_CODECS =if(Build.VERSION.SDK_INT <= Build.VERSION_CODES.N_MR1) arrayOf("OMX.qcom.video.decoder.avc","OMX.google.vp8.decoder") else arrayOf<String>()

    }
}

package com.suamusica.mediascanner

import android.os.Handler
import android.os.Looper
import com.suamusica.mediascanner.output.MediaOutput
import io.flutter.plugin.common.MethodChannel
import timber.log.Timber

class ChannelCallback(private val channel: MethodChannel,
                      private val handler: Handler = Handler(Looper.getMainLooper())) {

    fun onMediaScanned(mediaOutput: MediaOutput) {
        Timber.v("onMediaScanned(%s)", mediaOutput)
        handler.post { channel.invokeMethod(ON_MEDIA_SCANNED_METHOD, mediaOutput.toResult()) }
    }

    companion object {
        private const val ON_MEDIA_SCANNED_METHOD = "onMediaScanned"
    }
}
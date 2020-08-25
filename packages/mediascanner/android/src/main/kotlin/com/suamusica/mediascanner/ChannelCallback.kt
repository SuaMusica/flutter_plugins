package com.suamusica.mediascanner

import android.os.Handler
import android.os.Looper
import com.suamusica.mediascanner.output.ScannedMediaOutput
import io.flutter.plugin.common.MethodChannel
import timber.log.Timber

class ChannelCallback(private val channel: MethodChannel,
                      private val handler: Handler = Handler(Looper.getMainLooper())) {

    fun onMediaScanned(scannedMediaOutput: ScannedMediaOutput) {
        handler.post { channel.invokeMethod(ON_MEDIA_SCANNED_METHOD, scannedMediaOutput.toResult()) }
    }

    fun onAllMediaScanned(scannedMediaOutputList: List<ScannedMediaOutput>) {
        handler.post { channel.invokeMethod(ON_ALL_MEDIA_SCANNED_METHOD, scannedMediaOutputList.map { it.toResult() }) }
    }

    companion object {
        private const val ON_MEDIA_SCANNED_METHOD = "onMediaScanned"
        private const val ON_ALL_MEDIA_SCANNED_METHOD = "onAllMediaScanned"
    }
}
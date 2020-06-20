package com.suamusica.smads

import android.os.Handler
import android.os.Looper
import com.suamusica.smads.output.AdEventOutput
import com.suamusica.smads.output.ErrorOutput
import io.flutter.plugin.common.MethodChannel
import timber.log.Timber

class SmadsCallback(private val channel: MethodChannel) {

    fun onAddEvent(adEventOutput: AdEventOutput) {
        Timber.v("onAddEvent(adEventOutput = %s)", adEventOutput)
        onAddEvent(adEventOutput.toResult())
    }

    fun onAddEvent(output: Map<String, String>) {
        Timber.v("onAddEvent(output = %s)", output)
        onMainThread { channel.invokeMethod(ON_AD_EVENT_METHOD, output) }
    }

    fun onComplete() {
        Timber.v("onComplete()")
        onMainThread { channel.invokeMethod(ON_COMPLETE_METHOD, mapOf<Any, Any>()) }
    }

    fun onError(errorOutput: ErrorOutput) {
        Timber.v("onError(error = %s)", errorOutput)
        onMainThread { channel.invokeMethod(ON_ERROR_METHOD, errorOutput.toResult()) }
    }

    private fun onMainThread(block: ()->Unit) {
        Handler(Looper.getMainLooper()).post(block)
    }
    companion object {
        private const val ON_AD_EVENT_METHOD = "onAdEvent"
        private const val ON_COMPLETE_METHOD = "onComplete"
        private const val ON_ERROR_METHOD = "onError"
    }
}
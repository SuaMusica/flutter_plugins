package com.suamusica.smads

import com.suamusica.smads.output.AdEventOutput
import com.suamusica.smads.output.ErrorOutput
import io.flutter.plugin.common.MethodChannel

class SmadsCallback(private val channel: MethodChannel) {

    fun onAddEvent(adEventOutput: AdEventOutput) {
        onAddEvent(adEventOutput.toResult())
    }

    fun onAddEvent(output: Map<String, String>) {
        channel.invokeMethod(ON_AD_EVENT_METHOD, output)
    }

    fun onComplete() {
        channel.invokeMethod(ON_COMPLETE_METHOD, mapOf<Any, Any>())
    }

    fun onError(error: ErrorOutput) {
        channel.invokeMethod(ON_ERROR_METHOD, error.toResult())
    }

    companion object {
        private const val ON_AD_EVENT_METHOD = "onAdEvent"
        private const val ON_COMPLETE_METHOD = "onComplete"
        private const val ON_ERROR_METHOD = "onError"
    }
}
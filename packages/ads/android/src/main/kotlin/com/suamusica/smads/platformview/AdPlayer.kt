package com.suamusica.smads.platformview

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.view.View
import com.suamusica.smads.SmadsCallback
import com.suamusica.smads.helpers.ScreenHelper
import com.suamusica.smads.input.LoadMethodInput
import com.suamusica.smads.result.LoadResult
import com.suamusica.smads.result.ScreenStatusResult
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import timber.log.Timber

class AdPlayer(
        private val context: Context,
        messenger: BinaryMessenger,
        id: Int,
        private val params: AdPlayerParams
) : PlatformView, MethodChannel.MethodCallHandler {

    private val channel: MethodChannel = MethodChannel(messenger, VIEW_TYPE_ID)
    private val playerView = AdPlayerView(context)
    private val callback = SmadsCallback(channel)
    private val controller = AdPlayerViewController(context, callback, playerView)

    init {
        channel.setMethodCallHandler(this)
    }

    override fun getView(): View = playerView

    override fun dispose() {
        Timber.v("dispose")
        playerView.visibility = View.GONE
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        Timber.v("onMethodCall")
        Timber.d("call.method: %s", call.method)
        when (call.method) {
            LOAD_METHOD -> load(call.arguments, result)
            PLAY_METHOD -> controller.play()
            PAUSE_METHOD -> controller.pause()
            DISPOSE_METHOD -> controller.dispose()
            SCREEN_STATUS_METHOD -> screenStatus(result)
            else -> result.notImplemented()
        }
    }

    private fun load(input: Any, result: MethodChannel.Result) {
        Timber.d("load()")
        try {
            Handler(Looper.getMainLooper()).post {
                controller.load(LoadMethodInput(input), params.adSize)
                result.success(LoadResult.SUCCESS)
            }
        } catch (t: Throwable) {
            Timber.e(t)
            result.error(LoadResult.UNKNOWN_ERROR.toString(), t.message, null)
        }
    }

    private fun screenStatus(result: MethodChannel.Result) {
        Timber.d("screenStatus()")
        val resultCode = if(ScreenHelper.isForeground(context)) {
            ScreenStatusResult.IS_FOREGROUND
        } else {
            ScreenStatusResult.IS_BACKGROUND
        }
        Timber.d("screenStatus = %s", resultCode)
        result.success(resultCode)
    }

    companion object {
        private const val LOAD_METHOD = "load"
        private const val PLAY_METHOD = "play"
        private const val PAUSE_METHOD = "pause"
        private const val DISPOSE_METHOD = "dispose"
        private const val SCREEN_STATUS_METHOD = "screen_status"
        const val VIEW_TYPE_ID = "suamusica/pre_roll"
    }
}
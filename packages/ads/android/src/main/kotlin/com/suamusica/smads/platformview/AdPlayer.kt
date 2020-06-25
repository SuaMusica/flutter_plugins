package com.suamusica.smads.platformview

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.view.View
import com.suamusica.smads.SmadsCallback
import com.suamusica.smads.helpers.ConnectivityHelper
import com.suamusica.smads.helpers.ScreenHelper
import com.suamusica.smads.input.LoadMethodInput
import com.suamusica.smads.output.ErrorOutput
import com.suamusica.smads.result.LoadResult
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import timber.log.Timber

class AdPlayer(
        private val context: Context,
        messenger: BinaryMessenger,
        id: Int,
        args: HashMap<*, *>?
) : PlatformView, MethodChannel.MethodCallHandler {

    private val channel: MethodChannel = MethodChannel(messenger, "${VIEW_TYPE_ID}_$id")
    private val playerView = AdPlayerView(context)
    private val callback = SmadsCallback(channel)
    private val controller = AdPlayerViewController(context, callback, playerView)

    init {
        channel.setMethodCallHandler(this)
    }

    override fun getView(): View = playerView

    override fun dispose() {
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
            else -> result.notImplemented()
        }
    }

    private fun load(input: Any, result: MethodChannel.Result) {
        Timber.d("load()")
        try {

            if (!ScreenHelper.isVisible(context)) {
                Timber.d("Screen is gone")
                callback.onError(ErrorOutput.SCREEN_IS_LOCKED)
                result.success(LoadResult.SCREEN_IS_LOCKED)
                return
            }

            ConnectivityHelper.ping(context) { status ->
                Handler(Looper.getMainLooper()).post {
                    if (status) {
                        controller.load(LoadMethodInput(input))
                        result.success(LoadResult.SUCCESS)
                    } else {
                        Timber.d("has no connectivity")
                        callback.onError(ErrorOutput.NO_CONNECTIVITY)
                        result.success(LoadResult.NO_CONNECTIVITY)
                    }
                }
            }
        } catch (t: Throwable) {
            Timber.e(t)
            result.error(LoadResult.UNKNOWN_ERROR.toString(), t.message, null)
        }
    }

    companion object {
        private const val LOAD_METHOD = "load"
        private const val PLAY_METHOD = "play"
        private const val PAUSE_METHOD = "pause"
        
        const val VIEW_TYPE_ID = "suamusica/pre_roll"
    }
}
package com.suamusica.smads

import android.content.Context
import android.os.Handler
import android.os.Looper
import androidx.annotation.NonNull
import com.suamusica.smads.helpers.ScreenHelper
import com.suamusica.smads.input.LoadMethodInput
import com.suamusica.smads.platformview.AdPlayer
import com.suamusica.smads.platformview.AdPlayerFactory
import com.suamusica.smads.platformview.AdPlayerView
import com.suamusica.smads.platformview.AdPlayerViewController
import com.suamusica.smads.result.LoadResult
import com.suamusica.smads.result.ScreenStatusResult
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import timber.log.Timber

/** SmadsPlugin */
class SmadsPlugin : FlutterPlugin, MethodCallHandler {

    private val tag = "SmadsPlugin"
    private var channel: MethodChannel? = null
    private lateinit var context: Context
    private lateinit var callback: SmadsCallback
    private lateinit var controller: AdPlayerViewController

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        Initializer.run()
        Timber.v("onAttachedToEngine")
        this.channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
        this.context = flutterPluginBinding.applicationContext
        this.callback = SmadsCallback(channel!!)
        this.channel?.setMethodCallHandler(this)
        MethodChannelBridge.callback = callback
        controller = AdPlayerViewController(context, callback, AdPlayerView(context))
        flutterPluginBinding
                .platformViewRegistry
                .registerViewFactory(AdPlayer.VIEW_TYPE_ID, AdPlayerFactory(controller.adPlayerView))
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        Timber.v("onDetachedFromEngine")
        channel?.setMethodCallHandler(null)
        channel = null
        MethodChannelBridge.callback = null
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
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

    private fun load(input: Any, result: Result) {
        Timber.d("load()")
        try {
            Handler(Looper.getMainLooper()).post {
                controller.load(LoadMethodInput(input))
                result.success(LoadResult.SUCCESS)
            }
        } catch (t: Throwable) {
            Timber.e(t)
            result.error(LoadResult.UNKNOWN_ERROR.toString(), t.message, null)
        }
    }

    private fun screenStatus(result: Result) {
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
        @JvmStatic
        fun registerWith(registrar: Registrar) {
            val channel = MethodChannel(registrar.messenger(), CHANNEL_NAME)
            channel.setMethodCallHandler(SmadsPlugin())
        }

        const val CHANNEL_NAME = "suamusica/pre_roll"
        private const val LOAD_METHOD = "load"
        private const val PLAY_METHOD = "play"
        private const val PAUSE_METHOD = "pause"
        private const val DISPOSE_METHOD = "dispose"
        private const val SCREEN_STATUS_METHOD = "screen_status"
    }
}
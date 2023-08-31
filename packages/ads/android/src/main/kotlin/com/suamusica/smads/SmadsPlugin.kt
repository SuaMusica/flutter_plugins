package com.suamusica.smads

import android.content.Context
import android.os.Handler
import android.os.Looper
import androidx.annotation.NonNull
import com.google.ads.interactivemedia.v3.api.ImaSdkFactory
import com.google.ads.interactivemedia.v3.api.ImaSdkSettings
import com.suamusica.smads.helpers.ScreenHelper
import com.suamusica.smads.input.LoadMethodInput
import com.suamusica.smads.platformview.AdPlayer
import com.suamusica.smads.platformview.AdPlayerFactory
import com.suamusica.smads.platformview.AdPlayerView
import com.suamusica.smads.result.LoadResult
import com.suamusica.smads.result.ScreenStatusResult
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import timber.log.Timber

/** SmadsPlugin */
class SmadsPlugin : FlutterPlugin, MethodCallHandler {

    private val TAG = "SmadsPlugin"
    private var imaSdkSettings: ImaSdkSettings? = null
    private var channel: MethodChannel? = null
    private lateinit var context: Context
    private lateinit var callback: SmadsCallback
    private lateinit var controller: AdPlayerViewController

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        Initializer.run()
        Timber.d("onAttachedToEngine")
        this.channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
        this.context = flutterPluginBinding.applicationContext
        this.callback = SmadsCallback(channel!!)
        this.channel?.setMethodCallHandler(this)
        controller = AdPlayerViewController(context, callback)
        flutterPluginBinding
                .platformViewRegistry
                .registerViewFactory(AdPlayer.VIEW_TYPE_ID, AdPlayerFactory(controller))
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        Timber.d("onDetachedFromEngine")
        channel?.setMethodCallHandler(null)
        channel = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        Timber.d("onMethodCall")
        Timber.d("call.method: %s", call.method)
        when (call.method) {
            LOAD_METHOD -> load(call.arguments, result)
            PLAY_METHOD -> controller.play()
            PAUSE_METHOD -> controller.pause()
            DISPOSE_METHOD -> controller.dispose()
            SKIP_METHOD -> controller.skipAd()
            SCREEN_STATUS_METHOD -> screenStatus(result)
            else -> result.notImplemented()
        }
    }

    private fun load(input: Any, result: Result) {
        Timber.d("load() input: %s", input)
        try {
            val args = input as Map<String, Any?>
            val ppID = args["ppid"] as? String
            if (ppID != null) {
                imaSdkSettings = ImaSdkFactory.getInstance().createImaSdkSettings()
                imaSdkSettings?.let {
                    Timber.d("PPID %s", ppID)
                    it.ppid  = ppID
                }
            }
            Handler(Looper.getMainLooper()).post {
                controller.load(LoadMethodInput(input), AdPlayerView(context), imaSdkSettings)
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
        const val CHANNEL_NAME = "suamusica/pre_roll"
        private const val LOAD_METHOD = "load"
        private const val PLAY_METHOD = "play"
        private const val PAUSE_METHOD = "pause"
        private const val DISPOSE_METHOD = "dispose"
        private const val SKIP_METHOD = "skip"
        private const val SCREEN_STATUS_METHOD = "screen_status"

    }
}
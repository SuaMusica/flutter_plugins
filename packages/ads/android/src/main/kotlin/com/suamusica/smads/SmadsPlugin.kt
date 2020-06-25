package com.suamusica.smads

import androidx.annotation.NonNull
import com.suamusica.smads.platformview.AdPlayer
import com.suamusica.smads.platformview.AdPlayerFactory
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import timber.log.Timber

/** SmadsPlugin */
class SmadsPlugin : FlutterPlugin, MethodCallHandler {

//    private var channel: MethodChannel? = null
//    private lateinit var context: Context
//    private var callback: SmadsCallback? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        Initializer.run()
        Timber.v("onAttachedToEngine")
        val channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
//        this.context = flutterPluginBinding.applicationContext
//        this.callback = SmadsCallback(channel!!)
        channel.setMethodCallHandler(this)
//        MethodChannelBridge.callback = callback

        flutterPluginBinding
                .platformViewRegistry
                .registerViewFactory(AdPlayer.VIEW_TYPE_ID, AdPlayerFactory(flutterPluginBinding.binaryMessenger))


    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        Timber.v("onDetachedFromEngine")
//        channel = null
//        callback = null
//        MethodChannelBridge.callback = null
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        Timber.v("onMethodCall")
        Timber.d("call.method: %s", call.method)
//        when (call.method) {
//            LOAD_METHOD -> load(call.arguments, result)
//            SCREEN_STATUS_METHOD -> screenStatus(result)
//            else -> result.notImplemented()
//        }
    }

    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar) {
            val channel = MethodChannel(registrar.messenger(), CHANNEL_NAME)
            channel.setMethodCallHandler(SmadsPlugin())
        }

        const val CHANNEL_NAME = "smads"
    }
}

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

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        Initializer.run()
        Timber.v("onAttachedToEngine")
        val channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
        flutterPluginBinding
                .platformViewRegistry
                .registerViewFactory(AdPlayer.VIEW_TYPE_ID, AdPlayerFactory(flutterPluginBinding.binaryMessenger))
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        Timber.v("onDetachedFromEngine")
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        Timber.v("onMethodCall")
        Timber.d("call.method: %s", call.method)
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

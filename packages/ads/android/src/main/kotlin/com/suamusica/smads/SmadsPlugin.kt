package com.suamusica.smads

import androidx.annotation.NonNull
import com.suamusica.smads.platformview.AdPlayer
import com.suamusica.smads.platformview.AdPlayerFactory
import io.flutter.embedding.engine.plugins.FlutterPlugin
import timber.log.Timber

/** SmadsPlugin */
class SmadsPlugin : FlutterPlugin {

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        Initializer.run()
        Timber.v("onAttachedToEngine")
        flutterPluginBinding
                .platformViewRegistry
                .registerViewFactory(AdPlayer.VIEW_TYPE_ID, AdPlayerFactory(flutterPluginBinding.binaryMessenger))
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        Timber.v("onDetachedFromEngine")
    }
}

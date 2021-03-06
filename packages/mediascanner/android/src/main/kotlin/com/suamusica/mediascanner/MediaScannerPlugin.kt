package com.suamusica.mediascanner

import android.content.Context
import android.os.Build
import androidx.annotation.NonNull;
import com.suamusica.mediascanner.input.DeleteMediaMethodInput
import com.suamusica.mediascanner.input.ScanMediaMethodInput

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import timber.log.Timber

/** MediaScannerPlugin */
public class MediaScannerPlugin: FlutterPlugin, MethodCallHandler {
  private lateinit var channel : MethodChannel
  private lateinit var channelCallback: ChannelCallback
  private lateinit var context: Context
  private lateinit var mediaScanner: MediaScanner

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    Initializer.run()
    Timber.d("onAttachedToEngine")
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
    context = flutterPluginBinding.applicationContext
    channelCallback = ChannelCallback(channel)
    mediaScanner = MediaScanner(channelCallback, context)
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    Timber.d("onMethodCall")
    Timber.d("call.method: %s", call.method)

    when (call.method) {
      SCAN_MEDIA -> scanMedia(args = call.arguments, result = result)
      DELETE_MEDIA -> deleteMedia(args = call.arguments, result = result)
      READ -> read(args = call.arguments as Map<String, String>, result = result)
      "getPlatformVersion" -> {
        result.success("Android ${Build.VERSION.RELEASE}")
      }
      else -> result.notImplemented()
    }
  }

  private fun read(args: Map<String, String>, result: Result) {
    this.mediaScanner.read(args.get(URI)!!)
    result.success(RequestStatusResult.SUCCESS)
  }

  private fun scanMedia(args: Any, result: Result) {
    mediaScanner.scan(ScanMediaMethodInput(args))
    result.success(RequestStatusResult.SUCCESS)
  }

  private fun deleteMedia(args: Any, result: Result) {
    mediaScanner.deleteFromMediaId(DeleteMediaMethodInput(args))
    result.success(RequestStatusResult.SUCCESS)
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    Timber.d("onDetachedFromEngine")
    channel.setMethodCallHandler(null)
  }

  companion object {
    @JvmStatic
    fun registerWith(registrar: Registrar) {
      val channel = MethodChannel(registrar.messenger(), CHANNEL_NAME)
      channel.setMethodCallHandler(MediaScannerPlugin())
    }

    private const val URI = "uri"
    private const val READ = "read"
    private const val SCAN_MEDIA = "scan_media"
    private const val DELETE_MEDIA = "delete_media"
    private const val CHANNEL_NAME = "MediaScanner"
  }
}

package com.suamusica.smads

import android.content.Context
import android.content.Intent
import androidx.annotation.NonNull
import com.suamusica.smads.input.LoadMethodInput
import com.suamusica.smads.result.LoadResult
import com.suamusica.smads.result.ScreenStatusResult
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar

/** SmadsPlugin */
class SmadsPlugin: FlutterPlugin, MethodCallHandler {

  private var channel: MethodChannel? = null
  private var context: Context? = null
  private var callback: SmadsCallback? = null

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    this.channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
    this.context = flutterPluginBinding.applicationContext
    this.callback = SmadsCallback(channel!!)
    this.channel?.setMethodCallHandler(SmadsPlugin())
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel = null
    context = null
    callback = null
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when(call.method) {
      LOAD_METHOD -> load(LoadMethodInput(call.arguments), result)
      SCREEN_STATUS_METHOD -> screenStatus(result)
      else -> result.notImplemented()
    }
  }

  private fun load(input: LoadMethodInput, result: Result) {
    context?.let {
      it.startActivity(Intent(context, ImaPlayerActivity::class.java))
      result.success(LoadResult.SUCCESS)
    }
  }

  private fun screenStatus(result: Result) {
    result.success(ScreenStatusResult.LOCKED_SCREEN)
  }

  companion object {
    @JvmStatic
    fun registerWith(registrar: Registrar) {
      val channel = MethodChannel(registrar.messenger(), CHANNEL_NAME)
      channel.setMethodCallHandler(SmadsPlugin())
    }

    const val CHANNEL_NAME = "smads"
    private const val LOAD_METHOD = "load"
    private const val SCREEN_STATUS_METHOD = "screen_status"
  }
}

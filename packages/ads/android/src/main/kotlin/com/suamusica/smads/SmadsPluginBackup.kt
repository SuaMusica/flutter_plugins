package com.suamusica.smads
//
//import android.content.Context
//import android.os.Handler
//import android.os.Looper
//import androidx.annotation.NonNull
//import com.suamusica.smads.extensions.toAddPayerActivityExtras
//import com.suamusica.smads.helpers.ConnectivityHelper
//import com.suamusica.smads.helpers.ScreenHelper
//import com.suamusica.smads.input.LoadMethodInput
//import com.suamusica.smads.output.ErrorOutput
//import com.suamusica.smads.result.LoadResult
//import com.suamusica.smads.result.ScreenStatusResult
//import io.flutter.embedding.engine.plugins.FlutterPlugin
//import io.flutter.plugin.common.MethodCall
//import io.flutter.plugin.common.MethodChannel
//import io.flutter.plugin.common.MethodChannel.MethodCallHandler
//import io.flutter.plugin.common.MethodChannel.Result
//import io.flutter.plugin.common.PluginRegistry.Registrar
//import timber.log.Timber
//
///** SmadsPlugin */
//class SmadsPluginBackup : FlutterPlugin, MethodCallHandler {
//
//    private val tag = "SmadsPlugin"
//    private var channel: MethodChannel? = null
//    private lateinit var context: Context
//    private var callback: SmadsCallback? = null
//
//    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
//        Initializer.run()
//        Timber.v("onAttachedToEngine")
//        this.channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
//        this.context = flutterPluginBinding.applicationContext
//        this.callback = SmadsCallback(channel!!)
//        this.channel?.setMethodCallHandler(this)
//        MethodChannelBridge.callback = callback
//    }
//
//    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
//        Timber.v("onDetachedFromEngine")
//        channel = null
//        callback = null
//        MethodChannelBridge.callback = null
//    }
//
//    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
//        Timber.v("onMethodCall")
//        Timber.d("call.method: %s", call.method)
//        when (call.method) {
//            LOAD_METHOD -> load(call.arguments, result)
//            SCREEN_STATUS_METHOD -> screenStatus(result)
//            else -> result.notImplemented()
//        }
//    }
//
//    private fun load(input: Any, result: Result) {
//        Timber.d("load()")
//        try {
//
//            if (ScreenHelper.isLocked(context)) {
//                Timber.d("Screen is locked")
//                callback?.onError(ErrorOutput.SCREEN_IS_LOCKED)
//                result.success(LoadResult.SCREEN_IS_LOCKED)
//                return
//            }
//
//            ConnectivityHelper.ping(context) { status ->
//                Handler(Looper.getMainLooper()).post {
//                    if (status) {
//                        showAdPlayerActivity(input, result)
//                    } else {
//                        Timber.d("has no connectivity")
//                        callback?.onError(ErrorOutput.NO_CONNECTIVITY)
//                        result.success(LoadResult.NO_CONNECTIVITY)
//                    }
//                }
//            }
//        } catch (t: Throwable) {
//            Timber.e(t)
//            result.error(LoadResult.UNKNOWN_ERROR.toString(), t.message, null)
//        }
//    }
//
//    private fun showAdPlayerActivity(input: Any, result: Result) {
//        Timber.d("showAdPlayerActivity()")
//        try {
//            val loadMethodInput = LoadMethodInput(input)
//            Timber.d("loadMethodInput: %s", loadMethodInput)
//            val intent = loadMethodInput.toAddPayerActivityExtras().toIntent(context)
//            context.startActivity(intent)
//            result.success(LoadResult.SUCCESS)
//        } catch (t: Throwable) {
//            result.error(LoadResult.UNKNOWN_ERROR.toString(), t.message, null)
//        }
//    }
//
//    private fun screenStatus(result: Result) {
//        Timber.d("screenStatus()")
//        val resultCode = if(ScreenHelper.isLocked(context)) {
//            ScreenStatusResult.LOCKED_SCREEN
//        } else {
//            ScreenStatusResult.UNLOCKED_SCREEN
//        }
//        Timber.d("screenStatus = %s", resultCode)
//        result.success(resultCode)
//    }
//
//    companion object {
//        @JvmStatic
//        fun registerWith(registrar: Registrar) {
//            val channel = MethodChannel(registrar.messenger(), CHANNEL_NAME)
//            channel.setMethodCallHandler(SmadsPluginBackup())
//        }
//
//        const val CHANNEL_NAME = "smads"
//        private const val LOAD_METHOD = "load"
//        private const val SCREEN_STATUS_METHOD = "screen_status"
//    }
//}

package com.suamusica.mediascanner

import android.app.Activity
import android.app.PendingIntent
import android.content.ContentUris
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import androidx.annotation.NonNull;
import com.suamusica.mediascanner.input.DeleteMediaMethodInput
import com.suamusica.mediascanner.input.ScanMediaMethodInput

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.ActivityResultListener
import timber.log.Timber




/** MediaScannerPlugin */
public class MediaScannerPlugin: FlutterPlugin, MethodCallHandler, ActivityAware,
  ActivityResultListener {
  private lateinit var channel : MethodChannel
  private lateinit var channelCallback: ChannelCallback
  private lateinit var context: Context
  private lateinit var mediaScanner: MediaScanner
  private var activity: Activity? = null
  private var activityBinding: ActivityPluginBinding? = null
  private var pendingDeleteResult: Result? = null

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    Initializer.run()
    Timber.d("onAttachedToEngine")
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
    context = flutterPluginBinding.applicationContext
    channelCallback = ChannelCallback(channel)
    mediaScanner = MediaScanner(channelCallback, context)
    channel.setMethodCallHandler(this)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activityBinding = binding
    this.activity = binding.activity
    binding.addActivityResultListener(this)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activityBinding?.removeActivityResultListener(this)
    activityBinding = null
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    onAttachedToActivity(binding)
  }

  override fun onDetachedFromActivity() {
    activityBinding?.removeActivityResultListener(this)
    activityBinding = null
    activity = null
  }
  override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
    if (requestCode != DELETE_MEDIAS_REQUEST_CODE) {
      return false
    }

    val reply = pendingDeleteResult ?: return true
    pendingDeleteResult = null
    reply.success(resultCode == Activity.RESULT_OK)
    return true
  }
  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    Timber.d("onMethodCall")
    Timber.d("call.method: %s", call.method)

    when (call.method) {
      SCAN_MEDIA -> scanMedia(args = call.arguments, result = result)
      DELETE_MEDIA -> deleteMedia(args = call.arguments, result = result)
      DELETE_MEDIAS -> deleteMedias(call = call, result = result)
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

  private fun deleteMedias(call: MethodCall, result: Result) {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) {
      result.success(false)
      return
    }

    if (pendingDeleteResult != null) {
      result.error("delete_in_progress", "A media delete request is already running", null)
      return
    }

    val currentActivity = activity
    if (currentActivity == null) {
      result.error("no_activity", "Plugin is not attached to an activity", null)
      return
    }

    val paths: List<String> = call.argument("paths") ?: emptyList()
    if (paths.isEmpty()) {
      result.success(false)
      return
    }

    val urisToDelete: MutableList<Uri> = ArrayList()
    for (path in paths) {
      Timber.d("path: %s", path)

      val mediaID = getFilePathToMediaID(path)
      Timber.d("mediaID: %d", mediaID)

      if (mediaID > 0) {
        urisToDelete.add(
          ContentUris.withAppendedId(
            MediaStore.Audio.Media.getContentUri("external"),
            mediaID
          )
        )
      }
    }

    if (urisToDelete.isEmpty()) {
      result.success(false)
      return
    }

    val trashRequest: PendingIntent =
      MediaStore.createDeleteRequest(context.contentResolver, urisToDelete)
    pendingDeleteResult = result

    try {
      currentActivity.startIntentSenderForResult(
        trashRequest.intentSender,
        DELETE_MEDIAS_REQUEST_CODE,
        null,
        0,
        0,
        0,
        null
      )
    } catch (exception: Exception) {
      pendingDeleteResult = null
      result.error(
        "delete_launch_failed",
        "Failed to launch delete request: ${exception.message}",
        null
      )
    }
  }


  private fun getFilePathToMediaID(songPath: String): Long {
    var id: Long = 0
    val cr = context.contentResolver
    val uri = MediaStore.Files.getContentUri("external")
    val selection = MediaStore.Audio.Media.DATA
    val selectionArgs = arrayOf(songPath)
    val projection = arrayOf(MediaStore.Audio.Media._ID)
    val cursor = cr.query(uri, projection, "$selection=?", selectionArgs, null)
    if (cursor != null) {
      while (cursor.moveToNext()) {
        val idIndex = cursor.getColumnIndex(MediaStore.Audio.Media._ID)
        id = cursor.getString(idIndex).toLong()
      }
      with(cursor) { close() }
    }
    return id
  }


  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    Timber.d("onDetachedFromEngine")
    channel.setMethodCallHandler(null)
  }

  companion object {
    private const val DELETE_MEDIAS_REQUEST_CODE = 0x1033
    private const val URI = "uri"
    private const val READ = "read"
    private const val SCAN_MEDIA = "scan_media"
    private const val DELETE_MEDIA = "delete_media"
    private const val DELETE_MEDIAS = "delete_medias"
    private const val CHANNEL_NAME = "MediaScanner"
  }
}

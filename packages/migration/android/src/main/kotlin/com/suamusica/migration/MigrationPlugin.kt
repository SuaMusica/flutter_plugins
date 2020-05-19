package com.suamusica.migration;

import android.content.Context
import android.util.Log
import androidx.annotation.NonNull;
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import com.suamusica.room.database.QueryDatabase

/** MigrationPlugin */
public class MigrationPlugin private constructor(private val channel: MethodChannel, private val context: Context): FlutterPlugin, MethodCallHandler {
  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    val channel = MethodChannel(flutterPluginBinding.getFlutterEngine().getDartExecutor(), "migration")
    channel.setMethodCallHandler(MigrationPlugin(channel, flutterPluginBinding.getApplicationContext()));
  }

  // This static function is optional and equivalent to onAttachedToEngine. It supports the old
  // pre-Flutter-1.12 Android projects. You are encouraged to continue supporting
  // plugin registration via this function while apps migrate to use the new Android APIs
  // post-flutter-1.12 via https://flutter.dev/go/android-project-migration.
  //
  // It is encouraged to share logic between onAttachedToEngine and registerWith to keep
  // them functionally equivalent. Only one of onAttachedToEngine or registerWith will be called
  // depending on the user's project. onAttachedToEngine or registerWith must both be defined
  // in the same class.
  companion object {
    // Method names
    const val REQUEST_DOWNLOAD_CONTENT = "requestDownloadedContent"
    const val DELETE_OLD_CONTENT = "requestDownloadedContent"
    const val REQUEST_LOGGED_USER = "requestLoggedUser"
  
    const val Ok = 1
    const val NotOk = 0

    @JvmStatic
    fun registerWith(registrar: Registrar) {
      val channel = MethodChannel(registrar.messenger(), "migration")
      channel.setMethodCallHandler(MigrationPlugin(channel, registrar.context()))
    }
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    try {
      handleMethodCall(call, result)
    } catch (e: Exception) {
      Log.e("Migration", "Unexpected error!", e)
      result.error("Unexpected error!", e.message, e)
    }
  }

  private fun handleMethodCall(call: MethodCall, response: MethodChannel.Result) {
    when(call.method) {
      REQUEST_DOWNLOAD_CONTENT -> {
        QueryDatabase.getInstance(context)?.let { db ->
          val downloads = db.offlineMediaDao().getMedias()?.flatMap {
            listOf(
                    Pair("id", it.id),
                    Pair("path", it.filePath)
            )
          } ?: listOf()

          channel.invokeMethod("downloadedContent", downloads)
          if (downloads.isEmpty()) {
            response.success(NotOk)
          } else {
            response.success(Ok)
          }
        } ?: run {
          response.error("DatabaseNotFound", "Banco de dados não encontrado.", null)
        }
      }
      DELETE_OLD_CONTENT -> {
        QueryDatabase.getInstance(context)?.clearAllTables()
      }
      REQUEST_LOGGED_USER -> {
        val preferences = SharedPreferences(context)

        if (preferences.isLogged()) {
          response.success(
            mapOf(
              "userid" to preferences.getUserId(),
              "name" to preferences.getName(),
              "cover" to preferences.getProfileCover(),
              "age" to preferences.getAge(),
              "gender" to preferences.getGender()
            )
          )
        } else {
          response.error("UserNotFound", "Usuário não encontrado.", null)
        }
      }
      else -> {
        response.notImplemented()
        return
      }
    }

    response.success(Ok)
  }
    

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
  }
}

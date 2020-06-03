package com.suamusica.migration;

import android.content.Context
import android.util.Log
import androidx.annotation.NonNull
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.async
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import com.google.gson.Gson
import com.suamusica.room.database.QueryDatabase


/** MigrationPlugin */
public class MigrationPlugin : FlutterPlugin, MethodCallHandler {

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    val channel = MethodChannel(flutterPluginBinding.getFlutterEngine().getDartExecutor(), "migration")
    channel.setMethodCallHandler(
        MigrationPlugin().apply {
          this.context = flutterPluginBinding.getApplicationContext()
          this.channel = channel
        }
    )
  }
  lateinit var channel:MethodChannel
  lateinit var context:Context

  companion object {
    // Method names
    const val REQUEST_DOWNLOAD_CONTENT = "requestDownloadedContent"
    const val DELETE_OLD_CONTENT = "deleteOldContent"
    const val REQUEST_LOGGED_USER = "requestLoggedUser"
    const val Ok = 1
    const val NotOk = 0
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
      Log.e("Migration", call.method)

    when(call.method) {
      REQUEST_DOWNLOAD_CONTENT -> {
        val result = GlobalScope.async {
          QueryDatabase.getInstance(context)?.let { db ->
            val medias = db.offlineMediaDao().getMedias()?.flatMap {
              it.toMigration()
            }?.map { it.toMap() } ?: listOf()


            val playlists = db.offlinePlaylistDao().getPlaylists()?.filter{ it -> it.id!=null && it.name!=null && it.name.length>0 && it.artistName!=null && it.artistName.length>0 && it.ownerId!=null && it.ownerId.length>0 && it.ownerId.toInt()>0  && medias.firstOrNull { 
              media ->  media.containsKey("playlist_id") && media["playlist_id"] as String == it.id 
              } != null}?.map {
              Log.d("Migration", "Migrating Playlist!! ${it}")
              it.toMigration(isVerified =
              medias.first { media ->  media.containsKey("playlist_id") && media["playlist_id"] as String == it.id } != null
              )
            } ?: listOf()


            val albums = db.offlineAlbumDao().getAlbums()?.filter{ it -> it.id!=null && it.name!=null && it.name.length>0 && it.artistName!=null && it.artistName.length>0 && it.ownerId!=null && it.ownerId.length>0 && it.ownerId.toInt()>0 && medias.firstOrNull { media ->  media.containsKey("album_id") && media["album_id"] as String == it.id } != null}?.map {
              Log.d("Migration", "Migrating Album!! ${it}")
              it.toMigration(isVerified =
              medias.first { media -> media.containsKey("album_id") && media["album_id"] as String == it.id } != null
              )
            } ?: listOf()

            return@let mapOf("medias" to medias, "playlists" to playlists, "albums" to albums)
          } ?: run {
            return@run null
          }
        }

        runBlocking {
          try {
            val downloads = result.await()
            Log.d("Migration", "DownloadedContents: $downloads")
            channel.invokeMethod("androidDownloadedContent", downloads)

            if (downloads == null || downloads?.isEmpty()) {
              response.success(NotOk)
            } else {
              response.success(Ok)
            }
          } catch (ex: java.lang.Exception) {
            Log.e("Migration", "error: $ex", ex)
          }
        }
      }
      DELETE_OLD_CONTENT -> {
        val result = GlobalScope.async {
          QueryDatabase.getInstance(context)?.clearAllTables()
        }
        runBlocking { result.await()
        response.success(Ok) }
        return
      }
      REQUEST_LOGGED_USER -> {
        val preferences = SharedPreferences(context)
        Log.d("Migration", "preferences: ${preferences.getUserId()}")
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
          response.success(null)
        }
      }
      else -> {
        response.notImplemented()
      }
    }
  }


  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
  }
}

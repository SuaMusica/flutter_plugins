package com.suamusica.migration;

import android.content.Context
import android.util.Log
import androidx.annotation.NonNull
import com.mpatric.mp3agic.ID3v2
import com.mpatric.mp3agic.Mp3File
import com.suamusica.room.database.QueryDatabase
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import kotlinx.coroutines.*
import java.io.File
import java.util.*


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

    lateinit var channel: MethodChannel
    lateinit var context: Context

    companion object {
        // Method names
        const val REQUEST_DOWNLOAD_CONTENT = "requestDownloadedContent"
        const val DELETE_OLD_CONTENT = "deleteOldContent"
        const val REQUEST_LOGGED_USER = "requestLoggedUser"
        const val EXTRACT_ART = "extractArt"

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


    private suspend fun getFiles() = coroutineScope {
        async {
            QueryDatabase.getInstance(context)?.let { db ->
                val medias = db.offlineMediaDao().getMedias()?.flatMap {
                    it.toMigration()
                } ?: listOf()

                val id3 = medias.map {
                    readTags(it["local_path"] as String)
                }
                val playlists = db.offlinePlaylistDao().getPlaylists()?.filter { it ->
                    it.id != null && it.name != null && it.name.isNotEmpty() && it.artistName != null && it.artistName.isNotEmpty() && it.ownerId != null && it.ownerId.isNotEmpty() && it.ownerId.toInt() > 0 && medias.firstOrNull { media ->
                        media.containsKey("playlist_id") && media["playlist_id"] as String == it.id
                    } != null
                }?.map {
                    Log.d("Migration", "Migrating Playlist!! ${it}")
                    it.toMigration(isVerified =
                    medias.first { media -> media.containsKey("playlist_id") && media["playlist_id"] as String == it.id } != null
                    )
                } ?: listOf()


                val albums = db.offlineAlbumDao().getAlbums()?.filter { it ->
                    it.id != null && it.name != null && it.name.isNotEmpty() && it.artistName != null && it.artistName.isNotEmpty() && it.ownerId != null && it.ownerId.isNotEmpty() && it.ownerId.toInt() > 0 && medias.firstOrNull { media ->
                        media.containsKey("album_id") && media["album_id"] as String == it.id
                    } != null
                }?.map {
                    Log.d("Migration", "Migrating Album!! $it")
                    it.toMigration(isVerified =
                    medias.first { media -> media.containsKey("album_id") && media["album_id"] as String == it.id } != null
                    )
                } ?: listOf()

                return@let mapOf("medias" to medias, "playlists" to playlists, "albums" to albums, "id3" to id3)
            } ?: run {
                return@run null
            }
        }.await()

    }

    private fun handleMethodCall(call: MethodCall, response: MethodChannel.Result) {
        Log.e("Migration", call.method)
        when (call.method) {
            REQUEST_DOWNLOAD_CONTENT -> {
                GlobalScope.launch {
                    try {
                        val downloads = getFiles()
                        Log.d("Migration", "DownloadedContents: $downloads")
                        GlobalScope.launch(Dispatchers.Main) {
                            channel.invokeMethod("androidDownloadedContent", downloads)
                            if (downloads == null || downloads?.isEmpty()) {
                                response.success(NotOk)
                            } else {
                                response.success(Ok)
                            }
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
                runBlocking {
                    result.await()
                    response.success(Ok)
                }
                return
            }
            EXTRACT_ART -> {
                GlobalScope.async {
                    val items = call.argument<List<HashMap<String, String>>>("items")
                    for (item in items.orEmpty()) {
                        try {
                            val path = item["path"] as String
                            val coverPath = item["coverPath"] as String
                            val bytes = readArtwork(path)
                            if (bytes != null && bytes.size < 2000000) {
                                Log.d("Migration", "bytes is: ${bytes.size}")
                                val file = File(coverPath)
                                file.writeBytes(bytes)
                            }
                        } catch (e: Exception) {
                        }
                    }
                }
                response.success(Ok)
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

    private fun readArtwork(path: String): ByteArray? {
        try {
            val fileSize = File(path).length()
            val sizeInMb = fileSize / (1024.0 * 1024)
            if (sizeInMb < 30) {
                val mp3file = Mp3File(path)
                if (mp3file.hasId3v2Tag()) {
                    return mp3file.id3v2Tag.albumImage
                }
            }
        } catch (e: Exception) {
        } catch (o: OutOfMemoryError) {
        }
        return null
    }

    private fun readTags(path: String): Map<String, String> {
        val map: MutableMap<String, String> = HashMap()
        map["path"] = path
//        Log.i("MigrationKotlin", "Begin $path")
        try {
            val fileSize = File(path).length()
            val sizeInMb = fileSize / (1024.0 * 1024)
            if (sizeInMb < 30) {
                val mp3file = Mp3File(path)
                if (mp3file.hasId3v1Tag()) {
                    val id3v1Tag = mp3file.id3v1Tag
                    if (id3v1Tag.artist != null && id3v1Tag.artist.trim().isNotEmpty()) {
                        map["artist"] = id3v1Tag.artist
                    }
                    if (id3v1Tag.album != null && id3v1Tag.album.trim().isNotEmpty()) {
                        map["album"] = id3v1Tag.album
                    }

                }
                if (mp3file.hasId3v2Tag()) {
                    val id3v2Tag: ID3v2 = mp3file.id3v2Tag
                    if (id3v2Tag.artist != null && id3v2Tag.artist.trim().isNotEmpty()) {
                        map["artist"] = id3v2Tag.artist
                    }
                    if (id3v2Tag.album != null && id3v2Tag.album.trim().isNotEmpty()) {
                        map["album"] = id3v2Tag.album
                    }
                }
            }
        } catch (e: Exception) {
        } catch (o: OutOfMemoryError) {
        }
//        Log.i("MigrationKotlin", "End $path")
        return map

    }


    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    }
}

package com.suamusica.migration;

import android.content.Context
import android.util.Log
import androidx.annotation.NonNull
import com.suamusica.room.database.QueryDatabase
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.async
import kotlinx.coroutines.runBlocking
import org.jaudiotagger.audio.AudioFile
import org.jaudiotagger.audio.AudioFileIO
import org.jaudiotagger.tag.FieldKey
import org.jaudiotagger.tag.Tag
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
        const val EXTRACT_ID3 = "extractId3"

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

        when (call.method) {
            REQUEST_DOWNLOAD_CONTENT -> {
                val result = GlobalScope.async {
                    QueryDatabase.getInstance(context)?.let { db ->
                        val medias = db.offlineMediaDao().getMedias()?.flatMap {
                            it.toMigration()
                        } ?: listOf()

                        val playlists = db.offlinePlaylistDao().getPlaylists()?.filter { it ->
                            it.id != null && it.name != null && it.name.length > 0 && it.artistName != null && it.artistName.length > 0 && it.ownerId != null && it.ownerId.length > 0 && it.ownerId.toInt() > 0 && medias.firstOrNull { media ->
                                media.containsKey("playlist_id") && media["playlist_id"] as String == it.id
                            } != null
                        }?.map {
                            Log.d("Migration", "Migrating Playlist!! ${it}")
                            it.toMigration(isVerified =
                            medias.first { media -> media.containsKey("playlist_id") && media["playlist_id"] as String == it.id } != null
                            )
                        } ?: listOf()


                        val albums = db.offlineAlbumDao().getAlbums()?.filter { it ->
                            it.id != null && it.name != null && it.name.length > 0 && it.artistName != null && it.artistName.length > 0 && it.ownerId != null && it.ownerId.length > 0 && it.ownerId.toInt() > 0 && medias.firstOrNull { media ->
                                media.containsKey("album_id") && media["album_id"] as String == it.id
                            } != null
                        }?.map {
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
                runBlocking {
                    result.await()
                    response.success(Ok)
                }
                return
            }
            EXTRACT_ID3 -> {
                val result = GlobalScope.async {
                    QueryDatabase.getInstance(context)?.let { db ->
                        return@let db.offlineMediaDao().getMedias()?.flatMap {
                            listOf(mapOf(it.filePath to readTags(it.filePath)))
                        } ?: listOf()
                    } ?: run {
                        return@run listOf<Map<String, Map<String, String>>>()
                    }
                }
                runBlocking {
                    response.success(result.await())
                }
            }
            EXTRACT_ART -> {
                GlobalScope.async {
                    val items = call.argument<List<HashMap<String, String>>>("items")
                    for (item in items.orEmpty()) {
                        val path = item["path"] as String
                        val coverPath = item["coverPath"] as String
                        val bytes = readArtwork(path)
                        if (bytes != null) {
                            val file = File(coverPath)
                            file.writeBytes(bytes)
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
            val mp3File = File(path)
            val audioFile: AudioFile = AudioFileIO.read(mp3File)
            return audioFile.tag.firstArtwork.binaryData
        } catch (e: Exception) {
//      e.printStackTrace()
        }
        return null
    }

    private fun readTags(path: String): Map<String, String> {
      val map: MutableMap<String, String> = HashMap()
        try {
            val mp3File = File(path)
            val audioFile = AudioFileIO.read(mp3File)
            val tag: Tag = audioFile.tag
            map["title"] = tag.getFirst(FieldKey.TITLE)
            map["artist"] = tag.getFirst(FieldKey.ARTIST)
            map["genre"] = tag.getFirst(FieldKey.GENRE)
            map["trackNumber"] = tag.getFirst(FieldKey.TRACK)
            map["trackTotal"] = tag.getFirst(FieldKey.TRACK_TOTAL)
            map["discNumber"] = tag.getFirst(FieldKey.DISC_NO)
            map["discTotal"] = tag.getFirst(FieldKey.DISC_TOTAL)
            map["lyrics"] = tag.getFirst(FieldKey.LYRICS)
            map["comment"] = tag.getFirst(FieldKey.COMMENT)
            map["album"] = tag.getFirst(FieldKey.ALBUM)
            map["albumArtist"] = tag.getFirst(FieldKey.ALBUM_ARTIST)
            map["year"] = tag.getFirst(FieldKey.YEAR)
        } catch (e: Exception) {
            // e.printStackTrace()
        }
      return map
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    }
}

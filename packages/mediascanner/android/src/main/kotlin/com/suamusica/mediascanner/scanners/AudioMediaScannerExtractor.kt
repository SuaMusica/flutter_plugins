package com.suamusica.mediascanner.scanners

import android.annotation.TargetApi
import android.content.ContentUris
import android.content.Context
import android.database.Cursor
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Build
import android.provider.MediaStore.Audio
import com.suamusica.mediascanner.input.MediaType
import com.suamusica.mediascanner.model.Album
import com.suamusica.mediascanner.output.ScannedMediaOutput
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import timber.log.Timber
import com.mpatric.mp3agic.Mp3File;
import com.suamusica.mediascanner.db.ScannedMediaRepository
import java.util.Locale.getDefault

class AudioMediaScannerExtractor(private val context: Context) : MediaScannerExtractor {
    private val rootPaths = mutableListOf<String>()
    override val mediaType: MediaType = MediaType.AUDIO

    override val uri = Audio.Media.EXTERNAL_CONTENT_URI!!

    override val columns = arrayOf(
            Audio.Media.TITLE,
            Audio.Media.TRACK,
            Audio.Media.ARTIST,
            Audio.Media.ALBUM_ID,
            Audio.Media.ALBUM,
            Audio.Media.DATA,
            Audio.Media.DATE_ADDED,
            Audio.Media.DATE_MODIFIED,
            Audio.Media._ID,
            Audio.Media.DISPLAY_NAME,
            Audio.Media.MIME_TYPE
    )

    override val selection: String = Audio.Media.IS_MUSIC + " != 0"

    override val selectionArgs: Array<String> = arrayOf()

    override val sortOrder: String? = null

    private val albumColumns = arrayOf(
            Audio.Albums._ID,
            Audio.Albums.ALBUM_ART
    )

    private val albumCache = mutableMapOf<Long, Album?>()

    private fun getSuaMusicaId(path: String): Long? {
        val id = path.substringBeforeLast(".").split("_").last().toLongOrNull()
        if (id != null && id > 1000) {
            return id
        }
        return null
    }

    @TargetApi(Build.VERSION_CODES.KITKAT)
    override fun getScannedMediaFromCursor(cursor: Cursor,
                                           scannedMediaRepository: ScannedMediaRepository?): ScannedMediaOutput? {
        // cursor.columnNames.forEach {
        //     Timber.d("Field $it: [${getString(cursor, it)}]")
        // }

        val androidAlbumId = getLong(cursor, Audio.Media.ALBUM_ID)
        var albumId = androidAlbumId
        var playlistId = -1L;

        var musicId = getLong(cursor, Audio.Media._ID) * -1;
        val path = getString(cursor, Audio.Media.DATA)

        if(!path.lowercase(getDefault()).endsWith(".mp3")){
            return null
        }
        getSuaMusicaId(path)?.let {
            musicId = it
        }


        scannedMediaRepository?.let {
            if (rootPaths.isEmpty()){
                val appsDir = context.getExternalFilesDirs(null)
                appsDir.forEach { appDir ->
                    val absPath = appDir.absolutePath
                    val index = absPath.indexOf("/Android/")
                    if (index > 0) {
                        val rootPath = absPath.substring(0, index)
                        rootPaths.add(rootPath)
                    }
                }
            }
            var workPath = path
            if (musicId > 0) {
                for (rootPath in rootPaths ) {
                    if (workPath.startsWith(rootPath)) {
                        workPath = workPath.replace(rootPath, "")
                        break
                    }
                }
            }
            if ( it.mediaExists(mediaId = musicId, mediaPath = workPath)) {
                it.markMediaAsPresent(mediaId = musicId)
                Timber.d("MediaScanner: Found that mediaId: $musicId with path $path was already processed")
                return null
            } else {
                Timber.d("MediaScanner: mediaId: $musicId with path $path was not processed")
            }
        }

        var artist = getString(cursor, Audio.Media.ARTIST) {
            getString(cursor, Audio.Media.COMPOSER) {
                UNKNOWN_ARTIST
            }
        }
        artist = if (artist.trim().isBlank() || artist.contains("unknown", ignoreCase = true)) UNKNOWN_ARTIST else artist

        var titleFromId3: String? = null
        try {
            val mp3file = Mp3File(path)
            if (mp3file.hasId3v2Tag()) {
                val id3v2Tag = mp3file.id3v2Tag

                id3v2Tag.title?.takeIf { it.isNotBlank() }?.let { titleFromId3 = it }

                var url = id3v2Tag.url
                if (url != null && url.isNotEmpty()) {
                    val uri = Uri.parse(url)
                    uri.getQueryParameter("playlistId")?.let { value ->
                        playlistId = value.toLong()
                    }
                    uri.getQueryParameter("albumId")?.let { value ->
                        albumId = value.toLong()
                    }
                    uri.getQueryParameter("musicId")?.let { value ->
                        musicId = value.toLong()
                    }
                }

                if (artist == UNKNOWN_ARTIST && id3v2Tag.albumArtist.isNotEmpty()) {
                    artist = id3v2Tag.albumArtist
                }
            }
        } catch (e: Throwable) {
            if (e is java.io.FileNotFoundException) {
                Timber.e(e, "File does not exist.. $path")
                return null
            }
            Timber.e(e, "Failed to get ID3 tags. Ignoring...")
        }

        var displayTitle = getString(cursor, Audio.Media.TITLE) { getString(cursor, Audio.Media.DISPLAY_NAME) }
        if (displayTitle.isNotBlank() && displayTitle.startsWith("\uFEFF")) {
            displayTitle = displayTitle.removePrefix("\uFEFF")
        }
        titleFromId3?.let { displayTitle = it }
        val title = displayTitle.ifBlank { path.substringAfterLast('/').substringBeforeLast('.') }

        return ScannedMediaOutput(
                mediaId = musicId,
                title = title,
                artist = artist,
                albumId = albumId,
                playlistId = playlistId,
                album = getString(cursor, Audio.Media.ALBUM) { getString(cursor, "_description") },
                track = getString(cursor, Audio.Media.TRACK),
                path = path,
                albumCoverPath = getAlbumById(albumId, path)?.coverPath
                    ?: createCover(albumId, path),
                createdAt = getLong(cursor, Audio.Media.DATE_ADDED),
                updatedAt = getLong(cursor, Audio.Media.DATE_MODIFIED)
        )
    }

    private fun getLong(cursor: Cursor, columnName: String, defaultValue: () -> Long = { 0 }): Long {
        return try {
            // Timber.d("Getting the Column $columnName...")
            val value = cursor.getLongByColumnName(columnName)
            // Timber.d("Got value [$value] for Column $columnName!")
            value
        } catch (e: Throwable) {
            Timber.e(e, "Failed to get value for column $columnName using default [$defaultValue]")
            defaultValue.invoke()
        }
    }

    private fun getString(cursor: Cursor, columnName: String, defaultValue: () -> String = { "" }): String {
        return try {
            // Timber.d("Getting the Column $columnName...")
            val value = cursor.getStringByColumnName(columnName)
            // Timber.d("Got value $value for Column $columnName!")
            value
        } catch (e: Throwable) {
            Timber.e(e, "Failed to get value for column $columnName using default $defaultValue")
            defaultValue.invoke()
        }
    }

    @Synchronized
    private fun getAlbumById(albumId: Long, filePath: String): Album? {
        if (albumId <= 0) {
            albumCache[albumId] = null
        }

        if (albumCache[albumId] != null) {
            // Timber.d("Album $albumId is present in cache")
            return albumCache[albumId]
        }

        // Timber.d("Find album on android Media Store (albumId=$albumId)")

        val cursor = context.contentResolver.query(
                Audio.Albums.EXTERNAL_CONTENT_URI,
                albumColumns,
                Audio.Albums._ID + "=?",
                arrayOf(albumId.toString()),
                null
        )

        cursor?.use {
            if (it.moveToFirst()) {
                // Timber.d("Album $albumId founded.")

                var coverPath = getString(it, Audio.Albums.ALBUM_ART)

                if (coverPath.isBlank() && Build.VERSION.SDK_INT > 28) {
                    // Timber.d("Cover path is not present in MediaStore for albumId: $albumId")
                    coverPath = createCover(albumId, filePath)
                }

                return Album(coverPath = coverPath).also { album ->
                    albumCache[albumId] = album
                }
            }
        }

        // Timber.d("Album $albumId not founded.")
        albumCache[albumId] = null
        return null
    }

    private fun createCover(albumId: Long, filePath: String): String {
        // Timber.d("Trying create Album $albumId for file: $filePath")
        if (albumId < 5000 || albumId > 10000000) {
            return ""
        }

        var coverPath = "https://suamusica.com.br/cover/cd/$albumId"
        try {
            val mmr = MediaMetadataRetriever()
            mmr.setDataSource(filePath)
            mmr.embeddedPicture?.let { coverBytes ->
                val appRoot = context.filesDir.parentFile
                val appFlutterDir = File(appRoot, "app_flutter")
                val coversDir = File(appFlutterDir, "covers")
                if (!coversDir.exists()) {
                    coversDir.mkdirs()
                }

                val outputFile = File(coversDir, "$albumId.webp")
                if (outputFile.exists()) {
                    outputFile.delete()
                }

                try {
                    val bitmap = BitmapFactory.decodeByteArray(coverBytes, 0, coverBytes.size)
                    if (bitmap != null) {
                        FileOutputStream(outputFile).use { fos ->
                            bitmap.compress(Bitmap.CompressFormat.WEBP, 90, fos)
                        }
                    }
                } catch (e: IOException) {
                    Timber.e(e, "Error")
                    return ""
                }
                coverPath = outputFile.path
                // Timber.d("cover created: $coverPath")
            } ?: Timber.d("no has embeddedPicture.")
        } catch (t: Throwable) {
            return ""
            Timber.e(t, "Error")
        }

        return coverPath
    }

    override fun delete(id: Long) {
        context.contentResolver.delete(
                Audio.Media.EXTERNAL_CONTENT_URI,
                Audio.Albums._ID + "=?",
                arrayOf(id.toString())
        )
    }

    companion object {
        const val UNKNOWN_ARTIST = "Artista Desconhecido"
    }
}
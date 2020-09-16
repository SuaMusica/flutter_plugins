package com.suamusica.mediascanner.scanners

import android.content.Context
import android.database.Cursor
import android.media.MediaMetadataRetriever
import android.os.Build
import android.provider.MediaStore.Audio
import com.suamusica.mediascanner.input.MediaType
import com.suamusica.mediascanner.model.Album
import com.suamusica.mediascanner.output.ScannedMediaOutput
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import timber.log.Timber

class AudioMediaScannerExtractor(private val context: Context) : MediaScannerExtractor {

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
            Audio.Media._ID
    )

    override val selection: String = Audio.Media.IS_MUSIC + " != 0"

    override val selectionArgs: Array<String> = arrayOf()

    override val sortOrder: String? = null

    private val albumColumns = arrayOf(
            Audio.Albums._ID,
            Audio.Albums.ALBUM_ART
    )

    private val albumCache = mutableMapOf<Long, Album?>()

    private fun isSuaMusicaMusic(path: String): Boolean {
        return path.substringBeforeLast(".").split("_").last().toIntOrNull() != null
    }

    override fun getScannedMediaFromCursor(cursor: Cursor): ScannedMediaOutput? {
        cursor.columnNames.forEach {
            Timber.d("$it: [${getString(cursor, it, "")}]")
        }
        val albumId = getLong(cursor, Audio.Media.ALBUM_ID, 0)
        val path = getString(cursor, Audio.Media.DATA, "")
        if (isSuaMusicaMusic(path)) {
            return null
        }
        return ScannedMediaOutput(
                mediaId = getLong(cursor, Audio.Media._ID, 0),
                title = getString(cursor, Audio.Media.TITLE,
                        getString(cursor, Audio.Media.DISPLAY_NAME, "")),
                artist = getString(cursor, Audio.Media.ARTIST,
                        getString(cursor, Audio.Media.COMPOSER, "")),
                albumId = albumId,
                album = getString(cursor, Audio.Media.ALBUM,
                        getString(cursor, "_description", "")),
                track = getString(cursor, Audio.Media.TRACK, ""),
                path = path,
                albumCoverPath = getAlbumById(albumId, path)?.coverPath ?: "",
                createdAt = getLong(cursor, Audio.Media.DATE_ADDED, 0),
                updatedAt = getLong(cursor, Audio.Media.DATE_MODIFIED, 0)
        )
    }

    private fun getLong(cursor: Cursor, columnName: String, defaultValue: Long): Long {
        return try {
            Timber.d("Getting the Column $columnName...")
            val value = cursor.getLongByColumnName(columnName)
            Timber.d("Got value [$value] for Column $columnName!")
            value
        } catch (e: Throwable) {
            Timber.e(e,"Failed to get value for column $columnName using default [$defaultValue]")
            defaultValue
        }
    }

    private fun getString(cursor: Cursor, columnName: String, defaultValue: String): String {
        return try {
            Timber.d("Getting the Column $columnName...")
            val value = cursor.getStringByColumnName(columnName)
            Timber.d("Got value $value for Column $columnName!")
            value
        } catch (e: Throwable) {
            Timber.e(e,"Failed to get value for column $columnName using default $defaultValue")
            defaultValue
        }
    }

    @Synchronized
    private fun getAlbumById(albumId: Long, filePath: String): Album? {
        if (albumId <= 0) {
            albumCache[albumId] = null
        }

        if (albumCache.containsKey(albumId)) {
            Timber.d("Album $albumId is present in cache")
            return albumCache[albumId]
        }

        Timber.d("Find album on android Media Store (albumId=$albumId)")

        val cursor = context.contentResolver.query(
                Audio.Albums.EXTERNAL_CONTENT_URI,
                albumColumns,
                Audio.Albums._ID + "=?",
                arrayOf(albumId.toString()),
                null
        )

        cursor?.use {
            if (it.moveToFirst()) {
                Timber.d("Album $albumId founded.")

                var coverPath = getString(it, Audio.Albums.ALBUM_ART, "")

                if (coverPath.isBlank() && Build.VERSION.SDK_INT > 28) {
                    Timber.d("Cover path is not present in MediaStore for albumId: $albumId")
                    coverPath = createCover(albumId, filePath)
                }

                return Album(coverPath = coverPath).also { album ->
                    albumCache[albumId] = album
                }
            }
        }

        Timber.d("Album $albumId not founded.")
        albumCache[albumId] = null
        return null
    }

    private fun createCover(albumId: Long, filePath: String): String {
        Timber.d("Trying create Album $albumId for file: $filePath")
        var coverPath = ""
        try {
            val mmr = MediaMetadataRetriever()
            mmr.setDataSource(filePath)
            mmr.embeddedPicture?.let {
                val cacheDir = context.cacheDir
                Timber.d("Creating cover on cache dir: $cacheDir")
                val outputFile = File.createTempFile("sm_$albumId", ".jpg", cacheDir)

                if (outputFile.exists())
                    outputFile.delete()

                val fos = FileOutputStream(outputFile.path)
                try {
                    fos.write(it)
                    fos.close()
                } catch (e: IOException) {
                    Timber.e(e,"Error")
                }
                coverPath = outputFile.path
                Timber.d("cover created: $coverPath")
            } ?: Timber.d("no has embeddedPicture.")
        } catch (t: Throwable) {
            Timber.e(t,"Error")
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
}
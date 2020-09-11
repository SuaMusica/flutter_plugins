package com.suamusica.mediascanner.scanners

import android.content.Context
import android.database.Cursor
import android.media.MediaMetadataRetriever
import android.provider.MediaStore.Audio
import com.suamusica.mediascanner.input.MediaType
import com.suamusica.mediascanner.model.Album
import com.suamusica.mediascanner.output.ScannedMediaOutput
import timber.log.Timber
import java.io.File
import java.io.FileOutputStream
import java.io.IOException

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

    override fun getScannedMediaFromCursor(cursor: Cursor): ScannedMediaOutput {
        val albumId = cursor.getLongByColumnName(Audio.Media.ALBUM_ID)
        val path = cursor.getStringByColumnName(Audio.Media.DATA)
        return ScannedMediaOutput(
                mediaId = cursor.getLongByColumnName(Audio.Media._ID),
                title = cursor.getStringByColumnName(Audio.Media.TITLE),
                artist = cursor.getStringByColumnName(Audio.Media.ARTIST),
                albumId = albumId,
                album = cursor.getStringByColumnName(Audio.Media.ALBUM),
                track = cursor.getStringByColumnName(Audio.Media.TRACK),
                path = path,
                albumCoverPath = getAlbumById(albumId, path)?.coverPath ?: "",
                createdAt = cursor.getLongByColumnName(Audio.Media.DATE_ADDED),
                updatedAt = cursor.getLongByColumnName(Audio.Media.DATE_MODIFIED)
        )
    }

    @Synchronized
    private fun getAlbumById(albumId: Long, filePath: String): Album? {

        if (albumId <= 0) {
            albumCache[albumId] = null
        }

        if (albumCache.containsKey(albumId)) {
            Timber.d("Album %s is present in cache", albumId)
            return albumCache[albumId]
        }

        Timber.d("Find album on android Media Store (albumId=%s)", albumId)

        val cursor = context.contentResolver.query(
                Audio.Albums.EXTERNAL_CONTENT_URI,
                albumColumns,
                Audio.Albums._ID + "=?",
                arrayOf(albumId.toString()),
                null
        )

        cursor?.use {
            if (it.moveToFirst()) {

                Timber.d("Album %s founded.", albumId)

                var coverPath = it.getStringByColumnName(Audio.Albums.ALBUM_ART)

                if (coverPath.isBlank()) {
                    Timber.d("Cover path is not present in MediaStore for albumId: %s", albumId)
                    coverPath = createCover(albumId, filePath)
                }

                return Album(coverPath = coverPath).also { album ->
                    albumCache[albumId] = album
                }
            }
        }

        Timber.d("Album %s not founded.", albumId)
        albumCache[albumId] = null
        return null
    }

    private fun createCover(albumId: Long, filePath: String): String {
        Timber.d("Trying create Album %s for file: %s", albumId, filePath)
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
                    Timber.e(e)
                }
                coverPath = outputFile.path
                Timber.d("cover created: $coverPath")
            } ?: Timber.d("no has embeddedPicture.")
        } catch (t: Throwable) {
            Timber.e(t)
        }

        return coverPath
    }
}
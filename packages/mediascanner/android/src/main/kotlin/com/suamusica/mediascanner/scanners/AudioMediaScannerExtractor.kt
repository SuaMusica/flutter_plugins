package com.suamusica.mediascanner.scanners

import android.content.Context
import android.database.Cursor
import android.provider.MediaStore.Audio
import com.suamusica.mediascanner.input.MediaType
import com.suamusica.mediascanner.model.Album
import com.suamusica.mediascanner.output.ScannedMediaOutput
import com.suamusica.mediascanner.scanners.columns.MediaStoreAlbumConstants
import timber.log.Timber

class AudioMediaScannerExtractor(private val context: Context,
                                 private val albumConstants: MediaStoreAlbumConstants = MediaStoreAlbumConstants.get()) : MediaScannerExtractor {

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

    private val albumCache = mutableMapOf<Int, Album?>()

    override fun getScannedMediaFromCursor(cursor: Cursor): ScannedMediaOutput {
        val albumId = cursor.getIntByColumnName(Audio.Media.ALBUM_ID)
        return ScannedMediaOutput(
                mediaId = cursor.getIntByColumnName(Audio.Media._ID),
                title = cursor.getStringByColumnName(Audio.Media.TITLE),
                artist = cursor.getStringByColumnName(Audio.Media.ARTIST),
                albumId = albumId,
                album = cursor.getStringByColumnName(Audio.Media.ALBUM),
                track = cursor.getStringByColumnName(Audio.Media.TRACK),
                path = cursor.getStringByColumnName(Audio.Media.DATA),
                albumCoverPath = getAlbumById(albumId)?.coverPath ?: "",
                createdAt = cursor.getLongByColumnName(Audio.Media.DATE_ADDED),
                updatedAt = cursor.getLongByColumnName(Audio.Media.DATE_MODIFIED)
        )
    }

    @Synchronized
    private fun getAlbumById(albumId: Int): Album? {

        if (albumCache.containsKey(albumId)) {
            Timber.d("Album %s is present in cache", albumId)
            return albumCache[albumId]
        }

        Timber.d("Find album on android Media Store (albumId=%s)", albumId)

        Timber.d("Albums columns: %s", albumConstants.albumId)

        val cursor = context.contentResolver.query(
                albumConstants.uri,
                albumConstants.columns,
                albumConstants.albumId + "=?",
                arrayOf(albumId.toString()),
                null
        )

        cursor?.use {
            if (it.moveToFirst()) {
                Timber.d("Album %s founded.", albumId)
                return Album(coverPath = it.getStringByColumnName(albumConstants.albumArt)).also { album ->
                    albumCache[albumId] = album
                }
            }
        }

        Timber.d("Album %s not founded.", albumId)
        albumCache[albumId] = null
        return null
    }
}
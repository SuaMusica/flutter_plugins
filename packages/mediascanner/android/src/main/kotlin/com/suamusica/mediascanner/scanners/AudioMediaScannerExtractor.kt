package com.suamusica.mediascanner.scanners

import android.content.Context
import android.database.Cursor
import android.provider.MediaStore.Audio
import com.suamusica.mediascanner.input.MediaType
import com.suamusica.mediascanner.output.ScannedMediaOutput
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
            Audio.Media._ID
    )

    override val selection: String = Audio.Media.IS_MUSIC + " != 0"

    override val selectionArgs: Array<String> = arrayOf()

    override val sortOrder: String? = null

    private val albumColumns = arrayOf(
            Audio.Albums._ID,
            Audio.Albums.ALBUM_ART
    )

    override fun getScannedMediaFromCursor(cursor: Cursor): ScannedMediaOutput {
        return ScannedMediaOutput(
                title = cursor.getStringByColumnName(Audio.Media.TITLE),
                artist = cursor.getStringByColumnName(Audio.Media.ARTIST),
                album = cursor.getStringByColumnName(Audio.Media.ALBUM),
                track = cursor.getStringByColumnName(Audio.Media.TRACK),
                path = cursor.getStringByColumnName(Audio.Media.DATA),
                albumCoverPath = getAlbumCoverPathByAlbumId(cursor.getIntByColumnName(Audio.Media.ALBUM_ID))
        )
    }

    private fun getAlbumCoverPathByAlbumId(albumId: Int): String {
        Timber.v("getAlbumPictureById(albumId=%s)", albumId);

        val cursor = context.contentResolver.query(
                Audio.Albums.EXTERNAL_CONTENT_URI,
                albumColumns,
                Audio.Albums._ID + "=?",
                arrayOf(albumId.toString()),
                null
        )

        cursor?.use {
            if (it.moveToFirst()) {
                return it.getStringByColumnName(Audio.Albums.ALBUM_ART)
            }
        }

        return ""
    }
}
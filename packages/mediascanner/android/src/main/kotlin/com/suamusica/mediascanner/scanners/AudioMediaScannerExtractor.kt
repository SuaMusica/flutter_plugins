package com.suamusica.mediascanner.scanners

import android.database.Cursor
import android.provider.MediaStore.Audio.Media
import com.suamusica.mediascanner.input.MediaType
import com.suamusica.mediascanner.output.ScannedMediaOutput

class AudioMediaScannerExtractor : MediaScannerExtractor {

    override val mediaType: MediaType = MediaType.AUDIO

    override val uri = Media.EXTERNAL_CONTENT_URI!!

    override val columns = arrayOf(
            Media.TITLE,
            Media.ARTIST,
            Media.ALBUM,
            Media.DATA,
            Media._ID
    )

    override fun getScannedMediaFromCursor(cursor: Cursor): ScannedMediaOutput {
        return ScannedMediaOutput(
                title = cursor.getStringByColumnName(Media.TITLE),
                artist = cursor.getStringByColumnName(Media.ARTIST),
                album = cursor.getStringByColumnName(Media.ALBUM),
                path = cursor.getStringByColumnName(Media.DATA)
        )
    }
}
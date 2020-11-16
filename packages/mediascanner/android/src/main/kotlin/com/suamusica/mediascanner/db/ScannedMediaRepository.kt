package com.suamusica.mediascanner.db

import android.database.Cursor

class ScannedMediaRepository(dbHelper: ScannedMediaDbHelper) {
    private val dbHelper: ScannedMediaDbHelper = dbHelper

    fun mediaExists(mediaId: Long, mediaPath: String): Boolean {
        val db = dbHelper.readableDatabase
        var cursor: Cursor? = null
        try {
            cursor = db.query(
                    SCANNED_MEDIA_TABLE,
                    arrayOf(MEDIA_ID_FIELD),
                    SELECTION,
                    arrayOf(mediaId.toString(), mediaPath),
                    null,
                    null,
                    null
            )

            return cursor?.moveToNext() ?: false
        } finally {
            cursor?.close()
        }
    }

    companion object {
        val SCANNED_MEDIA_TABLE = "scanned_media"
        val MEDIA_ID_FIELD = "media_id"
        val PATH_FIELD = "path"
        val SELECTION = "${SCANNED_MEDIA_TABLE}.${MEDIA_ID_FIELD} = ? AND ${SCANNED_MEDIA_TABLE}.\"${PATH_FIELD}\" = ?"
    }
}
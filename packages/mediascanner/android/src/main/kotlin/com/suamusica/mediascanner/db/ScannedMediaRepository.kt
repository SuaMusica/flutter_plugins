package com.suamusica.mediascanner.db

import android.database.Cursor
import android.content.ContentValues
import timber.log.Timber

class ScannedMediaRepository(dbHelper: ScannedMediaDbHelper) {
    private val dbHelper: ScannedMediaDbHelper = dbHelper
//Download/kozah
    fun mediaExists(mediaId: Long, mediaPath: String): Boolean {
        return if (mediaId < 0) {
            externalMediaExists(mediaId, mediaPath)
        } else {
            internalMediaExists(mediaId, mediaPath)
        }
    }

    fun markMediaAsPresent(mediaId: Long): Boolean {
        val db = dbHelper.writableDatabase
        try {
            val values = ContentValues().apply {
                put("still_present", "1")
            }
            val count = db.update(
                    OFFLINE_MEDIA_TABLE,
                    values,
                    "id = ?",
                    arrayOf(mediaId.toString())
            )
            Timber.d("Updated media ${mediaId} as present")
            return count > 0
        } catch (t: Throwable) {
            Timber.e(t, "Error")
            return false
        }
    }


    private fun externalMediaExists(mediaId: Long, mediaPath: String): Boolean {
        val db = dbHelper.readableDatabase
        var cursor: Cursor? = null
        try {
            cursor = db.query(
                    SCANNED_MEDIA_TABLE,
                    arrayOf(MEDIA_ID_FIELD),
                    SCANNED_MEDIA_SELECTION,
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

    private fun internalMediaExists(mediaId: Long, mediaPath: String): Boolean {
        val db = dbHelper.readableDatabase
        var cursor: Cursor? = null
        try {
            cursor = db.query(
                    OFFLINE_MEDIA_TABLE,
                    arrayOf(OFFLINE_MEDIA_ID_FIELD),
                    OFFLINE_MEDIA_SELECTION,
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
        private const val SCANNED_MEDIA_TABLE = "scanned_media"
        private const val MEDIA_ID_FIELD = "media_id"
        private const val PATH_FIELD = "path"
        private const val SCANNED_MEDIA_SELECTION = "${SCANNED_MEDIA_TABLE}.${MEDIA_ID_FIELD} = ? AND ${SCANNED_MEDIA_TABLE}.\"${PATH_FIELD}\" = ?"

        private const val OFFLINE_MEDIA_TABLE = "offline_media_v2"
        private const val OFFLINE_MEDIA_ID_FIELD = "id"
        private const val OFFLINE_MEDIA_LOCAL_PATH_FIELD = "local_path"
        private const val OFFLINE_MEDIA_SELECTION = "${OFFLINE_MEDIA_TABLE}.${OFFLINE_MEDIA_ID_FIELD} = ? AND ${OFFLINE_MEDIA_TABLE}.\"${OFFLINE_MEDIA_LOCAL_PATH_FIELD}\" = ?"
    }
}
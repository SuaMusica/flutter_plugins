package com.suamusica.mediascanner.scanners

import android.database.Cursor
import android.net.Uri
import com.suamusica.mediascanner.input.MediaType
import com.suamusica.mediascanner.output.ScannedMediaOutput

interface MediaScannerExtractor {
    val mediaType: MediaType
    val uri: Uri
    val columns: Array<String>
    val selection: String
    val selectionArgs: Array<String>
    val sortOrder: String?

    fun getScannedMediaFromCursor(cursor: Cursor): ScannedMediaOutput

    fun Cursor.getStringByColumnName(columnName: String): String =
            this.getString(this.getColumnIndex(columnName)) ?: ""

    fun Cursor.getIntByColumnName(columnName: String): Int =
            this.getInt(this.getColumnIndex(columnName))

    fun Cursor.getLongByColumnName(columnName: String): Long =
            this.getLong(this.getColumnIndex(columnName))

    fun delete(id: Long)
}
package com.suamusica.mediascanner

import android.annotation.SuppressLint
import android.content.ContentResolver
import android.content.ContentUris
import android.content.Context
import com.suamusica.mediascanner.input.DeleteMediaMethodInput
import com.suamusica.mediascanner.input.MediaType
import com.suamusica.mediascanner.input.ScanMediaMethodInput
import com.suamusica.mediascanner.output.ScannedMediaOutput
import com.suamusica.mediascanner.scanners.AudioMediaScannerExtractor
import com.suamusica.mediascanner.scanners.MediaScannerExtractor
import timber.log.Timber
import java.io.File
import java.util.concurrent.Executor
import java.util.concurrent.Executors
import android.provider.DocumentsContract
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.database.Cursor
import android.util.Log

class MediaScanner(
        private val callback: ChannelCallback,
        private val context: Context,
        private val executor: Executor = Executors.newSingleThreadExecutor(),
        private val contentResolver: ContentResolver = context.contentResolver,
        private val mediaScannerExtractors: List<MediaScannerExtractor> = listOf(
                AudioMediaScannerExtractor(context)
        )
) {

    fun deleteFromMediaId(input: DeleteMediaMethodInput) {

        executor.execute {

            val file = File(input.fullPath)
            if (file.exists()) {
                file.delete()
                val parentFile = file.parentFile
                if (parentFile.isDirectory && parentFile.listFiles().isNullOrEmpty()) {
                    val deleteParent = parentFile.delete()
                    Timber.d("Delete: (parentFile: ${file.parent}, fileDeleted: $deleteParent)")
                }
            }

            val extractors = mediaScannerExtractors.filter {
                input.mediaType == MediaType.ALL
                        || it.mediaType == input.mediaType
            }

            extractors.forEach { it.delete(input.id) }
        }
    }

    fun read(uri: String) {
        Timber.v("read(%s)", uri)
        executor.execute {
            try {
                readMediaFromAndroidApi(uri)
            } catch (e: Throwable) {
                Timber.e(e)
                callback.onRead(null, e)
            }
        }
    }

    fun scan(input: ScanMediaMethodInput) {
        Timber.v("scan(%s)", input)
        executor.execute {
            try {
                scanMediasFromAndroidApi(input)
            } catch (e: Throwable) {
                Timber.e(e)
                callback.onAllMediaScanned(emptyList())
            }
        }
    }

    @SuppressLint("Recycle")
    private fun readMediaFromAndroidApi(uri: String) {
        val scannedMedia = this.readMediaFromUri(Uri.parse(uri))
        scannedMedia?.let {
            callback.onRead(it, null)
        }
    }

    @SuppressLint("Recycle")
    private fun scanMediasFromAndroidApi(input: ScanMediaMethodInput) {

        val allMediaScanned = mutableListOf<ScannedMediaOutput>()

        val extractors = mediaScannerExtractors.filter {
            input.mediaType == MediaType.ALL
                    || it.mediaType == input.mediaType
        }

        extractors.forEach { extractor ->
            val cursor = contentResolver.query(
                    extractor.uri,
                    extractor.columns,
                    extractor.selection,
                    extractor.selectionArgs,
                    null
            )
            cursor?.use { c ->
                while (c.moveToNext()) {
                    val scannedMedia = extractor.getScannedMediaFromCursor(c)
                    val extension = ".".plus(scannedMedia.path.substringAfterLast("."))
                    input.extensions.find { extension.contains(it) }?.let {
                        allMediaScanned.add(scannedMedia)
                    }
                }
            }
        }

        callback.onAllMediaScanned(allMediaScanned)
    }

    private fun readMediaFromUri(uri: Uri): ScannedMediaOutput? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.KITKAT)
            return null

        // DocumentProvider
        if (DocumentsContract.isDocumentUri(context, uri)) {
            val authority = uri.authority ?: ""
            // ExternalStorageProvider
            if (isExternalStorageDocument(authority)) {
                val docId = DocumentsContract.getDocumentId(uri)
                val split = docId.split(":".toRegex()).dropLastWhile { it.isEmpty() }.toTypedArray()
                val type = split[0]

                if ("primary".equals(type, ignoreCase = true)) {

                } else {
                    val splitDirectory = Environment.getExternalStorageDirectory().toString().split("/".toRegex())
                    if (splitDirectory.size > 1) {

                    }
                }

                return readMediaFromContentProvider(context, uri, null, null)
            } else if (isDownloadsDocument(authority)) {
                val id = DocumentsContract.getDocumentId(uri)
                val contentUri = ContentUris.withAppendedId(
                        Uri.parse("content://downloads/public_downloads"), java.lang.Long.valueOf(id))

                return readMediaFromContentProvider(context, contentUri, null, null)
            } else if (isMediaDocument(authority)) {
                val docId = DocumentsContract.getDocumentId(uri)
                val split = docId.split(":".toRegex()).dropLastWhile { it.isEmpty() }.toTypedArray()
                val type = split[0]

                var contentUri: Uri? = null
                when (type) {
                    "image" -> contentUri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI
                    "video" -> contentUri = MediaStore.Video.Media.EXTERNAL_CONTENT_URI
                    "audio" -> contentUri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
                }

                val selection = "_id=?"
                val selectionArgs = arrayOf(split[1])

                return readMediaFromContentProvider(context, contentUri, selection, selectionArgs)
            }// MediaProvider
            // DownloadsProvider
        } else if ("content".equals(uri.scheme, ignoreCase = true)) {
            return readMediaFromContentProvider(context, uri, null, null)
        } else if ("file".equals(uri.scheme, ignoreCase = true)) {
            return readMediaFromContentProvider(context, uri, null, null)
        }// File
        // MediaStore (and general)

        return null
    }

    private fun readMediaFromContentProvider(context: Context, uri: Uri?, selection: String?,
                                             selectionArgs: Array<String>?): ScannedMediaOutput? {

        var cursor: Cursor? = null

        try {
            cursor = context.contentResolver.query(uri!!, null, selection, selectionArgs, null)
            cursor?.use { c ->
                if (c.moveToNext()) {
                    if (c.getColumnNames().contains("mediaprovider_uri")) {
                        val providerUri = c.getStringByColumnName("mediaprovider_uri")
                        return readMediaFromContentProvider(context, Uri.parse(providerUri), selection, selectionArgs)
                    } else {
                        val scannedMedia = mediaScannerExtractors[0].getScannedMediaFromCursor(c)
                        return scannedMedia
                    }
                }
            }
        } finally {
            cursor?.close()
        }
        return null
    }

    private fun isExternalStorageDocument(authority: String): Boolean = "com.android.externalstorage.documents" == authority

    private fun isDownloadsDocument(authority: String): Boolean = "com.android.providers.downloads.documents" == authority

    private fun isMediaDocument(authority: String): Boolean = "com.android.providers.media.documents" == authority

    fun Cursor.getStringByColumnName(columnName: String): String =
            this.getString(this.getColumnIndex(columnName)) ?: ""
}
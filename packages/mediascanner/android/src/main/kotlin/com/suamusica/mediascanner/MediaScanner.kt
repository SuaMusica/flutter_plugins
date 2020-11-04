package com.suamusica.mediascanner

import android.annotation.SuppressLint
import android.annotation.TargetApi
import android.content.ContentResolver
import android.content.ContentUris
import android.content.Context
import android.database.Cursor
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.StatFs
import android.provider.DocumentsContract
import android.provider.MediaStore
import com.suamusica.mediascanner.input.DeleteMediaMethodInput
import com.suamusica.mediascanner.input.MediaType
import com.suamusica.mediascanner.input.ScanMediaMethodInput
import com.suamusica.mediascanner.output.ScannedMediaOutput
import com.suamusica.mediascanner.scanners.AudioMediaScannerExtractor
import com.suamusica.mediascanner.scanners.MediaScannerExtractor
import timber.log.Timber
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.util.*
import java.util.concurrent.Executor
import java.util.concurrent.Executors
import kotlin.random.Random

class MediaScanner(
        private val callback: ChannelCallback,
        private val context: Context,
        private val scanExecutor: Executor = Executors.newSingleThreadExecutor(),
        private val readExecutor: Executor = Executors.newSingleThreadExecutor(),
        private val contentResolver: ContentResolver = context.contentResolver,
        private val mediaScannerExtractors: List<MediaScannerExtractor> = listOf(
                AudioMediaScannerExtractor(context)
        )
) {

    fun deleteFromMediaId(input: DeleteMediaMethodInput) {

        scanExecutor.execute {

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
        Timber.d("read(%s)", uri)
        readExecutor.execute {
            try {
                readMediaFromAndroidApi(uri)
            } catch (e: Throwable) {
                Timber.e(e)
                callback.onRead(null, e)
            }
        }
    }

    fun scan(input: ScanMediaMethodInput) {
        Timber.d("scan(%s)", input)
        scanExecutor.execute {
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
                    scannedMedia?.let {
                        val extension = ".".plus(scannedMedia.path.substringAfterLast("."))
                        input.extensions.find { extension.contains(it) }?.let {
                            allMediaScanned.add(scannedMedia)
                        }
                    }
                }
            }
        }

        callback.onAllMediaScanned(allMediaScanned)
    }

    private fun getExternalStorageAvailableData(context: Context): ArrayList<HashMap<*, *>>? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.KITKAT)
            return null

        val appsDir = context.getExternalFilesDirs(null)
        val extRootPaths = ArrayList<HashMap<*, *>>()
        for (file in appsDir) {
            val path = file.absolutePath
            val statFs = StatFs(path)
            val availableBytes = statFs.availableBlocksLong * statFs.blockSizeLong
            val storageData = HashMap<String, Any>()
            try {
                val rootPath = file.parentFile.parentFile.parentFile.parentFile.absolutePath
                storageData["rootPath"] = rootPath
            } catch (e: Exception) {
            }
            storageData["path"] = path
            storageData["availableBytes"] = availableBytes
            extRootPaths.add(storageData)
        }
        return extRootPaths
    }

    private fun readMediaFromUri(uri: Uri): ScannedMediaOutput? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.KITKAT)
            return null
        val authority = uri.authority ?: ""

        // DocumentProvider
        when {
            DocumentsContract.isDocumentUri(context, uri) -> {
                // ExternalStorageProvider
                when {
                    isExternalStorageDocument(authority) -> {
                        val docId = DocumentsContract.getDocumentId(uri)
                        val split = docId.split(":".toRegex()).dropLastWhile { it.isEmpty() }.toTypedArray()
                        val type = split[0]

                        var path = ""
                        when {
                            "primary".equals(type, ignoreCase = true) -> {
                                path = "${Environment.getExternalStorageDirectory()}/${split[1]}"
                            }
                            else -> {
                                val storages = getExternalStorageAvailableData(context)
                                var sdPath: String? = null

                                storages?.forEach {
                                    if ((it["rootPath"] as String).contains(type)) {
                                        sdPath = it["rootPath"] as String + "/${docId.toString().substringAfterLast(type).substringAfterLast(":")}"
                                    }
                                }
                                if (sdPath != null) {
                                    path = sdPath as String
                                } else {
                                    val splitDirectory = Environment.getExternalStorageDirectory().toString().split("/".toRegex())
                                    if (splitDirectory.size > 1) {
                                        path = "${splitDirectory[0]}/$type/${split[1]}"
                                    }
                                }
                            }
                        }

                        return readMediaFromMediaMetadataRetriever(path)
                    }
                    isDownloadsDocument(authority) -> {
                        val id = DocumentsContract.getDocumentId(uri)

                        if (id.startsWith("raw:")) {
                            return readMediaFromMediaMetadataRetriever(id.substringAfter("raw:"))
                        }

                        val contentUri = ContentUris.withAppendedId(
                                Uri.parse("content://downloads/public_downloads"), java.lang.Long.valueOf(id))
                        try {
                            return readMediaFromContentProvider(context, contentUri, null, null)
                        } catch (t: Throwable) {
                            var cursor: Cursor? = null
                            try {
                                cursor = context.contentResolver.query(uri, null, null, null, null)

                                cursor?.use { c ->
                                    if (c.moveToNext()) {
                                        val scannedMedia = extractMedia(c, null, null)
                                        if (scannedMedia?.path?.trim()?.isBlank() != false && scannedMedia?.title?.contains(".") != false) {
                                            val newPath = "${Environment.getExternalStorageDirectory()}/Download/${scannedMedia!!.title}"
                                            return readMediaFromMediaMetadataRetriever(newPath)
                                        }

                                    }
                                }
                            } finally {
                                cursor?.close()
                            }
                            return null
                        }
                    }
                    isMediaDocument(authority) -> {
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
                    }
                }// MediaProvider
                // DownloadsProvider
            }
            "content".equals(uri.scheme, ignoreCase = true) -> {
                if(isXiaomi(authority)) {
                    var path = ""
                    if (uri.path.startsWith("/external_files")){
                        path = "${Environment.getExternalStorageDirectory()}/${uri.path.substringAfter("/external_files")}"
                    }
                    if(path.isNotEmpty()) {
                        return readMediaFromMediaMetadataRetriever(path)
                    }
                }
                return readMediaFromContentProvider(context, uri, null, null)
            }
            "file".equals(uri.scheme, ignoreCase = true) -> {
                return readMediaFromContentProvider(context, uri, null, null)
            }
        }// File
        // MediaStore (and general)

        return null
    }

    private fun readMediaFromMediaMetadataRetriever(path: String): ScannedMediaOutput? {
        val mmr = MediaMetadataRetriever()
        mmr.setDataSource(path)

        var artist = mmr.extractMetadata(MediaMetadataRetriever.METADATA_KEY_ARTIST)
                ?: mmr.extractMetadata(MediaMetadataRetriever.METADATA_KEY_ALBUM)
                ?: "Artista Desconhecido"
        if (artist.isBlank() || artist.toLowerCase().contains("unknown")) {
            artist = "Artista Desconhecido"
        }
        val album = mmr.extractMetadata(MediaMetadataRetriever.METADATA_KEY_ALBUM)
                ?: "Album Desconhecido"
        val name =
                mmr.extractMetadata(MediaMetadataRetriever.METADATA_KEY_TITLE)
                        ?: path.split("/").last().substringBeforeLast(".")

        val outputFile = mmr.embeddedPicture?.let { pic -> createCoverImage("$artist-$name", pic) }

        return ScannedMediaOutput(
                mediaId = System.currentTimeMillis() * Random.nextLong(),
                title = name,
                artist = artist,
                albumId = 0,
                playlistId = 0,
                album = album,
                track = "0",
                path = path,
                albumCoverPath = outputFile?.path ?: "",
                createdAt = 0,
                updatedAt = 0
        )

    }

    private fun createCoverImage(fileName: String?, coverByteArray: ByteArray?): File? {
        val outputFile = File.createTempFile(fileName, ".jpg", context.cacheDir)

        if (outputFile.exists())
            outputFile.delete()

        val fos = FileOutputStream(outputFile.path)
        try {
            fos.write(coverByteArray)
            fos.close()
        } catch (e: IOException) {
            Timber.e(e)
        }
        return outputFile
    }

    private fun readMediaFromContentProvider(context: Context, uri: Uri?, selection: String?,
                                             selectionArgs: Array<String>?): ScannedMediaOutput? {

        var cursor: Cursor? = null

        try {
            cursor = context.contentResolver.query(uri!!, null, selection, selectionArgs, null)
            cursor?.use { c ->
                if (c.moveToNext()) {
                    return extractMedia(c, selection, selectionArgs)
                }
            }
        } finally {
            cursor?.close()
        }
        return null
    }

    fun extractMedia(c: Cursor, selection: String?,
                     selectionArgs: Array<String>?): ScannedMediaOutput? {
        return if (c.columnNames.contains(MEDIA_PROVIDER_URI)) {
            val providerUri = c.getStringByColumnName(MEDIA_PROVIDER_URI)
            readMediaFromContentProvider(context, Uri.parse(providerUri), selection, selectionArgs)
                    ?: mediaScannerExtractors[0].getScannedMediaFromCursor(c, false)
        } else {
            mediaScannerExtractors[0].getScannedMediaFromCursor(c, false)
        }

    }

    private fun isExternalStorageDocument(authority: String): Boolean = "com.android.externalstorage.documents" == authority

    private fun isXiaomi(authority: String): Boolean = authority.startsWith("com.mi.android.globalFileexplorer.myprovider",ignoreCase = true)

    private fun isDownloadsDocument(authority: String): Boolean = "com.android.providers.downloads.documents" == authority

    private fun isMediaDocument(authority: String): Boolean = "com.android.providers.media.documents" == authority

    fun Cursor.getStringByColumnName(columnName: String): String =
            this.getString(this.getColumnIndex(columnName)) ?: ""

    companion object {
        const val MEDIA_PROVIDER_URI = "mediaprovider_uri"
    }
}
package com.suamusica.mediascanner

import android.annotation.SuppressLint
import android.content.ContentResolver
import android.content.Context
import com.suamusica.mediascanner.input.MediaType
import com.suamusica.mediascanner.input.ScanMediaMethodInput
import com.suamusica.mediascanner.output.ScannedMediaOutput
import com.suamusica.mediascanner.scanners.AudioMediaScannerExtractor
import com.suamusica.mediascanner.scanners.MediaScannerExtractor
import timber.log.Timber
import java.util.concurrent.Executor
import java.util.concurrent.Executors

class MediaScanner(
        private val callback: ChannelCallback,
        private val context: Context,
        private val executor: Executor = Executors.newSingleThreadExecutor(),
        private val contentResolver: ContentResolver = context.contentResolver,
        private val mediaScannerExtractors: List<MediaScannerExtractor> = listOf(
                AudioMediaScannerExtractor(context)
        )
) {
    fun scan(input: ScanMediaMethodInput) {
        Timber.v("scan(%s)", input)
        executor.execute { scanMediasFromAndroidApi(input) }
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
}
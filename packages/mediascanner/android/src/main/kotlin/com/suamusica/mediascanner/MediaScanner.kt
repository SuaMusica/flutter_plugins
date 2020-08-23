package com.suamusica.mediascanner

import android.content.Context
import com.suamusica.mediascanner.input.ScanMediaMethodInput
import com.suamusica.mediascanner.output.ScannedMediaOutput
import timber.log.Timber
import java.util.concurrent.Executor
import java.util.concurrent.Executors

class MediaScanner(
        private val callback: ChannelCallback,
        private val context: Context,
        private val executor: Executor = Executors.newSingleThreadExecutor()
) {
    fun scan(input: ScanMediaMethodInput) {
        Timber.v("scan(%s)", input)
        executor.execute {
            val scannedMediaOutputList: List<ScannedMediaOutput> = getAudioMedia()
            scannedMediaOutputList.forEach { callback.onMediaScanned(it) }
        }
    }

    private fun getAudioMedia(): List<ScannedMediaOutput> {
        return listOf(ScannedMediaOutput(title = "Title Media Test"))
    }
}
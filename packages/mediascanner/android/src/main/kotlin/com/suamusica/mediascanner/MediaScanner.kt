package com.suamusica.mediascanner

import android.content.Context
import com.suamusica.mediascanner.input.ScanMediaMethodInput
import com.suamusica.mediascanner.output.MediaOutput
import java.util.concurrent.Executor
import java.util.concurrent.Executors

class MediaScanner(
        private val callback: ChannelCallback,
        private val context: Context,
        private val executor: Executor = Executors.newSingleThreadExecutor()
) {
    fun scan(input: ScanMediaMethodInput) {
        executor.execute {
            val mediaOutputList: List<MediaOutput> = getAudioMedia()
            mediaOutputList.forEach { callback.onMediaScanned(it) }
        }
    }

    private fun getAudioMedia(): List<MediaOutput> {
        return listOf(MediaOutput(title = "Title Media Test"))
    }
}
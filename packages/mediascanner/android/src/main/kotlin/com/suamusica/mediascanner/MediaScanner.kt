package com.suamusica.mediascanner

import android.content.Context
import com.suamusica.mediascanner.input.ScanMediaMethodInput
import com.suamusica.mediascanner.output.Media
import java.util.concurrent.Executor
import java.util.concurrent.Executors

class MediaScanner(
        private val callback: ChannelCallback,
        private val context: Context,
        private val executor: Executor = Executors.newSingleThreadExecutor()
) {
    fun scan(input: ScanMediaMethodInput) {
        executor.execute {
            val mediaList: List<Media> = getAudioMedia()
            mediaList.forEach { callback.onMediaScanned(it) }
        }
    }

    private fun getAudioMedia(): List<Media> {
        return listOf(Media(title = "Title Media Test"))
    }
}
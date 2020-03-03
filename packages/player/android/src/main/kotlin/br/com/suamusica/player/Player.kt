package br.com.suamusica.player

import android.content.Context

interface Player {
    var volume: Double
    val duration: Long
    val currentPosition: Long
    var releaseMode: ReleaseMode
    val context: Context
    var stayAwake: Boolean
    val cookie: String

    fun prepare(media: Media)
    fun play()
    fun seek(position: Int)
    fun pause()
    fun stop()
    fun release()
    fun clear()
}
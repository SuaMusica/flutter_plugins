package br.com.suamusica.player

import android.content.Context

interface Player {
    var volume: Double
    val duration: Int
    val currentPosition: Int
    var releaseMode: ReleaseMode
    val context: Context
    var stayAwake: Boolean
    val cookie: String

    fun prepare(url: String)
    fun play()
    fun seek(position: Int)
    fun pause()
    fun stop()
    fun release()
}
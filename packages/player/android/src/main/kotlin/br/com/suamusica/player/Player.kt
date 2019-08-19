package br.com.suamusica.player

import android.content.Context

interface Player {
    var volume: Double
    val duration: Int
    val currentPosition: Int
    var releaseMode: ReleaseMode
    val context: Context
    var stayAwake: Boolean

    fun setUrl(url: String, local: Boolean)
    fun seek(position: Int)
    fun play()
    fun pause()
    fun stop()
    fun release()
}
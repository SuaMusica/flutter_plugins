package br.com.suamusica.player

import android.content.Context

interface Player {
    var volume: Double
    val duration: Long
    val currentPosition: Long
    var releaseMode: ReleaseMode
    val context: Context
    var stayAwake: Boolean

    fun prepare(cookie: String, media: Media)
    fun play()
    fun seek(position: Long)
    fun pause()
    fun stop()
    fun release()
    fun sendNotification()
    fun removeNotification()
    fun next()
    fun previous()
}
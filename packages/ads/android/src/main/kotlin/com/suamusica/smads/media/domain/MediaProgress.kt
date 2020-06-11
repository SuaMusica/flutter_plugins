package com.suamusica.smads.media.domain

data class MediaProgress(val current: Long, val total: Long) {

  fun percentage(): Long = (current * 100) / if (total <= 0) 1 else total

    companion object {
    val COMPLETED = MediaProgress(100, 100)
    val NONE = MediaProgress(0, 1)
  }
}
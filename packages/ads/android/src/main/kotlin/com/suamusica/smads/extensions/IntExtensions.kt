package com.suamusica.smads.extensions

import java.util.Formatter
import java.util.Locale

fun Int.asFormattedTime(): String {
  val totalSeconds = this / 1000

  val seconds = totalSeconds % 60
  val minutes = totalSeconds / 60 % 60
  val hours = totalSeconds / 3600

  val builder = StringBuilder()

  builder.setLength(0)

  val formatter = Formatter(builder, Locale.getDefault())

  return if (hours > 0) {
    formatter.format("%d:%02d:%02d", hours, minutes, seconds).toString()
  } else {
    formatter.format("%02d:%02d", minutes, seconds).toString()
  }
}

fun Int.toMinutes(): Int {
  val totalSeconds = this / 1000
  return totalSeconds % 60
}

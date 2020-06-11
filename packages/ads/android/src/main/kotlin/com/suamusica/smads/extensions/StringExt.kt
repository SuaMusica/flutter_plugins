package com.suamusica.smads.extensions

import java.math.BigInteger
import java.security.MessageDigest
import java.util.regex.Pattern

fun String.md5(): String {
  val md = MessageDigest.getInstance("MD5")
  return BigInteger(1, md.digest(toByteArray())).toString(16).padStart(32, '0')
}

fun String.isValidHexColor(): Boolean {
  val pattern = Pattern.compile("^#([A-Fa-f0-9]{8}|[A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$")
  return this.isNotBlank() && pattern.matcher(this).matches()
}
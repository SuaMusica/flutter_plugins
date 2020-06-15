package com.suamusica.smads.helpers

import android.content.Context
import android.net.ConnectivityManager
import timber.log.Timber
import java.io.IOException
import java.net.InetSocketAddress
import java.net.Socket

object ConnectivityHelper {

    private const val PING_ADDRESS = "www.google.com.br"
    private const val PORT = 80
    private const val PING_TIMEOUT_IN_MILLIS = 1000

    fun isConnected(context: Context): Boolean {
        val connectivityManager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val activeNetworkInfo = connectivityManager.activeNetworkInfo ?: return false
        if (!activeNetworkInfo.isConnected) return false
        return true
    }

    fun isReachable(context: Context): Boolean {
        val isConnected = isConnected(context)
        Timber.d("isConnected? %s", isConnected)
        if (isConnected.not()) return false
        return try {
            Socket().use {
                it.connect(InetSocketAddress(PING_ADDRESS, PORT), PING_TIMEOUT_IN_MILLIS)
            }
            true
        } catch (exception: IOException) {
            exception.printStackTrace()
            false
        }.also {
            Timber.v("isReachable = %s", it)
        }
    }
}
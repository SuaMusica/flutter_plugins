package com.suamusica.smads

import timber.log.Timber
import java.util.concurrent.atomic.AtomicBoolean

object Initializer {

    private val alreadyStarted = AtomicBoolean(false)

    fun run() {
        if (alreadyStarted.getAndSet(true)) return
        Timber.plant(Timber.DebugTree())
    }
}
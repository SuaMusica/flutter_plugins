package com.suamusica.mediascanner

import timber.log.Timber
import java.util.concurrent.atomic.AtomicBoolean

object Initializer {

    private val alreadyStarted = AtomicBoolean(false)

    fun run() {
        if (alreadyStarted.getAndSet(true)) return
        if(Timber.treeCount() != 0) return
        Timber.plant(Timber.DebugTree())
    }
}
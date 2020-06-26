package com.suamusica.smads.platformview

import android.view.View
import io.flutter.plugin.platform.PlatformView
import timber.log.Timber

class AdPlayer(private val controller: AdPlayerViewController,
               adPlayerParams: AdPlayerParams) : PlatformView {

    override fun getView(): View {
        return controller.adPlayerView
                ?: throw IllegalStateException("controller.adPlayerView should not be null.")
    }

    override fun dispose() {
        Timber.v("dispose")
//        adPlayerView.visibility = View.GONE
    }

    companion object {
        const val VIEW_TYPE_ID = "suamusica/pre_roll_view"
    }
}
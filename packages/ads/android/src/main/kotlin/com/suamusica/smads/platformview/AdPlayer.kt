package com.suamusica.smads.platformview

import android.view.View
import io.flutter.plugin.platform.PlatformView
import timber.log.Timber

class AdPlayer(private val adPlayerView: AdPlayerView, adPlayerParams: AdPlayerParams) : PlatformView {

    override fun getView(): View = adPlayerView

    override fun dispose() {
        Timber.v("dispose")
        adPlayerView.visibility = View.GONE
    }

    companion object {
        const val VIEW_TYPE_ID = "suamusica/pre_roll_view"
    }
}
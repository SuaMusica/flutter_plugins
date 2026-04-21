package com.suamusica.smads.platformview

import android.content.Context
import android.view.View
import com.suamusica.smads.AdPlayerViewController
import io.flutter.plugin.platform.PlatformView
import timber.log.Timber

class AdPlayer(private val controller: AdPlayerViewController,
               private val context: Context?,
               adPlayerParams: AdPlayerParams) : PlatformView {

    // The PlatformView lifecycle is owned by Flutter (via VirtualDisplayController) and
    // can outlive the controller's internal `adPlayerView` reference, which is nulled out
    // on `AdPlayerViewController.dispose()`. If we read `controller.adPlayerView` on every
    // `getView()` call, a call that arrives after the controller has been disposed (for
    // example, when the Activity is being resumed after an ad already completed) will
    // throw and crash the process. Cache the view the first time we see it so the
    // PlatformView stays renderable for as long as Flutter needs it.
    private var cachedView: View? = null

    override fun getView(): View {
        controller.adPlayerView?.let {
            cachedView = it
            return it
        }
        cachedView?.let { return it }

        // As a last resort (controller disposed before any view was ever attached),
        // return an empty placeholder instead of crashing the host Activity.
        Timber.w("AdPlayer.getView() called with no view available; returning placeholder.")
        val ctx = context ?: controller.appContext
        val placeholder = View(ctx)
        cachedView = placeholder
        return placeholder
    }

    override fun dispose() {
        Timber.d("dispose")
        cachedView = null
    }

    companion object {
        const val VIEW_TYPE_ID = "suamusica/pre_roll_view"
    }
}
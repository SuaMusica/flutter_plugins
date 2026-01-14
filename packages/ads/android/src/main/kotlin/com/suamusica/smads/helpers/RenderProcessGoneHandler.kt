package com.suamusica.smads.helpers

import android.os.Build
import android.view.View
import android.view.ViewGroup
import android.webkit.RenderProcessGoneDetail
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.annotation.RequiresApi
import timber.log.Timber

/**
 * Handler for WebView render process crashes.
 * 
 * The IMA SDK uses WebView internally for rendering ads. When the WebView's 
 * render process crashes (e.g., due to OOM), the app can crash if not handled.
 * 
 * This handler traverses the view hierarchy to find any WebViews and sets up
 * crash handling via WebViewClient.onRenderProcessGone().
 * 
 * Available on Android O (API 26) and above.
 */
class RenderProcessGoneHandler(
    private val onRenderProcessGone: (didCrash: Boolean) -> Unit
) {

    private val handledWebViews = mutableSetOf<Int>()

    /**
     * Sets up render process gone handling for any WebViews in the view hierarchy.
     * Call this after the view hierarchy is fully created.
     * 
     * @param rootView The root view to search for WebViews
     */
    fun setupForViewHierarchy(rootView: View) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            findAndSetupWebViews(rootView)
        } else {
            Timber.d("RenderProcessGoneHandler: API < 26, cannot set up handler")
        }
    }

    @RequiresApi(Build.VERSION_CODES.O)
    private fun findAndSetupWebViews(view: View) {
        when (view) {
            is WebView -> setupWebView(view)
            is ViewGroup -> {
                for (i in 0 until view.childCount) {
                    findAndSetupWebViews(view.getChildAt(i))
                }
            }
        }
    }

    @RequiresApi(Build.VERSION_CODES.O)
    private fun setupWebView(webView: WebView) {
        val viewId = System.identityHashCode(webView)
        
        if (handledWebViews.contains(viewId)) {
            Timber.d("WebView already has handler set up: %s", viewId)
            return
        }

        Timber.d("Setting up onRenderProcessGone handler for WebView: %s", viewId)
        
        val existingClient = try {
            // WebView doesn't expose getWebViewClient, so we create a wrapper
            null
        } catch (e: Exception) {
            null
        }

        webView.webViewClient = object : WebViewClient() {
            override fun onRenderProcessGone(view: WebView?, detail: RenderProcessGoneDetail?): Boolean {
                val didCrash = detail?.didCrash() ?: false
                Timber.e("onRenderProcessGone called! didCrash=%s, rendererPriorityAtExit=%s", 
                    didCrash, 
                    detail?.rendererPriorityAtExit()
                )

                // Clean up the WebView to prevent further issues
                try {
                    view?.let { wv ->
                        // Stop loading and clear
                        wv.stopLoading()
                        wv.loadUrl("about:blank")
                        
                        // Remove from parent if possible
                        (wv.parent as? ViewGroup)?.removeView(wv)
                        
                        // Destroy the WebView
                        wv.destroy()
                    }
                } catch (e: Exception) {
                    Timber.e(e, "Error cleaning up WebView after render process gone")
                }

                // Notify the callback
                onRenderProcessGone(didCrash)

                // Return true to indicate we handled it (prevents app crash)
                return true
            }
        }

        handledWebViews.add(viewId)
    }

    /**
     * Call this when the view hierarchy changes (e.g., after IMA SDK creates its views)
     * to set up handlers for any new WebViews.
     */
    fun refresh(rootView: View) {
        setupForViewHierarchy(rootView)
    }

    /**
     * Clears the tracked WebViews. Call this when disposing.
     */
    fun clear() {
        handledWebViews.clear()
    }

    companion object {
        /**
         * Checks if the device supports onRenderProcessGone handling.
         */
        fun isSupported(): Boolean = Build.VERSION.SDK_INT >= Build.VERSION_CODES.O
    }
}

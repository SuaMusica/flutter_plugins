package com.suamusica.smads.view

import android.content.Context
import android.content.Intent

data class AdPlayerActivityExtras(
        val adTagUrl: String,
        val contentUrl: String
) {

    fun toIntent(context: Context): Intent {
        val intent = Intent(context, AdPlayerActivity::class.java)
        intent.putExtra(AD_TAG_URL_KEY, adTagUrl)
        intent.putExtra(CONTENT_URL_KEY, contentUrl)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        return intent
    }

    companion object {
        private const val AD_TAG_URL_KEY = "AD_TAG_URL_KEY"
        private const val CONTENT_URL_KEY = "CONTENT_URL_KEY"

        fun fromIntent(intent: Intent): AdPlayerActivityExtras {
            return AdPlayerActivityExtras(
                    adTagUrl = intent.getStringExtra(AD_TAG_URL_KEY),
                    contentUrl = intent.getStringExtra(CONTENT_URL_KEY)
            )
        }
    }
}
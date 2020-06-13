package com.suamusica.smads.view

import android.content.Context
import android.content.Intent

data class AdPlayerActivityExtras(private val adTagUrl: String,
                                  val contentUrl: String,
                                  val age: Int?,
                                  val gender: String?,
                                  val typeAd: String) {

    val formattedAdTagUrl: String by lazy {
        "${adTagUrl}platform%3Dandroid%26Domain%3Dsuamusica%26age%3D${makeAgeExtra()}%26gender%3D${makeGenderExtra()}%26typead=${typeAd}"
    }

    fun toIntent(context: Context): Intent {
        val intent = Intent(context, AdPlayerActivity::class.java)
        intent.putExtra(AD_TAG_URL_KEY, adTagUrl)
        intent.putExtra(CONTENT_URL_KEY, contentUrl)
        intent.putExtra(AGE_KEY, makeAgeExtra())
        intent.putExtra(GENDER_KEY, makeGenderExtra())
        intent.putExtra(TYPE_AD_KEY, typeAd)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        return intent
    }

    private fun makeAgeExtra() = age ?: DEFAULT_AGE
    private fun makeGenderExtra() = if(!gender.isNullOrBlank()) gender else DEFAULT_GENDER

    companion object {
        private const val AD_TAG_URL_KEY = "AD_TAG_URL_KEY"
        private const val CONTENT_URL_KEY = "CONTENT_URL_KEY"
        private const val AGE_KEY = "AGE_KEY"
        private const val GENDER_KEY = "GENDER_KEY"
        private const val TYPE_AD_KEY = "TYPE_AD_KEY"

        private const val DEFAULT_AGE = -1
        private const val DEFAULT_GENDER = "-1"

        fun fromIntent(intent: Intent): AdPlayerActivityExtras {
            return AdPlayerActivityExtras(
                    adTagUrl = intent.getStringExtra(AD_TAG_URL_KEY),
                    contentUrl = intent.getStringExtra(CONTENT_URL_KEY),
                    age = intent.getIntExtra(AGE_KEY, DEFAULT_AGE),
                    gender = intent.getStringExtra(GENDER_KEY),
                    typeAd = intent.getStringExtra(TYPE_AD_KEY)
            )
        }
    }
}
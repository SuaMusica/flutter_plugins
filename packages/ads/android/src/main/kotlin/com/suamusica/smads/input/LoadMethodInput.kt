package com.suamusica.smads.input

import com.suamusica.smads.extensions.getRequired
import com.suamusica.smads.extensions.getValueOrNull

data class LoadMethodInput(
        val adTagUrl: String,
        val contentUrl: String,
        val age: Int?,
        val gender: String?,
        val typeAd: String
) {
    private constructor(args: Map<String, Any>)
            : this(
            args.getRequired(AD_TAG_URL_KEY),
            args.getRequired(CONTENT_URL_KEY),
            args.getValueOrNull(AGE_KEY),
            args.getValueOrNull(GENDER_KEY),
            args.getRequired(TYPE_AD_KEY))

    @Suppress("UNCHECKED_CAST")
    constructor(args: Any) : this(args = args as Map<String, Any>)

    companion object {
        private const val AD_TAG_URL_KEY = "__URL__"
        private const val CONTENT_URL_KEY = "__CONTENT__"
        private const val AGE_KEY = "age"
        private const val GENDER_KEY = "gender"
        private const val TYPE_AD_KEY = "typead"
    }
}
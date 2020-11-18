package com.suamusica.smads.input

import com.suamusica.smads.extensions.getRequired

class LoadMethodInput(
        tagUrl: String,
        queryParams: Map<String, Any>
) {
    private constructor(args: Map<String, Any>)
            : this(
            args.getRequired(AD_TAG_URL_KEY),
            args.toQueryParams())

    @Suppress("UNCHECKED_CAST")
    constructor(args: Any) : this(args = args as Map<String, Any>)

    private val queryString by lazy {
        queryParams.map {
            QUERY_PARAM_FORMAT.format(it.key, it.value.toString())
        }.joinToString("")
    }
    
    val adTagUrl: String by lazy {
        val parts = tagUrl.split("&")
        when {
            parts.isEmpty() -> tagUrl
            parts.last().endsWith(QUERY_CUSTOM_PARAMS_TAG) -> {
                tagUrl.plus(FIXED_PARAMS).plus(queryString)
            }
            parts.last().contains(QUERY_CUSTOM_PARAMS_TAG) -> {
                tagUrl.plus(AND_ENCODED).plus(FIXED_PARAMS).plus(queryString)
            }
            else -> tagUrl
        }
    }

    companion object {
        private const val AD_TAG_URL_KEY = "__URL__"

        private const val QUERY_CUSTOM_PARAMS_TAG = "cust_params="
        private const val AND_ENCODED = "%26"
        private const val EQUAL_ENCODED = "%3D"
        private const val FIXED_PARAMS = "platform${EQUAL_ENCODED}android${AND_ENCODED}Domain${EQUAL_ENCODED}suamusica"
        private const val QUERY_PARAM_FORMAT = "%%26%s%%3D%s"

        private fun Map<String, Any>.toQueryParams(): Map<String, Any> {
            return this.filterNot { it.key.startsWith("__") }
        }
    }

    override fun toString(): String {
        return "LoadMethodInput(adTagUrl='$adTagUrl')"
    }
}
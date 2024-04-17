package com.suamusica.smads.platformview

import com.suamusica.smads.extensions.getRequired

data class AdSize(val width: Int, val height: Int) {
    @Suppress("UNCHECKED_CAST")
    constructor(args: Map<String, Int>) : this(
            args.getRequired(AD_SIZE_WIDTH_KEY),
            args.getRequired(AD_SIZE_HEIGHT_KEY)
    )
    companion object {
        private const val AD_SIZE_WIDTH_KEY = "width"
        private const val AD_SIZE_HEIGHT_KEY = "height"
    }
}

data class AdPlayerParams(val adSize: AdSize) {

    private constructor(args: Map<String, Any>) : this(AdSize(args.getRequired(AD_SIZE_KEY)))

    @Suppress("UNCHECKED_CAST")
    constructor(args: Any?) : this(args = args as Map<String, Any>)

    companion object {
        private const val AD_SIZE_KEY = "adSize"
    }
}
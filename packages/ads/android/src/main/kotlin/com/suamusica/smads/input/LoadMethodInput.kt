package com.suamusica.smads.input

data class LoadMethodInput(
        val url: String,
        val contentUrl: String
) {
    private constructor(args: Map<String, String>)
            : this(
            args.getValue(URL_KEY),
            args.getValue(CONTENT_URL_KEY))

    @Suppress("UNCHECKED_CAST")
    constructor(args: Any) : this(args = args as Map<String, String>)

    companion object {
        private const val URL_KEY = "__URL__"
        private const val CONTENT_URL_KEY = "__CONTENT__"
    }
}
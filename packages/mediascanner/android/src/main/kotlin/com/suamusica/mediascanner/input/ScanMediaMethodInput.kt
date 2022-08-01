package com.suamusica.mediascanner.input

import com.suamusica.mediascanner.extensions.getRequired

data class ScanMediaMethodInput(
        val mediaType: MediaType,
        val extensions: List<String>,
        val databaseName: String,
        val databaseVersion: Int,
        val useUtil: Boolean
) {
    private constructor(args: Map<String, Any>)
            : this(
            MediaType.valueOf(args.getRequired(MEDIA_TYPE)),
            args.getRequired(SUPPORTED_EXTENSIONS),
            args.getRequired(DATABASE_NAME),
            args.getRequired(DATABASE_VERSION),
            args.getRequired(USE_UTIL)
    )

    @Suppress("UNCHECKED_CAST")
    constructor(args: Any) : this(
            args = args as Map<String, Any>)

    companion object {
        private const val MEDIA_TYPE = "media_type"
        private const val SUPPORTED_EXTENSIONS = "supported_extensions"
        private const val DATABASE_NAME = "database_name"
        private const val DATABASE_VERSION = "database_version"
        private const val USE_UTIL = "use_util"
    }
}
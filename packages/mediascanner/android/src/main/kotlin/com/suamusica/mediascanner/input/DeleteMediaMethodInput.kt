package com.suamusica.mediascanner.input

import com.suamusica.mediascanner.extensions.getRequired

data class DeleteMediaMethodInput(
        val mediaType: MediaType,
        val id: Long,
        val fullPath: String
) {
    private constructor(args: Map<String, Any>)
            : this(
            MediaType.valueOf(args.getRequired(MEDIA_TYPE)),
            args.getRequired(ID),
            args.getRequired(FULL_PATH)
    )

    @Suppress("UNCHECKED_CAST")
    constructor(args: Any) : this(args = args as Map<String, Any>)

    companion object {
        private const val MEDIA_TYPE = "media_type"
        private const val ID = "id"
        private const val FULL_PATH = "full_path"
    }
}
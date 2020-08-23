package com.suamusica.mediascanner.output

data class ScannedMediaOutput(
        val title: String
) {

    fun toResult(): Map<String, Any> {
        return mapOf(
                TITLE_KEY to title
        )
    }

    companion object {
        private const val TITLE_KEY = "title"
        private const val EMPTY_STRING = ""
    }
}
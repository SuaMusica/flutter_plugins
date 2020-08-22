package com.suamusica.mediascanner.output

data class Media(
        val title: String
) {

    fun toResult(): Map<String, String> {
        return mapOf(
                TYPE_KEY to title
        )
    }

    companion object {
        private const val TYPE_KEY = "type"
        private const val EMPTY_STRING = ""
    }
}
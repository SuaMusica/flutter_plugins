package com.suamusica.mediascanner.output

data class ScannedMediaOutput(
        val title: String,
        val artist: String,
        val album: String,
        val path: String
) {

    fun toResult(): Map<String, Any> {
        return mapOf(
                TITLE_KEY to title,
                ARTIST_KEY to artist,
                ALBUM_KEY to album,
                PATH_KEY to path
        )
    }

    companion object {
        private const val TITLE_KEY = "title"
        private const val ARTIST_KEY = "artist"
        private const val ALBUM_KEY = "album"
        private const val PATH_KEY = "path"
        private const val EMPTY_STRING = ""
    }
}
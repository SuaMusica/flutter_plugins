package com.suamusica.mediascanner.output

data class ScannedMediaOutput(
        val title: String,
        val artist: String,
        val album: String,
        val track: String,
        val path: String,
        val albumCoverPath: String
) {

    fun toResult(): Map<String, Any> {
        return mapOf(
                TITLE_KEY to title,
                ARTIST_KEY to artist,
                ALBUM_KEY to album,
                TRACK_KEY to track,
                PATH_KEY to path,
                ALBUM_COVER_PATH_KEY to albumCoverPath
        )
    }

    companion object {
        private const val TITLE_KEY = "title"
        private const val ARTIST_KEY = "artist"
        private const val ALBUM_KEY = "album"
        private const val TRACK_KEY = "track"
        private const val PATH_KEY = "path"
        private const val ALBUM_COVER_PATH_KEY = "album_cover_path"
        private const val EMPTY_STRING = ""
    }
}
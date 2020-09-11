package com.suamusica.mediascanner.output

data class ScannedMediaOutput(
        val mediaId: Long,
        val title: String,
        val artist: String,
        val albumId: Long,
        val album: String,
        val track: String,
        val path: String,
        val albumCoverPath: String,
        val createdAt: Long,
        val updatedAt: Long
) {

    fun toResult(): Map<String, Any> {
        return mapOf(
                MEDIA_ID_KEY to mediaId,
                TITLE_KEY to title,
                ARTIST_KEY to artist,
                ALBUM_ID_KEY to albumId,
                ALBUM_KEY to album,
                TRACK_KEY to track,
                PATH_KEY to path,
                ALBUM_COVER_PATH_KEY to albumCoverPath,
                CREATED_AT_KEY to createdAt,
                UPDATED_AT_KEY to updatedAt
        )
    }

    companion object {
        private const val MEDIA_ID_KEY = "mediaId"
        private const val TITLE_KEY = "title"
        private const val ARTIST_KEY = "artist"
        private const val ALBUM_ID_KEY = "albumId"
        private const val ALBUM_KEY = "album"
        private const val TRACK_KEY = "track"
        private const val PATH_KEY = "path"
        private const val ALBUM_COVER_PATH_KEY = "album_cover_path"
        private const val CREATED_AT_KEY = "created_at"
        private const val UPDATED_AT_KEY = "updated_at"
        private const val EMPTY_STRING = ""
    }
}
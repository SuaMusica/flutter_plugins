package com.suamusica.room.entities

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity
data class LocalDownloadEvent(
    @PrimaryKey(autoGenerate = true) var id: Long?,
    @ColumnInfo(name = "album_id")
    var albumId: String?,
    @ColumnInfo(name = "playlist_id")
    var playlistId: String?,
    @ColumnInfo(name = "music_id")
    var musicId: String?
) {
  constructor(): this(null, null, null, null)
}
package com.suamusica.room.entities

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.PrimaryKey
import com.google.gson.annotations.SerializedName

@Entity
data class CountLocalPlayEvent(
    @PrimaryKey(autoGenerate = true)
    var id: Long? = null,
    @field:SerializedName("arqid")
    @ColumnInfo(name = "music_id")
    var musicId: String? = null,
    @field:SerializedName("cdid")
    @ColumnInfo(name = "album_id")
    var albumId: String? = null,
    @field:SerializedName("plid")
    @ColumnInfo(name = "playlist_id")
    var playlistId: String? = null,
    @field:SerializedName("offline")
    var offline: Int = 0,
    @field:SerializedName("qty")
    @ColumnInfo(name = "qty")
    var quantity: Int? = null
) {
    constructor(musicId: String? = "0", albumId: String? = "0", playlistId: String? = "0", offline: Int = 0, quantity: Int? = 1):
        this(null, musicId, albumId, playlistId, offline, quantity)

    fun toLocalPlayEvent() = LocalPlayEvent(this.id, this.albumId, this.playlistId, this.musicId ?: "0", this.offline)
}
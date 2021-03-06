package com.suamusica.room.entities

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.Ignore
import androidx.room.Index
import androidx.room.PrimaryKey
import com.google.gson.annotations.SerializedName
import java.io.File

@Entity(indices = [Index(value = ["id", "album_id", "artist_id"])])
data class OfflineMedia(
  @PrimaryKey
  @ColumnInfo(name = "id")
  var id: String,
  @ColumnInfo(name = "file_path")
  var filePath: String = "",
  var name: String = "",
  @ColumnInfo(name = "image_url")
  var imageUrl: String = "",
  @field:SerializedName("dono")
  @ColumnInfo(name = "artist_id")
  var artistId: String = "",
  @ColumnInfo(name = "artist_name")
  var artistName: String = "",
  @field:SerializedName("cdid")
  @ColumnInfo(name = "album_id")
  var albumId: String = "",
  @field:SerializedName("plids")
  @ColumnInfo(name = "playlist_ids")
  var playlistIds: List<String> = listOf(),
  @ColumnInfo(name = "download_id")
  var downloadId: Long = 0,
  @ColumnInfo(name = "is_downloaded")
  var isDownloaded: Boolean = false,
  @ColumnInfo(name = "is_verified")
  var isVerified: Boolean = false,
  @Ignore
  var shareUrl: String? = null,
  @Ignore
  @field:SerializedName("plid")
  var playlistId: String? = null,
  @ColumnInfo(name = "is_external")
  var isExternal: Boolean = false,
  @ColumnInfo(name = "created_time")
  var creationTimeMillis: Long = -1,
  @ColumnInfo(name = "index_position")
  var indexPosition: Int = -1,
  @ColumnInfo(name = "stream")
  var stream: String = ""
){
  constructor():
  this("", "", "", "", "", "", "",
    listOf(), 0L, false, false, stream = "")

  fun mediaUrl(): String = if (File(filePath).exists()) filePath else stream

  fun toMigration(): List<Map<String, Any>> {
    val content = mutableListOf<Map<String, Any>>()

    if (playlistIds.isEmpty()) {
      content.add(
          mapOf(
              "id" to this.id,
              "name" to this.name,
              "album_id" to this.albumId,
              "download_id" to this.downloadId.toString(),
              "is_external" to this.isExternal,
              "index_in_album" to this.indexPosition.toString(),
              "path" to "",
              "stream_path" to this.stream,
              "share_url" to (this.shareUrl ?: ""),
              "local_path" to this.filePath,
              "created_at" to this.creationTimeMillis.toString(),
              "index_in_playlist" to "-1",
              "playlist_id"  to "0"
          )
      )
    } else {
      for (playlistId in playlistIds) {
        content.add(
            mapOf(
                "id" to this.id,
                "name" to this.name,
                "album_id" to this.albumId,
                "download_id" to this.downloadId.toString(),
                "is_external" to this.isExternal,
                "index_in_album" to this.indexPosition.toString(),
                "path" to "",
                "stream_path" to this.stream,
                "share_url" to (this.shareUrl ?: ""),
                "local_path" to this.filePath,
                "created_at" to this.creationTimeMillis.toString(),
                "index_in_playlist" to "-1",
                "playlist_id"  to playlistId
            )
        )
      }
    }

    return content.toList()
  }
}
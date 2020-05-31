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

  fun toMigration(): List<MigrationMedia> {
    val content = mutableListOf<MigrationMedia>()

    if (playlistIds.isEmpty()) {
      content.add(
          MigrationMedia(
              id = this.id,
              name= this.name,
              albumId= this.albumId,
              downloadId= this.downloadId.toString(),
              isExternal= this.isExternal,
              indexInAlbum= this.indexPosition.toString(),
              streamPath= this.stream,
              shareUrl= this.shareUrl ?: "",
              localPath= this.filePath,
              createdAt= this.creationTimeMillis.toString()
          )
      )
    } else {
      for (playlistId in playlistIds) {
        content.add(
            MigrationMedia(
                id = this.id,
                name= this.name,
                albumId= this.albumId,
                downloadId= this.downloadId.toString(),
                isExternal= this.isExternal,
                indexInAlbum= this.indexPosition.toString(),
                streamPath= this.stream,
                shareUrl= this.shareUrl ?: "",
                localPath= this.filePath,
                createdAt= this.creationTimeMillis.toString(),
                playlistId = playlistId
            )
        )
      }
    }

    return content.toList()
  }
}

data class MigrationMedia(
    var id: String,
    var name: String,
    var albumId: String,
    var downloadId: String,
    var isExternal: Boolean,
    var indexInAlbum: String,
    var path: String = "",
    var streamPath: String,
    var shareUrl: String,
    var localPath: String,
    var createdAt: String,
    var indexInPlaylist: String = "-1",
    var playlistId: String = "0"
) {
  fun toMap(): Map<String, Any> =
      mapOf(
          "id" to this.id,
          "name" to this.name,
          "album_id" to this.albumId,
          "download_id" to this.downloadId,
          "is_external" to this.isExternal,
          "index_in_album" to this.indexInAlbum,
          "path" to this.path,
          "stream_path" to this.streamPath,
          "share_url" to this.shareUrl,
          "local_path" to this.localPath,
          "created_at" to this.createdAt,
          "index_in_playlist" to this.indexInPlaylist,
          "playlist_id"  to this.playlistId
      )
}
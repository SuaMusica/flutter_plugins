package com.suamusica.room.entities

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.Ignore
import androidx.room.Index
import androidx.room.PrimaryKey
import java.io.Serializable

@Entity(indices = [Index(value = ["id", "artist_id"])])
data class OfflineAlbum(
  @PrimaryKey
  @ColumnInfo(name = "id")
  var id: String,
  var name: String = "",
  @ColumnInfo(name = "image_url")
  var imageUrl: String = "",
  @ColumnInfo(name = "artist_name")
  var artistName: String = "",
  @ColumnInfo(name = "artist_id")
  var ownerId: String = "",
  @ColumnInfo(name = "share_url")
  var shareUrl: String? = "",
  @ColumnInfo(name = "created_time")
  var creationTimeMillis: Long = -1,
  @Ignore
  var numberOfSongs: Int = 0,
  @Ignore
  var albumPath: String? = ""
): Serializable {
  constructor(): this("", "", "", "", "", "", -1, numberOfSongs = 0)

  fun prettyNumberOfSongs(): String {
    return if (numberOfSongs > 1) {
      "$numberOfSongs Músicas"
    } else {
      "$numberOfSongs Música"
    }
  }

  fun toMigration(isVerified: Boolean = false) =
      MigrationAlbum(
          id = this.id,
          name = this.name,
          coverUrl = this.imageUrl,
          shareUrl = this.shareUrl ?: "",
          artistName = this.artistName,
          artistId = this.ownerId,
          isVerified = isVerified,
          createdAt = this.creationTimeMillis.toString()
      ).toMap()
}

data class MigrationAlbum(
    var id: String,
    var name: String,
    var coverUrl: String,
    var shareUrl: String,
    var artistName: String,
    var artistId: String,
    var isVerified: Boolean = false,
    var createdAt: String
) {
  fun toMap(): Map<String, Any> =
      mapOf(
          "id" to this.id,
          "name" to this.name,
          "cover_url" to this.coverUrl,
          "artist_name" to this.artistName,
          "artist_id" to this.artistId,
          "share_url" to this.shareUrl,
          "is_verified" to this.isVerified,
          "created_at" to this.createdAt
      )
}
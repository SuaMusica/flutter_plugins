package com.suamusica.room.entities

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.Ignore
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(indices = [Index(value = ["id", "artist_id"])])
data class OfflinePlaylist(
  @PrimaryKey
  var id: String,
  var name: String = "",
  @ColumnInfo(name = "artist_name")
  var artistName: String = "",
  @ColumnInfo(name = "artist_id")
  var ownerId: String = "",
  @ColumnInfo(name = "cover_url")
  var coverUrl: String = "",
  @ColumnInfo(name = "share_url")
  var shareUrl: String = "",
  @ColumnInfo(name = "created_time")
  var creationTimeMillis: Long = -1,
  @Ignore
  var numberOfSongs: Int = 0
) {
  constructor(): this("","", "", "", "", "", -1, 0)

  fun toMigration(isVerified: Boolean = false): Map<String, Any> =
      mapOf(
          "id" to this.id,
          "name" to this.name,
          "cover_url" to this.coverUrl,
          "artist_name" to this.artistName,
          "artist_id" to this.ownerId,
          "share_url" to this.shareUrl,
          "is_verified" to isVerified,
          "created_at" to this.creationTimeMillis.toString()
      )
}
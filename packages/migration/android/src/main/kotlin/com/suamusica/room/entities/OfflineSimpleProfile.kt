package com.suamusica.room.entities

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.PrimaryKey
import com.google.gson.annotations.SerializedName

@Entity
data class OfflineSimpleProfile(
  @field:SerializedName("id")
  @PrimaryKey
  @ColumnInfo(name = "id")
  var id: String = "",
  @field:SerializedName("nome")
  @ColumnInfo(name = "name")
  var name: String = "",
  @field:SerializedName("perfilcover")
  @ColumnInfo(name = "profile_cover")
  var profileCover: String = "",
  @field:SerializedName("foto")
  @ColumnInfo(name = "photo")
  var photo: String = "",
  @field:SerializedName("isfollowing")
  @ColumnInfo(name = "is_following")
  var isFollowing: Boolean = false,
  @field:SerializedName("isverified")
  @ColumnInfo(name = "is_verified")
  var isVerified: Int = -1,
  @field:SerializedName("exclude")
  @ColumnInfo(name = "excluded")
  var excluded: String = "",
  @field:SerializedName("isProcessingFollowAction")
  @ColumnInfo(name = "is_processing_follow_action")
  var isProcessingFollowAction: Boolean = false
)
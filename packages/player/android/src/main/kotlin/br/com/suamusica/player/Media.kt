package br.com.suamusica.player

import com.google.gson.annotations.SerializedName

data class Media(
    @SerializedName("id") val id: Int,
    @SerializedName("name") val name: String,
    @SerializedName("ownerId") val ownerId: Int,
    @SerializedName("albumId") val albumId: Int,
    @SerializedName("albumTitle") val albumTitle: String,
    @SerializedName("author") val author: String,
    @SerializedName("url") val url: String,
    @SerializedName("is_local") val isLocal: Boolean,
    @SerializedName("cover_url") val coverUrl: String,
    @SerializedName("bigCover") val bigCoverUrl: String,
    @SerializedName("is_verified") val isVerified: Boolean,
    @SerializedName("shared_url") val shareUrl: String,
    @SerializedName("playlist_id") val playlistId: Int,
    @SerializedName("is_spot") val isSpot: Boolean,
    @SerializedName("isFavorite") val isFavorite: Boolean?,
    @SerializedName("fallbackUrl") val fallbackUrl: String,
    @SerializedName("indexInPlaylist") val indexInPlaylist: Int?,
    @SerializedName("catid") val categoryId: Int,
    @SerializedName("playlistTitle") val playlistTitle: String,
    @SerializedName("playlistCoverUrl") val playlistCoverUrl: String,
    @SerializedName("playlistOwnerId") val playlistOwnerId: Int
)
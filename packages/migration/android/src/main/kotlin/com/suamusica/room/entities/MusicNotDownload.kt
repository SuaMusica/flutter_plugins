package com.suamusica.room.entities

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.PrimaryKey
import com.google.gson.annotations.SerializedName

@Entity
data class MusicNotDownload(
  @PrimaryKey
  @ColumnInfo(name = "id") @SerializedName("id") val id: String,
  @ColumnInfo(name = "file") @SerializedName("arquivo") val filename: String,
  @ColumnInfo(name = "music_name") @SerializedName("nomeMusica") val musicName: String,
  @ColumnInfo(name = "title") @SerializedName("titulo") val title: String,
  @ColumnInfo(name = "plays") @SerializedName("plays") val plays: String,
  @ColumnInfo(name = "path") @SerializedName("caminho") val path: String,
  @ColumnInfo(name = "stream") @SerializedName("stream") val stream: String,
  @ColumnInfo(name = "cover") @SerializedName("cover") val cover: String,
  @ColumnInfo(name = "owner") @SerializedName("dono") val artistId: String,
  @ColumnInfo(name = "artist") @SerializedName("artist") val artist: String,
  @ColumnInfo(name = "name_artist") @SerializedName("nomeArtista") val artistName: String,
  @ColumnInfo(name = "album_id") @SerializedName("cdid") val albumId: String,
  @ColumnInfo(name = "album") @SerializedName("album") val albumName: String,
  @ColumnInfo(name = "media_type") @SerializedName("mediatype") val type: String,
  @ColumnInfo(name = "is_downloadable") @SerializedName("isDownloadable") val isDownloadable: Int,
  @ColumnInfo(name = "play_list_id") @SerializedName("plid") val playlistId: String,
  @ColumnInfo(name = "share_url") @SerializedName("shareUrl") val shareUrl: String,
  @ColumnInfo(name = "play_list_name") @SerializedName("playlistname") val playlistName: String,
  @ColumnInfo(name = "play_list_author_name") @SerializedName("playlistAuthorName") val playlistAuthorName: String,
  @ColumnInfo(name = "play_list_author_id") @SerializedName("playlistAuthorId") val playlistAuthorId: String,
  @ColumnInfo(name = "play_list_cover_url") @SerializedName("playlistCoverUrl") val playlistCoverUrl: String,
  @ColumnInfo(name = "is_verified") @SerializedName("isVerified") val artistIsVerified: Int,
  @ColumnInfo(name = "position") @SerializedName("position") val position: Int
) {

  fun name() = when {
    musicName.isBlank().not() -> musicName
    title.isBlank().not() -> title
    filename.isBlank().not() -> filename
    else -> "Não encontrado"
  }.removeAudioSuffix()

}

fun String.removeAudioSuffix() =
        this.replace(".mp3", "", true)
                .replace(".wav", "", true)
                .replace(".m3u8", "", true)
                .replace(".wma", "", true)
                .replace(".ogg", "", true)
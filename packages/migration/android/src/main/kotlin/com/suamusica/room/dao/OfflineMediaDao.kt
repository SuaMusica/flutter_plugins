package com.suamusica.room.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Transaction
import androidx.room.Update
import com.suamusica.room.entities.OfflineMedia

@Dao
interface OfflineMediaDao {
  @Query("SELECT * from OfflineMedia WHERE `id` = :id LIMIT 1")
  fun getItem(id: String): OfflineMedia?

  @Query("SELECT * from OfflineMedia WHERE `id` = :id AND `is_downloaded` = :isDownloaded LIMIT 1")
  fun getItem(id: String, isDownloaded: Boolean = true): OfflineMedia?

  @Query("SELECT * from OfflineMedia WHERE `file_path` = :path LIMIT 1")
  fun getItemFromPath(path: String): OfflineMedia?

  @Query("SELECT * from OfflineMedia")
  fun getMedias(): List<OfflineMedia>?

  @Query("SELECT * from OfflineMedia WHERE `is_downloaded` = :isDownloaded ORDER BY `album_id`, `index_position`")
  fun getMedias(isDownloaded: Boolean? = true): List<OfflineMedia>?

  @Query("SELECT * from OfflineMedia WHERE `index_position` = :position")
  fun getMediasWithPosition(position: Int? = null): List<OfflineMedia>?

  @Query("SELECT * from OfflineMedia WHERE `album_id` = :albumId ORDER BY `index_position`")
  fun getMediasFromAlbum(albumId: String): List<OfflineMedia>?

  @Query("SELECT * from OfflineMedia WHERE `album_id` = :albumId AND `is_downloaded` = :isDownloaded")
  fun getMediasFromAlbum(albumId: String, isDownloaded: Boolean? = true): List<OfflineMedia>?

  @Query("SELECT * from OfflineMedia WHERE `playlist_ids` LIKE '%\"' || :playlistId || '\"%'")
  fun getMediasFromPlaylist(playlistId: String): List<OfflineMedia>?

  @Query("SELECT * from OfflineMedia WHERE `playlist_ids` LIKE '%\"' || :playlistId || '\"%' AND `is_downloaded` = :isDownloaded")
  fun getMediasFromPlaylist(playlistId: String, isDownloaded: Boolean? = true): List<OfflineMedia>?

  @Insert(onConflict = OnConflictStrategy.IGNORE)
  fun insert(offlineMedia: OfflineMedia)

  @Transaction
  fun insertAll(medias: List<OfflineMedia>) = medias.forEach { insert(it) }

  @Transaction
  fun deleteAll(mediaIds: List<String>) = mediaIds.forEach { delete(it) }

  @Update(onConflict = OnConflictStrategy.REPLACE)
  fun update(offlineMedia: OfflineMedia)

  @Transaction
  fun updateAll(medias: List<OfflineMedia>) = medias.forEach { update(it) }

  @Query("DELETE from OfflineMedia WHERE `id` = :id")
  fun delete(id: String)

  @Query("DELETE from OfflineMedia WHERE `is_downloaded` = :isDownloaded")
  fun delete(isDownloaded: Boolean)
}
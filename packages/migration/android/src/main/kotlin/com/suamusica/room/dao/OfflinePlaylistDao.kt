package com.suamusica.room.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Transaction
import androidx.room.Update
import com.suamusica.room.entities.OfflinePlaylist

@Dao
interface OfflinePlaylistDao {
  @Query("SELECT * from OfflinePlaylist WHERE `id` = :id LIMIT 1")
  fun getItem(id: String): OfflinePlaylist?

  @Query("SELECT * from OfflinePlaylist")
  fun getPlaylists(): List<OfflinePlaylist>?

  @Update(onConflict = OnConflictStrategy.REPLACE)
  fun update(offlineMedia: OfflinePlaylist)

  @Transaction
  fun updateAll(playlists: List<OfflinePlaylist>) = playlists.forEach { insert(it) }

  @Insert(onConflict = OnConflictStrategy.IGNORE)
  fun insert(offlineMedia: OfflinePlaylist)

  @Transaction
  fun insertAll(playlists: List<OfflinePlaylist>) = playlists.forEach { insert(it) }

  @Query("DELETE from OfflinePlaylist WHERE `id` = :id")
  fun delete(id: String)
}
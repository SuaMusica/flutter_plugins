package com.suamusica.room.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Transaction
import androidx.room.Update
import com.suamusica.room.entities.OfflineAlbum

@Dao
interface OfflineAlbumDao {
  @Query("SELECT * from OfflineAlbum WHERE `id` = :id LIMIT 1")
  fun getItem(id: String): OfflineAlbum?

  @Query("SELECT * from OfflineAlbum")
  fun getAlbums(): List<OfflineAlbum>?

  @Update(onConflict = OnConflictStrategy.REPLACE)
  fun update(offlineAlbum: OfflineAlbum)

  @Transaction
  fun updateAll(list: List<OfflineAlbum>) = list.forEach { insert(it) }

  @Insert(onConflict = OnConflictStrategy.IGNORE)
  fun insert(offlineMedia: OfflineAlbum)

  @Transaction
  fun insertAll(list: List<OfflineAlbum>) = list.forEach { insert(it) }

  @Query("DELETE from OfflineAlbum WHERE `id` = :id")
  fun delete(id: String)
}
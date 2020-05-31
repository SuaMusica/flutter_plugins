package com.suamusica.room.dao

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Transaction
import com.suamusica.room.entities.CountLocalPlayEvent
import com.suamusica.room.entities.LocalPlayEvent

@Dao
interface LocalPlayEventDao {
  @Query("SELECT * from LocalPlayEvent")
  fun getAll(): List<LocalPlayEvent>

  @Query("SELECT * from LocalPlayEvent WHERE `id` = :id")
  fun getById(id: Long): LocalPlayEvent?

  @Query("SELECT * from LocalPlayEvent WHERE `album_id` = :albumId AND `playlist_id` = :playlistId AND `music_id` = :musicId")
  fun getBy(albumId: String? = null, playlistId: String? = null, musicId: String? = null): List<LocalPlayEvent>?

  @Query("SELECT id, music_id, album_id, playlist_id, offline, COUNT(*) AS qty from LocalPlayEvent GROUP BY music_id, album_id, playlist_id, offline")
  fun count(): List<CountLocalPlayEvent>?

  @Insert(onConflict = OnConflictStrategy.IGNORE)
  fun insert(LocalPlayEvent: LocalPlayEvent)

  @Transaction
  fun insert(profileIds: List<LocalPlayEvent>) {
    profileIds.forEach { insert(it) }
  }

  @Query("DELETE from LocalPlayEvent")
  fun deleteAll()

  @Delete
  fun delete(localPlayEvents: List<LocalPlayEvent>)

  @Delete
  fun delete(localPlayEvent: LocalPlayEvent)
}
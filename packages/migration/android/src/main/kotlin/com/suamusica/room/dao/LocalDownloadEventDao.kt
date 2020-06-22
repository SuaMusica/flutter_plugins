package com.suamusica.room.dao

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Transaction
import com.suamusica.room.entities.CountLocalDownloadEvent
import com.suamusica.room.entities.LocalDownloadEvent

@Dao
interface LocalDownloadEventDao {
  @Query("SELECT * from LocalDownloadEvent")
  fun getAll(): List<LocalDownloadEvent>

  @Query("SELECT * from LocalDownloadEvent WHERE `id` = :id")
  fun getById(id: Long): LocalDownloadEvent?

  @Query("SELECT * from LocalDownloadEvent WHERE `album_id` = :albumId AND `playlist_id` = :playlistId AND `music_id` = :musicId")
  fun getBy(albumId: String? = null, playlistId: String? = null, musicId: String? = null): List<LocalDownloadEvent>?

  @Query("SELECT id, music_id, album_id, playlist_id, COUNT(*) AS qty from LocalDownloadEvent GROUP BY music_id, album_id, playlist_id")
  fun count(): List<CountLocalDownloadEvent>?

  @Insert(onConflict = OnConflictStrategy.IGNORE)
  fun insert(LocalDownloadEvent: LocalDownloadEvent)

  @Transaction
  fun insert(profileIds: List<LocalDownloadEvent>) {
    profileIds.forEach { insert(it) }
  }

  @Query("DELETE from LocalDownloadEvent")
  fun deleteAll()

  @Delete
  fun delete(LocalDownloadEvents: List<LocalDownloadEvent>)

  @Delete
  fun delete(LocalDownloadEvent: LocalDownloadEvent)

}
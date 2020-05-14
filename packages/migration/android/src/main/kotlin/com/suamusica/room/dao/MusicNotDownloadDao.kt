package com.suamusica.room.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.suamusica.room.entities.MusicNotDownload

@Dao
interface MusicNotDownloadDao{
  @Query("SELECT * FROM MusicNotDownload")
  fun getAll() : List<MusicNotDownload>

  @Query("SELECT * FROM MusicNotDownload WHERE `id` = :id")
  fun getItem(id: String) : MusicNotDownload?

  @Insert(onConflict = OnConflictStrategy.IGNORE)
  fun insert(musicNotDownload: MusicNotDownload)

  @Query("DELETE FROM MusicNotDownload WHERE `id` = :id")
  fun deleteById(id: String)

  @Query("DELETE FROM MusicNotDownload")
  fun deleteAll()
}
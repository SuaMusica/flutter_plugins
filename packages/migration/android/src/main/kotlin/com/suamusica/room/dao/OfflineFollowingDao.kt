package com.suamusica.room.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.suamusica.room.entities.OfflineSimpleProfile

@Dao
interface OfflineFollowingDao {

  @Insert(onConflict = OnConflictStrategy.IGNORE)
  fun insert(item: OfflineSimpleProfile)

  @Query("SELECT * from OfflineSimpleProfile")
  fun getListOfflineSimpleProfile(): List<OfflineSimpleProfile>

  @Query("DELETE from OfflineSimpleProfile WHERE `id` = :id")
  fun deleteById(id: String)

  @Query("DELETE from OfflineSimpleProfile")
  fun deleteAll()
}
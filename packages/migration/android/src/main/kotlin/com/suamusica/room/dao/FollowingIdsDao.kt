package com.suamusica.room.dao

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Transaction
import com.suamusica.room.entities.FollowingId

@Dao
interface FollowingIdsDao {
  @Query("SELECT * from FollowingId ORDER BY id DESC LIMIT :limit")
  fun getAllWithLimit(limit: Int?): List<FollowingId>

  @Query("SELECT * from FollowingId")
  fun getAll(): List<FollowingId>

  @Insert(onConflict = OnConflictStrategy.IGNORE)
  fun insert(followingId: FollowingId)

  @Transaction
  fun insertAll(profileIds: List<String>) {
    profileIds.forEach { insert(FollowingId(it)) }
  }

  @Query("SELECT * from FollowingId WHERE `id` = :id")
  fun getId(id: String): String?

  @Query("DELETE from FollowingId")
  fun deleteAll()

  @Delete
  fun deleteUnFollowerIds(unFollowerIds: List<FollowingId>)

  @Query("DELETE FROM FollowingId WHERE `id` = :id")
  fun deleteById(id: String)

  @Delete
  fun delete(unFollowerId: FollowingId)
}
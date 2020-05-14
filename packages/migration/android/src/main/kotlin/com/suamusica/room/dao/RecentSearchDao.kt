package com.suamusica.room.dao

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy.REPLACE
import androidx.room.Query
import com.suamusica.room.entities.RecentSearch

@Dao
interface RecentSearchDao {
  @Query("SELECT * from RecentSearch ORDER BY id DESC LIMIT :limit")
  fun getAll(limit: Int): List<RecentSearch>

  @Insert(onConflict = REPLACE)
  fun insert(weatherData: RecentSearch)

  @Query("DELETE from RecentSearch WHERE `query` = :query")
  fun deleteRecentSearchByQuery(query: String)

  @Query("DELETE from RecentSearch")
  fun deleteAll()
}
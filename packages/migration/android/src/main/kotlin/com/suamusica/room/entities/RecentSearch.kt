package com.suamusica.room.entities

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.Ignore
import androidx.room.PrimaryKey

@Entity
data class RecentSearch (
    @PrimaryKey(autoGenerate = true) var id: Long?,
    @ColumnInfo(name = "query") var query: String
) {
  constructor(): this(null, "")

  constructor(query: String): this(null, query)
}
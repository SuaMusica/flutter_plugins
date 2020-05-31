package com.suamusica.room.database

import androidx.sqlite.db.SupportSQLiteDatabase
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.TypeConverters
import androidx.room.migration.Migration
import android.content.Context
import com.suamusica.room.converters.Converters
import com.suamusica.room.dao.*
import com.suamusica.room.entities.*

@Database(
    entities = [
      RecentSearch::class, FollowingId::class, OfflineMedia::class, OfflineAlbum::class, OfflinePlaylist::class,
      LocalPlayEvent::class, CountLocalPlayEvent::class, LocalDownloadEvent::class, CountLocalDownloadEvent::class,
      OfflineSimpleProfile::class, MusicNotDownload::class
    ],
    version = 7)
@TypeConverters(Converters::class)
abstract class QueryDatabase : RoomDatabase() {

  abstract fun recentSearchDao(): RecentSearchDao

  abstract fun followingIdsDao(): FollowingIdsDao

  abstract fun localPlayEventDao(): LocalPlayEventDao

  abstract fun localDownloadEventDao(): LocalDownloadEventDao

  abstract fun offlineMediaDao(): OfflineMediaDao

  abstract fun offlineAlbumDao(): OfflineAlbumDao

  abstract fun offlinePlaylistDao(): OfflinePlaylistDao

  abstract fun offlineFollowingDao(): OfflineFollowingDao

  abstract fun musicNotDownloadDao(): MusicNotDownloadDao

  companion object {
    private var INSTANCE: QueryDatabase? = null

    fun getInstance(context: Context): QueryDatabase? {
      if (INSTANCE == null) {
        synchronized(QueryDatabase::class) {
          INSTANCE = Room.databaseBuilder(context.applicationContext,
              QueryDatabase::class.java, "query.db")
              .addMigrations(MIGRATION_1_2, MIGRATION_2_3, MIGRATION_3_4, MIGRATION_4_5,
                MIGRATION_5_6, MIGRATION_6_7)
              .build()
        }
      }
      return INSTANCE
    }

    private val MIGRATION_1_2 = object : Migration(1, 2) {
      override fun migrate(database: SupportSQLiteDatabase) {
        database.execSQL("CREATE TABLE IF NOT EXISTS `LocalDownloadEvent` (`id` INTEGER, `album_id` TEXT, " +
            "`playlist_id` TEXT, `music_id` TEXT, PRIMARY KEY(`id`))")

        database.execSQL("CREATE TABLE IF NOT EXISTS `CountLocalDownloadEvent` (`id` INTEGER, `album_id` TEXT, " +
            "`playlist_id` TEXT, `music_id` TEXT, `qty` INTEGER, PRIMARY KEY(`id`))")
      }
    }

    private val MIGRATION_2_3 = object : Migration(2, 3) {
      override fun migrate(database: SupportSQLiteDatabase) {
        database.execSQL("ALTER TABLE `OfflineMedia` ADD COLUMN `is_external` INTEGER DEFAULT 0 NOT NULL")
        database.execSQL("ALTER TABLE `OfflineMedia` ADD COLUMN `index_position` INTEGER DEFAULT -1 NOT NULL")
        database.execSQL("ALTER TABLE `OfflineMedia` ADD COLUMN `created_time` INTEGER DEFAULT -1 NOT NULL")
        database.execSQL("ALTER TABLE `OfflineAlbum` ADD COLUMN `created_time` INTEGER DEFAULT -1 NOT NULL")
        database.execSQL("ALTER TABLE `OfflinePlaylist` ADD COLUMN `created_time` INTEGER DEFAULT -1 NOT NULL")
      }
    }

    private val MIGRATION_3_4 = object : Migration(3, 4) {
      override fun migrate(database: SupportSQLiteDatabase) {
        //NEED CAUSE A BUG OF MIGRATION
      }
    }

    private val MIGRATION_4_5 = object : Migration(4, 5) {
      override fun migrate(database: SupportSQLiteDatabase) {
        database.execSQL("CREATE TABLE IF NOT EXISTS `OfflineSimpleProfile` " +
          "(`id` TEXT NOT NULL, " +
          "`name` TEXT NOT NULL, " +
          "`profile_cover` TEXT NOT NULL, " +
          "`photo` TEXT NOT NULL, " +
          "`excluded` TEXT NOT NULL, " +
          "`is_following` INTEGER NOT NULL, " +
          "`is_verified` INTEGER NOT NULL, " +
          "`is_processing_follow_action` INTEGER NOT NULL, " +
          "PRIMARY KEY(`id`))")
      }
    }


    private val MIGRATION_5_6 = object : Migration(5, 6) {
      override fun migrate(database: SupportSQLiteDatabase) {
        database.execSQL("CREATE TABLE IF NOT EXISTS `MusicNotDownload` " +
          "(`id` TEXT NOT NULL, " +
          "`file` TEXT NOT NULL, " +
          "`music_name` TEXT NOT NULL, " +
          "`title` TEXT NOT NULL, " +
          "`plays` TEXT NOT NULL, " +
          " `path` TEXT NOT NULL, " +
          "`stream` TEXT NOT NULL, " +
          "`cover` TEXT NOT NULL, " +
          "`owner` TEXT NOT NULL, " +
          " `artist` TEXT NOT NULL, " +
          "`name_artist` TEXT NOT NULL, " +
          " `album_id` TEXT NOT NULL, " +
          " `album` TEXT NOT NULL, " +
          " `media_type` TEXT NOT NULL, " +
          "`is_downloadable` INTEGER NOT NULL, " +
          "`play_list_id` TEXT NOT NULL, " +
          "`share_url` TEXT NOT NULL, " +
          "`play_list_name` TEXT NOT NULL, " +
          "`play_list_author_name` TEXT NOT NULL, " +
          "`play_list_author_id` TEXT NOT NULL, " +
          "`play_list_cover_url` TEXT NOT NULL, " +
          "`is_verified` INTEGER NOT NULL, " +
          "`position` INTEGER NOT NULL, " +
          "PRIMARY KEY(`id`))")
      }
    }

    private val MIGRATION_6_7 = object : Migration(6, 7) {
      override fun migrate(database: SupportSQLiteDatabase) {
        database.execSQL("ALTER TABLE `OfflineMedia` ADD COLUMN `stream` TEXT DEFAULT '' NOT NULL")
      }
    }
  }
}
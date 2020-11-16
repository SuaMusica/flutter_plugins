package com.suamusica.mediascanner.db

import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper

class ScannedMediaDbHelper(
        context: android.content.Context,
        dbName: String,
        dbVersion: Int):
        SQLiteOpenHelper(context, dbName, null, dbVersion) {
    override fun onCreate(db: SQLiteDatabase?) {
        // We gonna use the OneApp DB
    }

    override fun onUpgrade(db: SQLiteDatabase?, oldVersion: Int, newVersion: Int) {
        // We gonna use the OneApp DB
    }
}
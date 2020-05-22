package com.suamusica.migration;

import android.content.Context
import android.content.SharedPreferences

private const val PREFERENCES_FILE_KEY = "suamusica.suamusicaapp.prefs_file"

class SharedPreferences constructor(context: Context) {
    
    private lateinit var sharedPreferences: SharedPreferences

    private val USER_ID_KEY = "userid"
    private val USER_NAME_KEY = "USER_NAME_KEY"
    private val USER_AGE_KEY = "USER_AGE_KEY"
    private val USER_GENDER_KEY = "USER_GENDER_KEY"
    private val USER_PROFILE_COVER_KEY = "USER_PROFILE_COVER_KEY"
    private val USER_CURRENT_JWT = "USER_CURRENT_JWT"

    init {
        sharedPreferences = context.getSharedPreferences(PREFERENCES_FILE_KEY, Context.MODE_PRIVATE)
    }

    fun isLogged() =
            sharedPreferences.contains(USER_ID_KEY) &&
                    getStringValue(USER_ID_KEY).isNullOrBlank().not()

    fun getUserId(): String? =
            if (sharedPreferences.contains(USER_ID_KEY))
                getStringValue(USER_ID_KEY)
            else null

    fun getName(): String? =
            if (sharedPreferences.contains(USER_ID_KEY))
                getStringValue(USER_NAME_KEY)
            else null

    fun getProfileCover(): String? =
            if (sharedPreferences.contains(USER_ID_KEY))
                getStringValue(USER_PROFILE_COVER_KEY)
            else null

    fun getGender(): String? =
            if (sharedPreferences.contains(USER_ID_KEY))
                getStringValue(USER_GENDER_KEY)
            else null

    fun getAge(): Int? =
            if (sharedPreferences.contains(USER_ID_KEY))
                getIntValue(USER_AGE_KEY)
            else null

    private fun getStringValue(key: String) = sharedPreferences.getString(key, "")

    private fun getIntValue(key: String) = sharedPreferences.getInt(key, 0)
}


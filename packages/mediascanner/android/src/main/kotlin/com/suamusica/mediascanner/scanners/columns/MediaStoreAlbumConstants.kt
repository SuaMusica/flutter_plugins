package com.suamusica.mediascanner.scanners.columns

import android.net.Uri
import android.os.Build
import android.provider.MediaStore

interface MediaStoreAlbumConstants {
    val uri: Uri
        get() = MediaStore.Audio.Albums.EXTERNAL_CONTENT_URI
    val columns: Array<String>
    val albumId: String
    val albumArt: String

    companion object {
        fun get(): MediaStoreAlbumConstants {
            if (Build.VERSION.SDK_INT < 29) {
                return MediaStoreAlbumConstantsLTApi29()
            }

            return MediaStoreAlbumConstantsGTApi29()
        }
    }
}
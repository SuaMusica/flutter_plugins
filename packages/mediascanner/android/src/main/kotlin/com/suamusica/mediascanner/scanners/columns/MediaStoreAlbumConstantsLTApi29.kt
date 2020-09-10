package com.suamusica.mediascanner.scanners.columns

import android.provider.MediaStore.Audio.Albums

open class MediaStoreAlbumConstantsLTApi29 : MediaStoreAlbumConstants {

    override val albumId: String get() = Albums._ID
    override val albumArt: String get() = Albums.ALBUM_ART

    override val columns get() = arrayOf(
        albumId,
        albumArt
    )
}
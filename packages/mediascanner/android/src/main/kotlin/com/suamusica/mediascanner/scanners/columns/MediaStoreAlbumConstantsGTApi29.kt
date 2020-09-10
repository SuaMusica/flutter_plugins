package com.suamusica.mediascanner.scanners.columns

import android.provider.MediaStore.Audio.Albums

class MediaStoreAlbumConstantsGTApi29 : MediaStoreAlbumConstantsLTApi29() {
    override val albumId: String get() = Albums.ALBUM_ID
}
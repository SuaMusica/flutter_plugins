package br.com.suamusica.player

import android.graphics.Bitmap
import android.net.Uri
import android.support.v4.media.MediaBrowserCompat.MediaItem
import android.support.v4.media.MediaDescriptionCompat
import android.support.v4.media.MediaMetadataCompat
import android.support.v4.media.MediaMetadataCompat.*
import android.util.Log
import androidx.collection.ArrayMap

inline val MediaMetadataCompat.METADATA_KEY_IS_VERIFIED: String
    get() = "android.media.metadata.METADATA_KEY_IS_VERIFIED"

inline val MediaMetadataCompat.METADATA_KEY_SHARE_URL: String
    get() = "android.media.metadata.METADATA_KEY_SHARE_URL"

inline val MediaMetadataCompat.METADATA_KEY_ALBUM_ID: String
    get() = "android.media.metadata.METADATA_KEY_ALBUM_ID"

inline val MediaMetadataCompat.METADATA_KEY_PLAYLIST_ID: String
    get() = "android.media.metadata.METADATA_KEY_PLAYLIST_ID"

inline val MediaMetadataCompat.METADATA_KEY_ARTIST_ID: String
    get() = "android.media.metadata.METADATA_KEY_ARTIST_ID"

inline val MediaMetadataCompat.id get() = getString(METADATA_KEY_MEDIA_ID) ?: ""

inline val MediaMetadataCompat.title get() = getString(METADATA_KEY_TITLE) ?: ""

inline val MediaMetadataCompat.artist get() = getString(METADATA_KEY_ARTIST) ?: ""

inline val MediaMetadataCompat.duration
    get() = getLong(MediaMetadataCompat.METADATA_KEY_DURATION) ?: 0

inline val MediaMetadataCompat.album get() = getString(METADATA_KEY_ALBUM) ?: ""

inline val MediaMetadataCompat.author get() = getString(METADATA_KEY_AUTHOR) ?: ""

inline val MediaMetadataCompat.writer get() = getString(METADATA_KEY_WRITER) ?: ""

inline val MediaMetadataCompat.composer get() = getString(METADATA_KEY_COMPOSER) ?: ""

inline val MediaMetadataCompat.compilation
    get() = getString(METADATA_KEY_COMPILATION) ?: ""

inline val MediaMetadataCompat.date get() = getString(METADATA_KEY_DATE) ?: ""

inline val MediaMetadataCompat.year get() = getString(METADATA_KEY_YEAR) ?: ""

inline val MediaMetadataCompat.genre get() = getString(METADATA_KEY_GENRE) ?: ""

inline val MediaMetadataCompat.trackNumber
    get() = getLong(METADATA_KEY_TRACK_NUMBER)

inline val MediaMetadataCompat.trackCount
    get() = getLong(METADATA_KEY_NUM_TRACKS)

inline val MediaMetadataCompat.discNumber
    get() = getLong(MediaMetadataCompat.METADATA_KEY_DISC_NUMBER)

inline val MediaMetadataCompat.albumArtist
    get() = getString(METADATA_KEY_ALBUM_ARTIST) ?: ""

inline val MediaMetadataCompat.art get(): Bitmap? = getBitmap(MediaMetadataCompat.METADATA_KEY_ART)

inline val MediaMetadataCompat.artUri
    get() = Uri.parse(this.getString(METADATA_KEY_ART_URI) ?: "")

inline val MediaMetadataCompat.albumArt
    get(): Bitmap? = getBitmap(MediaMetadataCompat.METADATA_KEY_ALBUM_ART)

inline val MediaMetadataCompat.albumArtUri
    get() = Uri.parse(this.getString(METADATA_KEY_ALBUM_ART_URI) ?: "")

inline val MediaMetadataCompat.userRating
    get() = getLong(MediaMetadataCompat.METADATA_KEY_USER_RATING)

inline val MediaMetadataCompat.rating get() = getLong(MediaMetadataCompat.METADATA_KEY_RATING)

inline val MediaMetadataCompat.displayTitle
    get() = getString(METADATA_KEY_DISPLAY_TITLE)

inline val MediaMetadataCompat.displaySubtitle
    get() = getString(METADATA_KEY_DISPLAY_SUBTITLE)

inline val MediaMetadataCompat.displayDescription
    get() = getString(METADATA_KEY_DISPLAY_DESCRIPTION)

inline val MediaMetadataCompat.displayIcon
    get() = getBitmap(METADATA_KEY_DISPLAY_ICON)

inline val MediaMetadataCompat.displayIconUri
    get() = Uri.parse(this.getString(METADATA_KEY_DISPLAY_ICON_URI) ?: "")

inline val MediaMetadataCompat.mediaUri
    get() = Uri.parse(this.getString(METADATA_KEY_MEDIA_URI) ?: "")

inline val MediaMetadataCompat.downloadStatus
    get() = getLong(METADATA_KEY_DOWNLOAD_STATUS)

inline val MediaMetadataCompat.isVerified
    get(): Boolean = getString("METADATA_KEY_IS_VERIFIED") ?: "0" == "1"

inline val MediaMetadataCompat.shareUrl
    get() = this.getString("METADATA_KEY_SHARE_URL")

inline val MediaMetadataCompat.albumId
    get() = this.getString("METADATA_KEY_ALBUM_ID")

inline val MediaMetadataCompat.playlistId
    get() = getString("METADATA_KEY_PLAYLIST_ID")

inline val MediaMetadataCompat.artistId
    get() = getString("METADATA_KEY_ARTIST_ID")

// @MediaItem.Flags
inline val MediaMetadataCompat.flag
    get() = this.getLong(METADATA_KEY_UAMP_FLAGS).toInt()

/**
 * Useful extensions for [MediaMetadataCompat.Builder].
 */

// These do not have getters, so create a message for the error.
const val NO_GET = "Property does not have a 'get'"

inline var Builder.id: String
    @Deprecated(NO_GET, level = DeprecationLevel.ERROR)
    get() = throw IllegalAccessException("Cannot get from MediaMetadataCompat.Builder")
    set(value) {
        putString(METADATA_KEY_MEDIA_ID, value)
    }

inline var Builder.title: String?
    @Deprecated(NO_GET, level = DeprecationLevel.ERROR)
    get() = throw IllegalAccessException("Cannot get from MediaMetadataCompat.Builder")
    set(value) {
        putString(METADATA_KEY_TITLE, value)
    }

inline var Builder.artist: String?
    @Deprecated(NO_GET, level = DeprecationLevel.ERROR)
    get() = throw IllegalAccessException("Cannot get from MediaMetadataCompat.Builder")
    set(value) {
        putString(METADATA_KEY_ARTIST, value)
    }

inline var Builder.album: String?
    @Deprecated(NO_GET, level = DeprecationLevel.ERROR)
    get() = throw IllegalAccessException("Cannot get from MediaMetadataCompat.Builder")
    set(value) {
        putString(METADATA_KEY_ALBUM, value)
    }

inline var Builder.duration: Long
    @Deprecated(NO_GET, level = DeprecationLevel.ERROR)
    get() = throw IllegalAccessException("Cannot get from MediaMetadataCompat.Builder")
    set(value) {
        putLong(MediaMetadataCompat.METADATA_KEY_DURATION, value)
    }

inline var Builder.genre: String?
    @Deprecated(NO_GET, level = DeprecationLevel.ERROR)
    get() = throw IllegalAccessException("Cannot get from MediaMetadataCompat.Builder")
    set(value) {
        putString(METADATA_KEY_GENRE, value)
    }

inline var Builder.mediaUri: String?
    @Deprecated(NO_GET, level = DeprecationLevel.ERROR)
    get() = throw IllegalAccessException("Cannot get from MediaMetadataCompat.Builder")
    set(value) {
        putString(METADATA_KEY_MEDIA_URI, value)
    }

inline var Builder.albumArtUri: String?
    @Deprecated(NO_GET, level = DeprecationLevel.ERROR)
    get() = throw IllegalAccessException("Cannot get from MediaMetadataCompat.Builder")
    set(value) {
        putString(METADATA_KEY_ALBUM_ART_URI, value)
    }

inline var Builder.albumArt: Bitmap?
    @Deprecated(NO_GET, level = DeprecationLevel.ERROR)
    get() = throw IllegalAccessException("Cannot get from MediaMetadataCompat.Builder")
    set(value) {
        putBitmap(MediaMetadataCompat.METADATA_KEY_ALBUM_ART, value)
    }

inline var Builder.trackNumber: Long
    @Deprecated(NO_GET, level = DeprecationLevel.ERROR)
    get() = throw IllegalAccessException("Cannot get from MediaMetadataCompat.Builder")
    set(value) {
        putLong(METADATA_KEY_TRACK_NUMBER, value)
    }

inline var Builder.trackCount: Long
    @Deprecated(NO_GET, level = DeprecationLevel.ERROR)
    get() = throw IllegalAccessException("Cannot get from MediaMetadataCompat.Builder")
    set(value) {
        putLong(METADATA_KEY_NUM_TRACKS, value)
    }

inline var Builder.displayTitle: String?
    @Deprecated(NO_GET, level = DeprecationLevel.ERROR)
    get() = throw IllegalAccessException("Cannot get from MediaMetadataCompat.Builder")
    set(value) {
        putString(METADATA_KEY_DISPLAY_TITLE, value)
    }

inline var Builder.displaySubtitle: String?
    @Deprecated(NO_GET, level = DeprecationLevel.ERROR)
    get() = throw IllegalAccessException("Cannot get from MediaMetadataCompat.Builder")
    set(value) {
        putString(METADATA_KEY_DISPLAY_SUBTITLE, value)
    }

inline var Builder.displayDescription: String?
    @Deprecated(NO_GET, level = DeprecationLevel.ERROR)
    get() = throw IllegalAccessException("Cannot get from MediaMetadataCompat.Builder")
    set(value) {
        putString(METADATA_KEY_DISPLAY_DESCRIPTION, value)
    }

inline var Builder.displayIconUri: String?
    @Deprecated(NO_GET, level = DeprecationLevel.ERROR)
    get() = throw IllegalAccessException("Cannot get from MediaMetadataCompat.Builder")
    set(value) {
        putString(METADATA_KEY_DISPLAY_ICON_URI, value)
    }

inline var Builder.downloadStatus: Long
    @Deprecated(NO_GET, level = DeprecationLevel.ERROR)
    get() = throw IllegalAccessException("Cannot get from MediaMetadataCompat.Builder")
    set(value) {
        putLong(METADATA_KEY_DOWNLOAD_STATUS, value)
    }

inline var Builder.compilation: String?
    @Deprecated(NO_GET, level = DeprecationLevel.ERROR)
    get() = throw IllegalAccessException("Cannot get from MediaMetadataCompat.Builder")
    set(value) {
        putString(METADATA_KEY_COMPILATION, value)
    }

inline var Builder.isVerified: Boolean?
    @Deprecated(NO_GET, level = DeprecationLevel.ERROR)
    get() = throw IllegalAccessException("Cannot get from MediaMetadataCompat.Builder")
    set(value) {
        putString("METADATA_KEY_IS_VERIFIED", if (value == true) "1" else "0")
    }

inline var Builder.shareUrl: String?
    @Deprecated(NO_GET, level = DeprecationLevel.ERROR)
    get() = throw IllegalAccessException("Cannot get from MediaMetadataCompat.Builder")
    set(value) {
        putString("METADATA_KEY_SHARE_URL", value)
    }

inline var Builder.albumId: String?
    @Deprecated(NO_GET, level = DeprecationLevel.ERROR)
    get() = throw IllegalAccessException("Cannot get from MediaMetadataCompat.Builder")
    set(value) {
        putString("METADATA_KEY_ALBUM_ID", value)
    }

inline var Builder.playlistId: String?
    @Deprecated(NO_GET, level = DeprecationLevel.ERROR)
    get() = throw IllegalAccessException("Cannot get from MediaMetadataCompat.Builder")
    set(value) {
        putString("METADATA_KEY_PLAYLIST_ID", value)
    }

inline var Builder.artistId: String?
    @Deprecated(NO_GET, level = DeprecationLevel.ERROR)
    get() = throw IllegalAccessException("Cannot get from MediaMetadataCompat.Builder")
    set(value) {
        putString("METADATA_KEY_ARTIST_ID", value)
    }

/**
 * Custom property for storing whether a [MediaMetadataCompat] item represents an
 * item that is [MediaItem.FLAG_BROWSABLE] or [MediaItem.FLAG_PLAYABLE].
 */
// @MediaItem.Flags
inline var Builder.flag: Int
    @Deprecated(NO_GET, level = DeprecationLevel.ERROR)
    get() = throw IllegalAccessException("Cannot get from MediaMetadataCompat.Builder")
    set(value) {
        putLong(METADATA_KEY_UAMP_FLAGS, value.toLong())
    }

/**
 * Custom property for retrieving a [MediaDescriptionCompat] which also includes
 * all of the keys from the [MediaMetadataCompat] object in its extras.
 *
 * These keys are used by the ExoPlayer MediaSession extension when announcing metadata changes.
 */
inline val MediaMetadataCompat.fullDescription
    get() =
        description.also {
            it.extras?.putAll(bundle)
        }

fun MediaMetadataCompat.toMap(): Map<String, Any?> {
    val mutableMap = mutableMapOf<String, Any?>()

    this.let { extras ->
        val keySet = extras.keySet()
        val iterator = keySet.iterator()
        val metadataTypeLong = 0
        val metadataTypeText = 1
        val metadataTypeBitmap = 2
        val metadataTypeRating = 3

        val metadataKeyType = ArrayMap<String, Int>()
        metadataKeyType[METADATA_KEY_TITLE] = metadataTypeText
        metadataKeyType[METADATA_KEY_ARTIST] = metadataTypeText
        metadataKeyType[METADATA_KEY_ALBUM] = metadataTypeText
        metadataKeyType[METADATA_KEY_AUTHOR] = metadataTypeText
        metadataKeyType[METADATA_KEY_WRITER] = metadataTypeText
        metadataKeyType[METADATA_KEY_COMPOSER] = metadataTypeText
        metadataKeyType[METADATA_KEY_COMPILATION] = metadataTypeText
        metadataKeyType[METADATA_KEY_DATE] = metadataTypeText
        metadataKeyType[METADATA_KEY_GENRE] = metadataTypeText
        metadataKeyType[METADATA_KEY_ALBUM_ARTIST] = metadataTypeText
        metadataKeyType[METADATA_KEY_ART_URI] = metadataTypeText
        metadataKeyType[METADATA_KEY_ALBUM_ART_URI] = metadataTypeText
        metadataKeyType[METADATA_KEY_DISPLAY_TITLE] = metadataTypeText
        metadataKeyType[METADATA_KEY_DISPLAY_SUBTITLE] = metadataTypeText
        metadataKeyType[METADATA_KEY_DISPLAY_DESCRIPTION] = metadataTypeText
        metadataKeyType[METADATA_KEY_DISPLAY_ICON_URI] = metadataTypeText
        metadataKeyType[METADATA_KEY_MEDIA_ID] = metadataTypeText
        metadataKeyType[METADATA_KEY_MEDIA_URI] = metadataTypeText
        metadataKeyType[METADATA_KEY_DURATION] = metadataTypeLong
        metadataKeyType[METADATA_KEY_YEAR] = metadataTypeLong
        metadataKeyType[METADATA_KEY_TRACK_NUMBER] = metadataTypeLong
        metadataKeyType[METADATA_KEY_NUM_TRACKS] = metadataTypeLong
        metadataKeyType[METADATA_KEY_DISC_NUMBER] = metadataTypeLong
        metadataKeyType[METADATA_KEY_BT_FOLDER_TYPE] = metadataTypeLong
        metadataKeyType[METADATA_KEY_ADVERTISEMENT] = metadataTypeLong
        metadataKeyType[METADATA_KEY_DOWNLOAD_STATUS] = metadataTypeLong
        metadataKeyType[METADATA_KEY_ART] = metadataTypeBitmap
        metadataKeyType[METADATA_KEY_ALBUM_ART] = metadataTypeBitmap
        metadataKeyType[METADATA_KEY_DISPLAY_ICON] = metadataTypeBitmap
        metadataKeyType[METADATA_KEY_USER_RATING] = metadataTypeRating
        metadataKeyType[METADATA_KEY_RATING] = metadataTypeRating


        while (iterator.hasNext()) {
            val key = iterator.next()
            when (metadataKeyType[key]) {
                metadataTypeLong -> mutableMap[key] = extras.getLong(key)
                metadataTypeText -> mutableMap[key] = extras.getString(key)
                metadataTypeRating -> mutableMap[key] = extras.getRating(key)
                metadataTypeBitmap -> Log.d("MediaMetadataCompat", "toMap - ignoring Bitmap.")
                else -> Log.d("MediaMetadataCompat", "toMap - ignoring ${metadataKeyType[key]}.")
            }
        }
    }

    return mutableMap.toMap()
}


/**
 * Custom property that holds whether an item is [MediaItem.FLAG_BROWSABLE] or
 * [MediaItem.FLAG_PLAYABLE].
 */
const val METADATA_KEY_UAMP_FLAGS = "com.example.android.uamp.media.METADATA_KEY_UAMP_FLAGS"
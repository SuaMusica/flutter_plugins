package com.suamusica.mediascanner.scanners

import android.content.Context
import android.database.Cursor
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Build
import android.provider.MediaStore.Audio
import com.suamusica.mediascanner.input.MediaType
import com.suamusica.mediascanner.model.Album
import com.suamusica.mediascanner.output.ScannedMediaOutput
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import timber.log.Timber
import com.mpatric.mp3agic.ID3v1Tag;
import com.mpatric.mp3agic.ID3v24Tag;
import com.mpatric.mp3agic.InvalidDataException;
import com.mpatric.mp3agic.Mp3File;
import com.mpatric.mp3agic.NotSupportedException;
import com.mpatric.mp3agic.UnsupportedTagException;
import com.suamusica.mediascanner.db.ScannedMediaRepository

class AudioMediaScannerExtractor(private val context: Context) : MediaScannerExtractor {
    override val mediaType: MediaType = MediaType.AUDIO

    override val uri = Audio.Media.EXTERNAL_CONTENT_URI!!

    override val columns = arrayOf(
            Audio.Media.TITLE,
            Audio.Media.TRACK,
            Audio.Media.ARTIST,
            Audio.Media.ALBUM_ID,
            Audio.Media.ALBUM,
            Audio.Media.DATA,
            Audio.Media.DATE_ADDED,
            Audio.Media.DATE_MODIFIED,
            Audio.Media._ID
    )

    override val selection: String = Audio.Media.IS_MUSIC + " != 0"

    override val selectionArgs: Array<String> = arrayOf()

    override val sortOrder: String? = null

    private val albumColumns = arrayOf(
            Audio.Albums._ID,
            Audio.Albums.ALBUM_ART
    )

    private val albumCache = mutableMapOf<Long, Album?>()

    private fun getSuaMusicaId(path: String): Long? {
        val id = path.substringBeforeLast(".").split("_").last().toLongOrNull()
        if (id != null && id > 1000) {
            return id
        }
        return null
    }

    override fun getScannedMediaFromCursor(cursor: Cursor,
                                           scannedMediaRepository: ScannedMediaRepository?): ScannedMediaOutput? {
        cursor.columnNames.forEach {
            Timber.d("Field $it: [${getString(cursor, it)}]")
        }
        var albumId = getLong(cursor, Audio.Media.ALBUM_ID)
        var playlistId = -1L;

        var musicId = getLong(cursor, Audio.Media._ID) * -1;
        val path = getString(cursor, Audio.Media.DATA)
        getSuaMusicaId(path)?.let {
            musicId = it
        }

        scannedMediaRepository?.let {
            if (it.mediaExists(mediaId = musicId, mediaPath = path.replace("/storage/emulated/0", ""))) {
                Timber.d("MediaScanner: Found that mediaId: $musicId with path $path was already processed")
                return null
            } else {
                Timber.d("MediaScanner: mediaId: $musicId with path $path was not processed")
            }
        }

        //TODO: otimizar MusicId + path sqlite @Nadilson
        var artist = getString(cursor, Audio.Media.ARTIST) {
            getString(cursor, Audio.Media.COMPOSER) {
                UNKNOWN_ARTIST
            }
        }
        artist = if (artist.trim().isBlank() || artist.contains("unknown", ignoreCase = true)) UNKNOWN_ARTIST else artist

        try {
            Timber.d("Opening MP3 file...")
            val mp3file = Mp3File(path)
            if (mp3file.hasId3v2Tag()) {
                Timber.d("Trying to read Id3 tags...")
                val id3v2Tag = mp3file.id3v2Tag;

                var url = id3v2Tag.url
                Timber.d("SM_URL: [$url]")
                if (url != null && url.isNotEmpty()) {
                    val uri = Uri.parse(url)
                    uri.getQueryParameter("playlistId")?.let { value ->
                        playlistId = value.toLong()
                    }
                    uri.getQueryParameter("albumId")?.let { value ->
                        albumId = value.toLong()
                    }
                    uri.getQueryParameter("musicId")?.let { value ->
                        musicId = value.toLong()
                    }
                }

                if (artist == UNKNOWN_ARTIST) {
                    if (id3v2Tag.albumArtist.isNotEmpty()) {
                        artist = id3v2Tag.albumArtist
                    }
                }
            } else {
                Timber.d("Id3 tags were not found $path")
            }
        } catch (e: Throwable) {
            Timber.e(e, "Failed to get ID3 tags. Ignoring...");
        }

        return ScannedMediaOutput(
                mediaId = musicId,
                title = getString(cursor, Audio.Media.TITLE) { getString(cursor, Audio.Media.DISPLAY_NAME) },
                artist = artist,
                albumId = albumId,
                playlistId = playlistId,
                album = getString(cursor, Audio.Media.ALBUM) { getString(cursor, "_description") },
                track = getString(cursor, Audio.Media.TRACK),
                path = path,
                albumCoverPath = getAlbumById(albumId, path)?.coverPath ?: "",
                createdAt = getLong(cursor, Audio.Media.DATE_ADDED),
                updatedAt = getLong(cursor, Audio.Media.DATE_MODIFIED)
        )
    }

    private fun getLong(cursor: Cursor, columnName: String, defaultValue: () -> Long = { 0 }): Long {
        return try {
            Timber.d("Getting the Column $columnName...")
            val value = cursor.getLongByColumnName(columnName)
            Timber.d("Got value [$value] for Column $columnName!")
            value
        } catch (e: Throwable) {
            Timber.e(e, "Failed to get value for column $columnName using default [$defaultValue]")
            defaultValue.invoke()
        }
    }

    private fun getString(cursor: Cursor, columnName: String, defaultValue: () -> String = { "" }): String {
        return try {
            Timber.d("Getting the Column $columnName...")
            val value = cursor.getStringByColumnName(columnName)
            Timber.d("Got value $value for Column $columnName!")
            value
        } catch (e: Throwable) {
            Timber.e(e, "Failed to get value for column $columnName using default $defaultValue")
            defaultValue.invoke()
        }
    }

    @Synchronized
    private fun getAlbumById(albumId: Long, filePath: String): Album? {
        if (albumId <= 0) {
            albumCache[albumId] = null
        }

        if (albumCache.containsKey(albumId)) {
            Timber.d("Album $albumId is present in cache")
            return albumCache[albumId]
        }

        Timber.d("Find album on android Media Store (albumId=$albumId)")

        val cursor = context.contentResolver.query(
                Audio.Albums.EXTERNAL_CONTENT_URI,
                albumColumns,
                Audio.Albums._ID + "=?",
                arrayOf(albumId.toString()),
                null
        )

        cursor?.use {
            if (it.moveToFirst()) {
                Timber.d("Album $albumId founded.")

                var coverPath = getString(it, Audio.Albums.ALBUM_ART)

                if (coverPath.isBlank() && Build.VERSION.SDK_INT > 28) {
                    Timber.d("Cover path is not present in MediaStore for albumId: $albumId")
                    coverPath = createCover(albumId, filePath)
                }

                return Album(coverPath = coverPath).also { album ->
                    albumCache[albumId] = album
                }
            }
        }

        Timber.d("Album $albumId not founded.")
        albumCache[albumId] = null
        return null
    }

    private fun createCover(albumId: Long, filePath: String): String {
        Timber.d("Trying create Album $albumId for file: $filePath")
        var coverPath = ""
        try {
            val mmr = MediaMetadataRetriever()
            mmr.setDataSource(filePath)
            mmr.embeddedPicture?.let {
                val cacheDir = context.cacheDir
                Timber.d("Creating cover on cache dir: $cacheDir")
                val outputFile = File.createTempFile("sm_$albumId", ".jpg", cacheDir)

                if (outputFile.exists())
                    outputFile.delete()

                val fos = FileOutputStream(outputFile.path)
                try {
                    fos.write(it)
                    fos.close()
                } catch (e: IOException) {
                    Timber.e(e, "Error")
                }
                coverPath = outputFile.path
                Timber.d("cover created: $coverPath")
            } ?: Timber.d("no has embeddedPicture.")
        } catch (t: Throwable) {
            Timber.e(t, "Error")
        }

        return coverPath
    }

    override fun delete(id: Long) {
        context.contentResolver.delete(
                Audio.Media.EXTERNAL_CONTENT_URI,
                Audio.Albums._ID + "=?",
                arrayOf(id.toString())
        )
    }

    companion object {
        const val UNKNOWN_ARTIST = "Artista Desconhecido"
    }
}
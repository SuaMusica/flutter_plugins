package br.com.suamusica.player

import android.util.Log
import androidx.media3.common.MediaItem
import androidx.media3.exoplayer.ExoPlayer

/**
 * Manages content synchronization between the main player and Android Auto
 */
class AndroidAutoContentManager(
    private val browseTree: AndroidAutoBrowseTree
) {
    companion object {
        private const val TAG = "AAContentManager"
    }

    /**
     * Syncs current player queue with Android Auto browse tree
     */
    fun syncPlayerQueue(player: ExoPlayer?) {
        player?.let { exoPlayer ->
            val currentItems = mutableListOf<MediaItem>()

            for (i in 0 until exoPlayer.mediaItemCount) {
                val mediaItem = exoPlayer.getMediaItemAt(i)
                currentItems.add(mediaItem)
            }

            if (currentItems.isNotEmpty()) {
                Log.d(TAG, "Syncing ${currentItems.size} items from player queue to Android Auto")
                
                // Update recent items with current queue
                browseTree.addChildren(AndroidAutoBrowseTree.RECENT_ID, currentItems)
                
                // Extract Media objects and group by album/artist if available
                val mediaObjects = mutableListOf<Media>()
                currentItems.forEach { mediaItem ->
                    val associatedMedia = mediaItem.associatedMedia
                    if (associatedMedia != null) {
                        mediaObjects.add(associatedMedia)
                    }
                }
                
                if (mediaObjects.isNotEmpty()) {
                    updateAlbumsAndArtists(mediaObjects)
                }
                
                Log.d(TAG, "Successfully synced ${currentItems.size} items to Android Auto")
            }
        } ?: run {
            Log.w(TAG, "Player is null, cannot sync queue to Android Auto")
        }
    }

    /**
     * Adds new media items to Android Auto browse tree
     */
    fun addMediaItems(medias: List<Media>) {
        val mediaItems = medias.map { media ->
            browseTree.createPlayableMediaItem(media)
        }

        // Add to recent items
        browseTree.addChildren(AndroidAutoBrowseTree.RECENT_ID, mediaItems)

        // Group by album for albums section
        val albumGroups = medias.groupBy { it.albumTitle }
        albumGroups.forEach { (albumName, albumTracks) ->
            if (albumName.isNotEmpty()) {
                val albumId = "album_${albumName.hashCode()}"
                val albumItem = browseTree.createBrowsableItem(
                    albumId,
                    albumName,
                    "${albumTracks.size} faixas"
                )
                browseTree.addMediaItem(albumItem)

                val albumMediaItems = albumTracks.map { track ->
                    browseTree.createPlayableMediaItem(track)
                }
                browseTree.addChildren(albumId, albumMediaItems)
            }
        }

        // Group by artist for artists section
        val artistGroups = medias.groupBy { it.author }
        artistGroups.forEach { (artistName, artistTracks) ->
            if (artistName.isNotEmpty()) {
                val artistId = "artist_${artistName.hashCode()}"
                val artistItem = browseTree.createBrowsableItem(
                    artistId,
                    artistName,
                    "${artistTracks.size} faixas"
                )
                browseTree.addMediaItem(artistItem)

                val artistMediaItems = artistTracks.map { track ->
                    browseTree.createPlayableMediaItem(track)
                }
                browseTree.addChildren(artistId, artistMediaItems)
            }
        }

        Log.d(TAG, "Added ${medias.size} media items to Android Auto browse tree")
    }

    /**
     * Updates favorites in Android Auto
     */
    fun updateFavorites(favoriteMedias: List<Media>) {
        val favoriteItems = favoriteMedias.map { media ->
            browseTree.createPlayableMediaItem(media)
        }

        browseTree.addChildren(AndroidAutoBrowseTree.FAVORITES_ID, favoriteItems)
        Log.d(TAG, "Updated ${favoriteItems.size} favorite items in Android Auto")
    }

    /**
     * Updates albums and artists sections from media objects
     */
    private fun updateAlbumsAndArtists(medias: List<Media>) {
        // Group by album for albums section
        val albumGroups = medias.groupBy { it.albumTitle }
        val albumItems = mutableListOf<MediaItem>()
        
        albumGroups.forEach { (albumName, albumTracks) ->
            if (albumName.isNotEmpty()) {
                val albumId = "album_${albumName.hashCode()}"
                val albumItem = browseTree.createBrowsableItem(
                    albumId,
                    albumName,
                    "${albumTracks.size} faixas",
                    null,
                    androidx.media3.common.MediaMetadata.FOLDER_TYPE_ALBUMS
                )
                albumItems.add(albumItem)
                browseTree.addMediaItem(albumItem)

                val albumMediaItems = albumTracks.map { track ->
                    browseTree.createPlayableMediaItem(track)
                }
                browseTree.addAlbumTracks(albumId, albumMediaItems)
            }
        }
        
        // Update albums section
        if (albumItems.isNotEmpty()) {
            browseTree.addChildren(AndroidAutoBrowseTree.ALBUMS_ID, albumItems)
        }

        // Group by artist for artists section
        val artistGroups = medias.groupBy { it.author }
        val artistItems = mutableListOf<MediaItem>()
        
        artistGroups.forEach { (artistName, artistTracks) ->
            if (artistName.isNotEmpty()) {
                val artistId = "artist_${artistName.hashCode()}"
                val artistItem = browseTree.createBrowsableItem(
                    artistId,
                    artistName,
                    "${artistTracks.size} faixas",
                    null,
                    androidx.media3.common.MediaMetadata.FOLDER_TYPE_ARTISTS
                )
                artistItems.add(artistItem)
                browseTree.addMediaItem(artistItem)

                val artistMediaItems = artistTracks.map { track ->
                    browseTree.createPlayableMediaItem(track)
                }
                browseTree.addArtistTracks(artistId, artistMediaItems)
            }
        }
        
        // Update artists section
        if (artistItems.isNotEmpty()) {
            browseTree.addChildren(AndroidAutoBrowseTree.ARTISTS_ID, artistItems)
        }
    }

    /**
     * Clears all content from Android Auto browse tree
     */
    fun clearContent() {
        browseTree.addChildren(AndroidAutoBrowseTree.RECENT_ID, emptyList())
        browseTree.addChildren(AndroidAutoBrowseTree.PLAYLISTS_ID, emptyList())
        browseTree.addChildren(AndroidAutoBrowseTree.ALBUMS_ID, emptyList())
        browseTree.addChildren(AndroidAutoBrowseTree.ARTISTS_ID, emptyList())
        browseTree.addChildren(AndroidAutoBrowseTree.FAVORITES_ID, emptyList())
        Log.d(TAG, "Cleared all content from Android Auto browse tree")
    }
}
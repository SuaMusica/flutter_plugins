package br.com.suamusica.player

import android.content.Context
import android.net.Uri
import android.os.Bundle
import android.util.Log
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.common.MimeTypes
import androidx.media3.session.LibraryResult
import androidx.media3.session.MediaLibraryService
import androidx.media3.session.MediaSession
import com.google.common.collect.ImmutableList
import com.google.common.util.concurrent.Futures
import com.google.common.util.concurrent.ListenableFuture

/**
 * Manages the browsable media hierarchy for Android Auto
 */
class AndroidAutoBrowseTree(private val context: Context) {
    
    companion object {
        // Root IDs for navigation
        const val ROOT_ID = "__ROOT__"
        const val RECENT_ID = "__RECENT__"
        const val PLAYLISTS_ID = "__PLAYLISTS__"
        const val ALBUMS_ID = "__ALBUMS__"
        const val ARTISTS_ID = "__ARTISTS__"
        const val FAVORITES_ID = "__FAVORITES__"
        
        // Media item storage
        private val mediaIdToChildren = mutableMapOf<String, MutableList<MediaItem>>()
        private val mediaIdToItem = mutableMapOf<String, MediaItem>()
        
        // Content storage
        private val recentItems = mutableListOf<MediaItem>()
        private val playlistItems = mutableListOf<MediaItem>()
        private val albumItems = mutableListOf<MediaItem>()
        private val artistItems = mutableListOf<MediaItem>()
        private val favoriteItems = mutableListOf<MediaItem>()
        
        // Data caches for search
        private val allPlayableItems = mutableListOf<MediaItem>()
        private val albumToTracks = mutableMapOf<String, MutableList<MediaItem>>()
        private val artistToTracks = mutableMapOf<String, MutableList<MediaItem>>()
        private val playlistToTracks = mutableMapOf<String, MutableList<MediaItem>>()
    }
    
    init {
        buildMediaHierarchy()
    }
    
    /**
     * Builds the initial media hierarchy for Android Auto
     */
    private fun buildMediaHierarchy() {
        // Create root items
        val rootItems = mutableListOf<MediaItem>()
        
        // Recent
        val recentItem = MediaItem.Builder()
            .setMediaId(RECENT_ID)
            .setMediaMetadata(
                MediaMetadata.Builder()
                    .setTitle("Recentes")
                    .setIsBrowsable(true)
                    .setIsPlayable(false)
                    .setFolderType(MediaMetadata.FOLDER_TYPE_MIXED)
                    .build()
            )
            .build()
        rootItems.add(recentItem)
        mediaIdToItem[RECENT_ID] = recentItem
        
        // Playlists
        val playlistsItem = MediaItem.Builder()
            .setMediaId(PLAYLISTS_ID)
            .setMediaMetadata(
                MediaMetadata.Builder()
                    .setTitle("Playlists")
                    .setIsBrowsable(true)
                    .setIsPlayable(false)
                    .setFolderType(MediaMetadata.FOLDER_TYPE_PLAYLISTS)
                    .build()
            )
            .build()
        rootItems.add(playlistsItem)
        mediaIdToItem[PLAYLISTS_ID] = playlistsItem
        
        // Albums
        val albumsItem = MediaItem.Builder()
            .setMediaId(ALBUMS_ID)
            .setMediaMetadata(
                MediaMetadata.Builder()
                    .setTitle("Álbuns")
                    .setIsBrowsable(true)
                    .setIsPlayable(false)
                    .setFolderType(MediaMetadata.FOLDER_TYPE_ALBUMS)
                    .build()
            )
            .build()
        rootItems.add(albumsItem)
        mediaIdToItem[ALBUMS_ID] = albumsItem
        
        // Artists
        val artistsItem = MediaItem.Builder()
            .setMediaId(ARTISTS_ID)
            .setMediaMetadata(
                MediaMetadata.Builder()
                    .setTitle("Artistas")
                    .setIsBrowsable(true)
                    .setIsPlayable(false)
                    .setFolderType(MediaMetadata.FOLDER_TYPE_ARTISTS)
                    .build()
            )
            .build()
        rootItems.add(artistsItem)
        mediaIdToItem[ARTISTS_ID] = artistsItem
        
        // Favorites
        val favoritesItem = MediaItem.Builder()
            .setMediaId(FAVORITES_ID)
            .setMediaMetadata(
                MediaMetadata.Builder()
                    .setTitle("Favoritos")
                    .setIsBrowsable(true)
                    .setIsPlayable(false)
                    .setFolderType(MediaMetadata.FOLDER_TYPE_MIXED)
                    .build()
            )
            .build()
        rootItems.add(favoritesItem)
        mediaIdToItem[FAVORITES_ID] = favoritesItem
        
        // Store root children
        mediaIdToChildren[ROOT_ID] = rootItems
        
        // Initialize empty collections for each section
        mediaIdToChildren[RECENT_ID] = recentItems
        mediaIdToChildren[PLAYLISTS_ID] = playlistItems
        mediaIdToChildren[ALBUMS_ID] = albumItems
        mediaIdToChildren[ARTISTS_ID] = artistItems
        mediaIdToChildren[FAVORITES_ID] = favoriteItems
    }
    
    /**
     * Gets the root media item for Android Auto
     */
    fun getRoot(): MediaItem {
        return MediaItem.Builder()
            .setMediaId(ROOT_ID)
            .setMediaMetadata(
                MediaMetadata.Builder()
                    .setTitle("SuaMusica")
                    .setIsBrowsable(true)
                    .setIsPlayable(false)
                    .build()
            )
            .build()
    }
    
    /**
     * Gets children for a given parent ID
     */
    fun getChildren(parentId: String): List<MediaItem> {
        return when (parentId) {
            ROOT_ID -> mediaIdToChildren[ROOT_ID] ?: emptyList()
            RECENT_ID -> getRecentItems()
            PLAYLISTS_ID -> getPlaylistItems()
            ALBUMS_ID -> getAlbumItems()
            ARTISTS_ID -> getArtistItems()
            FAVORITES_ID -> getFavoriteItems()
            else -> {
                // Check if it's a specific playlist, album, or artist
                getSpecificItems(parentId)
            }
        }
    }
    
    /**
     * Gets a specific media item by ID
     */
    fun getItem(mediaId: String): MediaItem? {
        return mediaIdToItem[mediaId]
    }
    
    /**
     * Adds a media item to the tree
     */
    fun addMediaItem(mediaItem: MediaItem) {
        mediaIdToItem[mediaItem.mediaId] = mediaItem
        
        // Add to searchable items if it's playable
        if (mediaItem.mediaMetadata.isPlayable == true) {
            synchronized(allPlayableItems) {
                // Remove existing item with same ID
                allPlayableItems.removeAll { it.mediaId == mediaItem.mediaId }
                allPlayableItems.add(mediaItem)
            }
        }
    }
    
    /**
     * Adds children to a parent
     */
    fun addChildren(parentId: String, children: List<MediaItem>) {
        val childrenList = children.toMutableList()
        mediaIdToChildren[parentId] = childrenList
        
        children.forEach { child ->
            mediaIdToItem[child.mediaId] = child
            
            // Add to searchable items if it's playable
            if (child.mediaMetadata.isPlayable == true) {
                synchronized(allPlayableItems) {
                    // Remove existing item with same ID
                    allPlayableItems.removeAll { it.mediaId == child.mediaId }
                    allPlayableItems.add(child)
                }
            }
        }
        
        // Update specific collections based on parent ID
        when (parentId) {
            RECENT_ID -> {
                synchronized(recentItems) {
                    recentItems.clear()
                    recentItems.addAll(childrenList)
                }
            }
            PLAYLISTS_ID -> {
                synchronized(playlistItems) {
                    playlistItems.clear()
                    playlistItems.addAll(childrenList)
                }
            }
            ALBUMS_ID -> {
                synchronized(albumItems) {
                    albumItems.clear()
                    albumItems.addAll(childrenList)
                }
            }
            ARTISTS_ID -> {
                synchronized(artistItems) {
                    artistItems.clear()
                    artistItems.addAll(childrenList)
                }
            }
            FAVORITES_ID -> {
                synchronized(favoriteItems) {
                    favoriteItems.clear()
                    favoriteItems.addAll(childrenList)
                }
            }
            else -> {
                // For specific album/artist/playlist content
                when {
                    parentId.startsWith("album_") -> {
                        albumToTracks[parentId] = childrenList
                    }
                    parentId.startsWith("artist_") -> {
                        artistToTracks[parentId] = childrenList
                    }
                    parentId.startsWith("playlist_") -> {
                        playlistToTracks[parentId] = childrenList
                    }
                }
            }
        }
    }
    
    /**
     * Creates a playable media item from Media object
     */
    fun createPlayableMediaItem(media: Media): MediaItem {
        val artworkUri = try {
            if (media.bigCoverUrl.isNotEmpty()) Uri.parse(media.bigCoverUrl) else null
        } catch (e: Exception) {
            null
        }
        
        val metadata = MediaMetadata.Builder()
            .setTitle(media.name)
            .setArtist(media.author)
            .setAlbumTitle(media.albumTitle)
            .setArtworkUri(artworkUri)
            .setIsBrowsable(false)
            .setIsPlayable(true)
            .build()
        
        return MediaItem.Builder()
            .setMediaId(media.id.toString())
            .setUri(Uri.parse(media.url))
            .setMediaMetadata(metadata)
            .setMimeType(MimeTypes.AUDIO_MPEG)
            .build()
    }
    
    /**
     * Creates a browsable folder item
     */
    fun createBrowsableItem(
        id: String,
        title: String,
        subtitle: String? = null,
        artworkUri: Uri? = null,
        folderType: Int = MediaMetadata.FOLDER_TYPE_MIXED
    ): MediaItem {
        val metadata = MediaMetadata.Builder()
            .setTitle(title)
            .setSubtitle(subtitle)
            .setArtworkUri(artworkUri)
            .setIsBrowsable(true)
            .setIsPlayable(false)
            .setFolderType(folderType)
            .build()
        
        return MediaItem.Builder()
            .setMediaId(id)
            .setMediaMetadata(metadata)
            .build()
    }
    
    /**
     * Adds tracks to an album
     */
    fun addAlbumTracks(albumId: String, tracks: List<MediaItem>) {
        albumToTracks[albumId] = tracks.toMutableList()
        tracks.forEach { track ->
            mediaIdToItem[track.mediaId] = track
        }
    }
    
    /**
     * Adds tracks to an artist
     */
    fun addArtistTracks(artistId: String, tracks: List<MediaItem>) {
        artistToTracks[artistId] = tracks.toMutableList()
        tracks.forEach { track ->
            mediaIdToItem[track.mediaId] = track
        }
    }
    
    /**
     * Adds tracks to a playlist
     */
    fun addPlaylistTracks(playlistId: String, tracks: List<MediaItem>) {
        playlistToTracks[playlistId] = tracks.toMutableList()
        tracks.forEach { track ->
            mediaIdToItem[track.mediaId] = track
        }
    }
    
    // Private methods to get specific content types
    private fun getRecentItems(): List<MediaItem> {
        synchronized(recentItems) {
            return recentItems.toList()
        }
    }
    
    private fun getPlaylistItems(): List<MediaItem> {
        synchronized(playlistItems) {
            return playlistItems.toList()
        }
    }
    
    private fun getAlbumItems(): List<MediaItem> {
        synchronized(albumItems) {
            return albumItems.toList()
        }
    }
    
    private fun getArtistItems(): List<MediaItem> {
        synchronized(artistItems) {
            return artistItems.toList()
        }
    }
    
    private fun getFavoriteItems(): List<MediaItem> {
        synchronized(favoriteItems) {
            return favoriteItems.toList()
        }
    }
    
    private fun getSpecificItems(parentId: String): List<MediaItem> {
        return when {
            parentId.startsWith("album_") -> albumToTracks[parentId] ?: emptyList()
            parentId.startsWith("artist_") -> artistToTracks[parentId] ?: emptyList()
            parentId.startsWith("playlist_") -> playlistToTracks[parentId] ?: emptyList()
            else -> mediaIdToChildren[parentId] ?: emptyList()
        }
    }
    
    /**
     * Searches for media items
     */
    fun search(query: String): List<MediaItem> {
        if (query.isBlank()) return emptyList()
        
        val queryLowerCase = query.lowercase().trim()
        val results = mutableListOf<MediaItem>()
        
        synchronized(allPlayableItems) {
            // Search in all playable items
            allPlayableItems.forEach { item ->
                val metadata = item.mediaMetadata
                val title = metadata.title?.toString()?.lowercase() ?: ""
                val artist = metadata.artist?.toString()?.lowercase() ?: ""
                val album = metadata.albumTitle?.toString()?.lowercase() ?: ""
                
                if (title.contains(queryLowerCase) || 
                    artist.contains(queryLowerCase) || 
                    album.contains(queryLowerCase)) {
                    results.add(item)
                }
            }
        }
        
        // Search in browsable items (albums, artists, playlists)
        val browsableResults = mutableListOf<MediaItem>()
        
        synchronized(albumItems) {
            albumItems.forEach { item ->
                val title = item.mediaMetadata.title?.toString()?.lowercase() ?: ""
                if (title.contains(queryLowerCase)) {
                    browsableResults.add(item)
                }
            }
        }
        
        synchronized(artistItems) {
            artistItems.forEach { item ->
                val title = item.mediaMetadata.title?.toString()?.lowercase() ?: ""
                if (title.contains(queryLowerCase)) {
                    browsableResults.add(item)
                }
            }
        }
        
        synchronized(playlistItems) {
            playlistItems.forEach { item ->
                val title = item.mediaMetadata.title?.toString()?.lowercase() ?: ""
                if (title.contains(queryLowerCase)) {
                    browsableResults.add(item)
                }
            }
        }
        
        // Combine results, prioritizing exact matches and putting browsable items first
        val combinedResults = mutableListOf<MediaItem>()
        combinedResults.addAll(browsableResults)
        combinedResults.addAll(results)
        
        // Limit results to avoid overwhelming the UI
        return combinedResults.take(50)
    }
    
    /**
     * Clears all content from the browse tree
     */
    fun clearAll() {
        synchronized(recentItems) { recentItems.clear() }
        synchronized(playlistItems) { playlistItems.clear() }
        synchronized(albumItems) { albumItems.clear() }
        synchronized(artistItems) { artistItems.clear() }
        synchronized(favoriteItems) { favoriteItems.clear() }
        synchronized(allPlayableItems) { allPlayableItems.clear() }
        
        albumToTracks.clear()
        artistToTracks.clear()
        playlistToTracks.clear()
        
        // Keep only root items in mediaIdToChildren
        val rootItems = mediaIdToChildren[ROOT_ID]
        mediaIdToChildren.clear()
        if (rootItems != null) {
            mediaIdToChildren[ROOT_ID] = rootItems
        }
        
        // Clear item cache but keep root items
        val rootItemsToKeep = mutableMapOf<String, MediaItem>()
        rootItemsToKeep[ROOT_ID] = getRoot()
        rootItemsToKeep[RECENT_ID] = mediaIdToItem[RECENT_ID]!!
        rootItemsToKeep[PLAYLISTS_ID] = mediaIdToItem[PLAYLISTS_ID]!!
        rootItemsToKeep[ALBUMS_ID] = mediaIdToItem[ALBUMS_ID]!!
        rootItemsToKeep[ARTISTS_ID] = mediaIdToItem[ARTISTS_ID]!!
        rootItemsToKeep[FAVORITES_ID] = mediaIdToItem[FAVORITES_ID]!!
        
        mediaIdToItem.clear()
        mediaIdToItem.putAll(rootItemsToKeep)
        
        // Reinitialize collections
        mediaIdToChildren[RECENT_ID] = recentItems
        mediaIdToChildren[PLAYLISTS_ID] = playlistItems
        mediaIdToChildren[ALBUMS_ID] = albumItems
        mediaIdToChildren[ARTISTS_ID] = artistItems
        mediaIdToChildren[FAVORITES_ID] = favoriteItems
    }
    
    /**
     * Gets the total number of items in a specific category
     */
    fun getCategoryItemCount(categoryId: String): Int {
        return when (categoryId) {
            RECENT_ID -> recentItems.size
            PLAYLISTS_ID -> playlistItems.size
            ALBUMS_ID -> albumItems.size
            ARTISTS_ID -> artistItems.size
            FAVORITES_ID -> favoriteItems.size
            else -> mediaIdToChildren[categoryId]?.size ?: 0
        }
    }
    
    /**
     * Initializes the browse tree with sample content for testing Android Auto connectivity
     */
    fun initializeWithSampleContent() {
        Log.d("AndroidAutoBrowseTree", "Initializing with sample content for testing...")
        
        // Create sample artist
        val sampleArtist = createBrowsableItem(
            "artist_sample",
            "Artista Exemplo",
            "3 faixas",
            null,
            MediaMetadata.FOLDER_TYPE_ARTISTS
        )
        addMediaItem(sampleArtist)
        
        // Create sample album  
        val sampleAlbum = createBrowsableItem(
            "album_sample", 
            "Álbum Exemplo",
            "Artista Exemplo",
            null,
            MediaMetadata.FOLDER_TYPE_ALBUMS
        )
        addMediaItem(sampleAlbum)
        
        // Create sample playlist
        val samplePlaylist = createBrowsableItem(
            "playlist_sample",
            "Playlist Exemplo", 
            "3 faixas",
            null,
            MediaMetadata.FOLDER_TYPE_PLAYLISTS
        )
        addMediaItem(samplePlaylist)
        
        // Create sample tracks
        val sampleTracks = mutableListOf<MediaItem>()
        for (i in 1..3) {
            val track = MediaItem.Builder()
                .setMediaId("track_sample_$i")
                .setUri(Uri.parse("https://example.com/track$i.mp3"))
                .setMediaMetadata(
                    MediaMetadata.Builder()
                        .setTitle("Faixa Exemplo $i")
                        .setArtist("Artista Exemplo")
                        .setAlbumTitle("Álbum Exemplo")
                        .setIsPlayable(true)
                        .setIsBrowsable(false)
                        .build()
                )
                .build()
            sampleTracks.add(track)
            addMediaItem(track)
        }
        
        // Associate tracks with artist, album and playlist
        addArtistTracks("artist_sample", sampleTracks)
        addAlbumTracks("album_sample", sampleTracks)
        addPlaylistTracks("playlist_sample", sampleTracks)
        
        // Add some tracks to recent and favorites
        synchronized(recentItems) {
            recentItems.clear()
            recentItems.addAll(sampleTracks.take(2))
        }
        
        synchronized(favoriteItems) {
            favoriteItems.clear() 
            favoriteItems.add(sampleTracks[0])
        }
        
        // Update category collections
        synchronized(artistItems) {
            if (artistItems.none { it.mediaId == "artist_sample" }) {
                artistItems.add(sampleArtist)
            }
        }
        
        synchronized(albumItems) {
            if (albumItems.none { it.mediaId == "album_sample" }) {
                albumItems.add(sampleAlbum)
            }
        }
        
        synchronized(playlistItems) {
            if (playlistItems.none { it.mediaId == "playlist_sample" }) {
                playlistItems.add(samplePlaylist)
            }
        }
        
        Log.d("AndroidAutoBrowseTree", "Sample content initialized:")
        Log.d("AndroidAutoBrowseTree", "- Artists: ${artistItems.size}")
        Log.d("AndroidAutoBrowseTree", "- Albums: ${albumItems.size}")  
        Log.d("AndroidAutoBrowseTree", "- Playlists: ${playlistItems.size}")
        Log.d("AndroidAutoBrowseTree", "- Recent: ${recentItems.size}")
        Log.d("AndroidAutoBrowseTree", "- Favorites: ${favoriteItems.size}")
        Log.d("AndroidAutoBrowseTree", "- Total playable: ${allPlayableItems.size}")
    }
} 
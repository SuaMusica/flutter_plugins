package br.com.suamusica.player

import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.view.KeyEvent
import androidx.annotation.OptIn
import androidx.media3.cast.CastPlayer
import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import androidx.media3.common.Player.COMMAND_GET_TIMELINE
import androidx.media3.common.Player.COMMAND_SEEK_TO_NEXT
import androidx.media3.common.Player.COMMAND_SEEK_TO_NEXT_MEDIA_ITEM
import androidx.media3.common.Player.COMMAND_SEEK_TO_PREVIOUS
import androidx.media3.common.Player.COMMAND_SEEK_TO_PREVIOUS_MEDIA_ITEM
import androidx.media3.common.Player.REPEAT_MODE_ALL
import androidx.media3.common.Player.REPEAT_MODE_OFF
import androidx.media3.common.Player.REPEAT_MODE_ONE
import androidx.media3.common.Player.STATE_IDLE
import androidx.media3.common.util.UnstableApi
import androidx.media3.session.CommandButton
import androidx.media3.session.LibraryResult
import androidx.media3.session.MediaLibraryService
import androidx.media3.session.MediaSession
import androidx.media3.session.R.drawable
import androidx.media3.session.SessionCommand
import androidx.media3.session.SessionError
import androidx.media3.session.SessionResult
import br.com.suamusica.player.PlayerPlugin.Companion.DISABLE_REPEAT_MODE
import br.com.suamusica.player.PlayerPlugin.Companion.ENQUEUE_METHOD
import br.com.suamusica.player.PlayerPlugin.Companion.FAVORITE
import br.com.suamusica.player.PlayerPlugin.Companion.ID_FAVORITE_ARGUMENT
import br.com.suamusica.player.PlayerPlugin.Companion.ID_URI_ARGUMENT
import br.com.suamusica.player.PlayerPlugin.Companion.INDEXES_TO_REMOVE
import br.com.suamusica.player.PlayerPlugin.Companion.IS_FAVORITE_ARGUMENT
import br.com.suamusica.player.PlayerPlugin.Companion.LOAD_ONLY_ARGUMENT
import br.com.suamusica.player.PlayerPlugin.Companion.NEW_URI_ARGUMENT
import br.com.suamusica.player.PlayerPlugin.Companion.PLAY_FROM_QUEUE_METHOD
import br.com.suamusica.player.PlayerPlugin.Companion.POSITIONS_LIST
import br.com.suamusica.player.PlayerPlugin.Companion.POSITION_ARGUMENT
import br.com.suamusica.player.PlayerPlugin.Companion.REMOVE_ALL
import br.com.suamusica.player.PlayerPlugin.Companion.REMOVE_IN
import br.com.suamusica.player.PlayerPlugin.Companion.REORDER
import br.com.suamusica.player.PlayerPlugin.Companion.REPEAT_MODE
import br.com.suamusica.player.PlayerPlugin.Companion.SEEK_METHOD
import br.com.suamusica.player.PlayerPlugin.Companion.SET_REPEAT_MODE
import br.com.suamusica.player.PlayerPlugin.Companion.TIME_POSITION_ARGUMENT
import br.com.suamusica.player.PlayerPlugin.Companion.TOGGLE_SHUFFLE
import br.com.suamusica.player.PlayerPlugin.Companion.UPDATE_FAVORITE
import br.com.suamusica.player.PlayerPlugin.Companion.UPDATE_MEDIA_URI
import br.com.suamusica.player.PlayerSingleton.playerChangeNotifier
import com.google.common.collect.ImmutableList
import com.google.common.util.concurrent.Futures
import com.google.common.util.concurrent.ListenableFuture
import com.google.gson.reflect.TypeToken
import com.google.gson.GsonBuilder
import androidx.media3.common.MediaMetadata

/**
 * Unified callback implementation that combines MediaButtonEventHandler functionality
 * with Android Auto MediaLibraryService support
 */
@UnstableApi
class AndroidAutoLibraryCallback(
    private val browseTree: AndroidAutoBrowseTree?,
    private val packageValidator: PackageValidator?,
    private val getMediaService: () -> MediaLibrarySession,
) : MediaLibraryService.MediaLibrarySession.Callback {

    companion object {
        private const val TAG = "AndroidAutoCallback"
        
        // Bundle keys for Android Auto
        private const val CONTENT_STYLE_SUPPORTED = "android.media.browse.CONTENT_STYLE_SUPPORTED"
        private const val CONTENT_STYLE_PLAYABLE_HINT = "android.media.browse.CONTENT_STYLE_PLAYABLE_HINT"
        private const val CONTENT_STYLE_BROWSABLE_HINT = "android.media.browse.CONTENT_STYLE_BROWSABLE_HINT"
        private const val CONTENT_STYLE_LIST_ITEM_HINT_VALUE = 1
        private const val CONTENT_STYLE_GRID_ITEM_HINT_VALUE = 2
        
        // Search support
        private const val SEARCH_SUPPORTED = "android.media.browse.SEARCH_SUPPORTED"
        
        // Legacy support from MediaButtonEventHandler
        private const val BROWSABLE_ROOT = "/"
        private const val EMPTY_ROOT = "@empty@"
    }

    // ======================
    // CONNECTION MANAGEMENT
    // ======================

    @OptIn(UnstableApi::class)
    override fun onConnect(
        session: MediaSession,
        controller: MediaSession.ControllerInfo
    ): MediaSession.ConnectionResult {
        Log.d(TAG, "=== onConnect called ===")
        
        // Validate the calling package if packageValidator is available
//        val isKnownCaller = packageValidator?.isKnownCaller(controller.packageName, controller.uid) ?: true
        val isKnownCaller = true
        // For debugging: Allow Google packages and system packages
//        val isAllowedForDebugging = controller.packageName.startsWith("com.google.") ||
//                                   controller.packageName == "android" ||
//                                   controller.packageName.contains("android.auto") ||
//                                   controller.packageName.contains("projection") ||
//                                   controller.uid == android.os.Process.SYSTEM_UID ||
//                                   controller.uid == android.os.Process.myUid()
//
        val isAllowedForDebugging = true
        val shouldAllow = isKnownCaller || isAllowedForDebugging
        
        if (!shouldAllow) {
            Log.w(TAG, "Rejecting connection from unknown caller: ${controller.packageName}")
            return MediaSession.ConnectionResult.reject()
        }
        
        // Build comprehensive session commands (from MediaButtonEventHandler)
        val sessionCommands =
            MediaSession.ConnectionResult.DEFAULT_SESSION_COMMANDS.buildUpon().apply {
                add(SessionCommand("notification_next", Bundle.EMPTY))
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    add(SessionCommand("notification_previous", Bundle.EMPTY))
                }
                add(SessionCommand("notification_favoritar", Bundle.EMPTY))
                add(SessionCommand("notification_desfavoritar", Bundle.EMPTY))
                add(SessionCommand(SEEK_METHOD, session.token.extras))
                add(SessionCommand("pause", Bundle.EMPTY))
                add(SessionCommand("stop", Bundle.EMPTY))
                add(SessionCommand("next", Bundle.EMPTY))
                add(SessionCommand("previous", Bundle.EMPTY))
                add(SessionCommand(UPDATE_FAVORITE, session.token.extras))
                add(SessionCommand(FAVORITE, session.token.extras))
                add(SessionCommand(TOGGLE_SHUFFLE, Bundle.EMPTY))
                add(SessionCommand(REPEAT_MODE, Bundle.EMPTY))
                add(SessionCommand(DISABLE_REPEAT_MODE, Bundle.EMPTY))
                add(SessionCommand(ENQUEUE_METHOD, session.token.extras))
                add(SessionCommand(REMOVE_ALL, Bundle.EMPTY))
                add(SessionCommand(REORDER, session.token.extras))
                add(SessionCommand(REMOVE_IN, session.token.extras))
                add(SessionCommand(SET_REPEAT_MODE, session.token.extras))
                add(SessionCommand("prepare", session.token.extras))
                add(SessionCommand("playFromQueue", session.token.extras))
                add(SessionCommand("play", Bundle.EMPTY))
                add(SessionCommand("remove_notification", Bundle.EMPTY))
                add(SessionCommand("send_notification", session.token.extras))
                add(SessionCommand("ads_playing", Bundle.EMPTY))
                add(SessionCommand("onTogglePlayPause", Bundle.EMPTY))
                add(SessionCommand(UPDATE_MEDIA_URI, session.token.extras))
                add(SessionCommand("cast", session.token.extras))
                add(SessionCommand("cast_next_media", session.token.extras))
                // Android Auto specific commands
                add(SessionCommand("refresh_content", Bundle.EMPTY))
            }.build()

        val playerCommands =
            MediaSession.ConnectionResult.DEFAULT_PLAYER_COMMANDS.buildUpon()
                .remove(COMMAND_SEEK_TO_PREVIOUS)
                .remove(COMMAND_SEEK_TO_PREVIOUS_MEDIA_ITEM)
                .remove(COMMAND_SEEK_TO_NEXT)
                .remove(COMMAND_SEEK_TO_NEXT_MEDIA_ITEM)
                .add(COMMAND_GET_TIMELINE)
                .build()

        // Allow connection for Android Auto and other known callers
        return MediaSession.ConnectionResult.AcceptedResultBuilder(session)
            .setAvailableSessionCommands(sessionCommands)
            .setAvailablePlayerCommands(playerCommands)
            .build()
    }

    // ======================
    // CUSTOM COMMANDS
    // ======================

    @OptIn(UnstableApi::class)
    override fun onCustomCommand(
        session: MediaSession,
        controller: MediaSession.ControllerInfo,
        customCommand: SessionCommand,
        args: Bundle
    ): ListenableFuture<SessionResult> {
        Log.d(TAG, "onCustomCommand called: ${customCommand.customAction} by ${controller.packageName}")
        
        // Handle all original MediaButtonEventHandler commands
        when (customCommand.customAction) {
            "notification_favoritar", "notification_desfavoritar" -> {
                val isFavorite = customCommand.customAction == "notification_favoritar"
                PlayerSingleton.favorite(isFavorite)
                buildIcons()
            }

            "cast" -> {
                getMediaService().castWithCastPlayer(args.getString("cast_id"))
            }

            SEEK_METHOD -> {
                val position = args.getLong("position")
                val playWhenReady = args.getBoolean("playWhenReady")
                session.player.seekTo(position)
                session.player.playWhenReady = playWhenReady
            }

            FAVORITE -> {
                val isFavorite = args.getBoolean(IS_FAVORITE_ARGUMENT)
                val mediaItem = session.player.currentMediaItem!!
                updateFavoriteMetadata(
                    session.player,
                    session.player.currentMediaItemIndex,
                    mediaItem,
                    isFavorite,
                )
                buildIcons()
            }

            REMOVE_ALL -> {
                getMediaService().removeAll()
            }

            REMOVE_IN -> {
                getMediaService().removeIn(
                    args.getIntegerArrayList(INDEXES_TO_REMOVE) ?: emptyList()
                )
            }

            REORDER -> {
                val oldIndex = args.getInt("oldIndex")
                val newIndex = args.getInt("newIndex")
                val json = args.getString(POSITIONS_LIST)
                val gson = GsonBuilder().create()
                val mediaListType = object : TypeToken<List<Map<String, Int>>?>() {}.type
                val positionsList: List<Map<String, Int>> = gson.fromJson(json, mediaListType)
                getMediaService().reorder(oldIndex, newIndex, positionsList)
            }

            "onTogglePlayPause" -> {
                if (session.player.isPlaying) {
                    session.player.pause()
                } else {
                    session.player.play()
                }
            }

            TOGGLE_SHUFFLE -> {
                val json = args.getString(POSITIONS_LIST)
                val gson = GsonBuilder().create()
                val mediaListType = object : TypeToken<List<Map<String, Int>>>() {}.type
                val positionsList: List<Map<String, Int>> = gson.fromJson(json, mediaListType)
                getMediaService().toggleShuffle(positionsList)
            }

            REPEAT_MODE -> {
                session.player.let {
                    when (it.repeatMode) {
                        REPEAT_MODE_OFF -> {
                            it.repeatMode = REPEAT_MODE_ALL
                        }
                        REPEAT_MODE_ONE -> {
                            it.repeatMode = REPEAT_MODE_OFF
                        }
                        else -> {
                            it.repeatMode = REPEAT_MODE_ONE
                        }
                    }
                }
            }

            DISABLE_REPEAT_MODE -> {
                getMediaService().disableRepeatMode()
            }

            "stop" -> {
                session.player.stop()
            }

            "play" -> {
                if (session.player.playbackState == STATE_IDLE) {
                    session.player.prepare()
                }
                session.player.play()
            }

            SET_REPEAT_MODE -> {
                val mode = args.getString("mode")
                val convertedMode = when (mode) {
                    "off" -> REPEAT_MODE_OFF
                    "one" -> REPEAT_MODE_ONE
                    "all" -> REPEAT_MODE_ALL
                    else -> REPEAT_MODE_OFF
                }
                if (session.player is CastPlayer) {
                    playerChangeNotifier?.onRepeatChanged(convertedMode)
                } else {
                    session.player.repeatMode = convertedMode
                }
            }

            "cast_next_media" -> {
                val json = args.getString("media")
                val gson = GsonBuilder().create()
                val mediaListType = object : TypeToken<Media>() {}.type
                val media: Media = gson.fromJson(json, mediaListType)
                session.player.setMediaItem(getMediaService().createMediaItem(media))
            }

            PLAY_FROM_QUEUE_METHOD -> {
                if (session.player is CastPlayer) {
                    PlayerSingleton.getMediaFromQueue(args.getInt(POSITION_ARGUMENT))
                } else {
                    getMediaService().playFromQueue(
                        args.getInt(POSITION_ARGUMENT), 
                        args.getLong(TIME_POSITION_ARGUMENT),
                        args.getBoolean(LOAD_ONLY_ARGUMENT),
                    )
                }
            }

            "notification_previous", "previous" -> {
                if (session.player is CastPlayer) {
                    PlayerSingleton.getPreviousMedia()
                } else {
                    if (session.player.hasPreviousMediaItem()) {
                        session.player.seekToPreviousMediaItem()
                    } else {
                        session.player.seekToPrevious()
                    }
                }
            }

            "notification_next", "next" -> {
                if (session.player is CastPlayer) {
                    PlayerSingleton.getNextMedia()
                } else {
                    session.player.seekToNextMediaItem()
                }
            }

            "pause" -> {
                session.player.pause()
            }

            UPDATE_MEDIA_URI -> {
                val newUri = args.getString(NEW_URI_ARGUMENT)
                val id = args.getInt(ID_URI_ARGUMENT)
                session.player.let {
                    for (i in 0 until it.mediaItemCount) {
                        val mediaItem = it.getMediaItemAt(i)
                        if (mediaItem.mediaId == id.toString()) {
                            getMediaService().updateMediaUri(i, newUri)
                            break
                        }
                    }
                }
            }

            UPDATE_FAVORITE -> {
                val isFavorite = args.getBoolean(IS_FAVORITE_ARGUMENT)
                val id = args.getInt(ID_FAVORITE_ARGUMENT)
                session.player.let {
                    for (i in 0 until it.mediaItemCount) {
                        val mediaItem = it.getMediaItemAt(i)
                        if (mediaItem.mediaId == id.toString()) {
                            updateFavoriteMetadata(it, i, mediaItem, isFavorite)
                            if (id.toString() == session.player.currentMediaItem?.mediaId) {
                                buildIcons()
                            }
                            break
                        }
                    }
                }
                PlayerSingleton.favorite(isFavorite)
            }

            "ads_playing" -> {
                getMediaService().removeNotification()
            }

            ENQUEUE_METHOD -> {
                val json = args.getString("json")
                val gson = GsonBuilder().create()
                val mediaListType = object : TypeToken<List<Media>>() {}.type
                val mediaList: List<Media> = gson.fromJson(json, mediaListType)
                buildIcons()
                getMediaService().enqueue(
                    mediaList,
                    args.getBoolean("autoPlay"),
                )
            }

            // Android Auto specific commands
            "refresh_content" -> {
                // Handle content refresh
                return Futures.immediateFuture(SessionResult(SessionResult.RESULT_SUCCESS))
            }
            else -> {
                Log.w(TAG, "Unknown custom command: ${customCommand.customAction}")
                return Futures.immediateFuture(SessionResult(SessionError.ERROR_UNKNOWN))
            }
        }
        
        return Futures.immediateFuture(SessionResult(SessionResult.RESULT_SUCCESS))
    }

    // ======================
    // MEDIA BUTTON EVENTS
    // ======================

    @UnstableApi
    override fun onMediaButtonEvent(
        session: MediaSession,
        controllerInfo: MediaSession.ControllerInfo,
        intent: Intent
    ): Boolean {
        onMediaButtonEventHandler(intent, session)
        return true
    }

    @UnstableApi
    fun onMediaButtonEventHandler(intent: Intent?, session: MediaSession) {
        if (intent == null) {
            return
        }

        if (Intent.ACTION_MEDIA_BUTTON == intent.action) {
            @Suppress("DEPRECATION") val ke =
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    intent.getParcelableExtra(Intent.EXTRA_KEY_EVENT, KeyEvent::class.java)
                } else {
                    intent.getParcelableExtra(Intent.EXTRA_KEY_EVENT)
                }
            if (ke == null) {
                return
            }

            if (ke.action == KeyEvent.ACTION_UP) {
                return
            }

            Log.d(TAG, "Key: $ke")
            when (ke.keyCode) {
                KeyEvent.KEYCODE_MEDIA_PLAY -> {
                    PlayerSingleton.play()
                }

                KeyEvent.KEYCODE_MEDIA_PAUSE -> {
                    PlayerSingleton.pause()
                }

                KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE -> {
                    Log.d(TAG, "Key Code: PlayPause")
                    if (session.player.isPlaying) {
                        PlayerSingleton.pause()
                    } else {
                        PlayerSingleton.play()
                    }
                }

                KeyEvent.KEYCODE_MEDIA_NEXT -> {
                    Log.d(TAG, "Key Code: Next")
                    PlayerSingleton.next()
                }

                KeyEvent.KEYCODE_MEDIA_PREVIOUS -> {
                    Log.d(TAG, "Key Code: Previous")
                    PlayerSingleton.previous()
                }

                KeyEvent.KEYCODE_MEDIA_STOP -> {
                    PlayerSingleton.stop()
                }
            }
        } else if (intent.hasExtra(FAVORITE)) {
            PlayerSingleton.favorite(intent.getBooleanExtra(FAVORITE, false))
        }
    }

    // ======================
    // ANDROID AUTO LIBRARY METHODS
    // ======================

    @OptIn(UnstableApi::class)
    override fun onGetLibraryRoot(
        session: MediaLibraryService.MediaLibrarySession,
        browser: MediaSession.ControllerInfo,
        params: MediaLibraryService.LibraryParams?
    ): ListenableFuture<LibraryResult<MediaItem>> {
        // Log.d(TAG, "=== onGetLibraryRoot called ===")
        // // Check if this is Android Auto
        // val isAndroidAuto = browser.packageName == "com.google.android.projection.gearhead" ||
        //                    browser.packageName == "com.google.android.gms" ||
        //                    browser.packageName.contains("android.auto")
        // Log.d(TAG, "Is Android Auto client: $isAndroidAuto")
        
        // // Validate client using PackageValidator if available
        // val isKnownCaller = packageValidator?.isKnownCaller(browser.packageName, browser.uid) ?: true
        // Log.d(TAG, "Is known caller: $isKnownCaller")
        
        // if (!isKnownCaller && !isAndroidAuto) {
        //     Log.w(TAG, "Unknown caller: ${browser.packageName} (${browser.uid})")
        //     return Futures.immediateFuture(
        //         LibraryResult.ofError(LibraryResult.RESULT_ERROR_PERMISSION_DENIED)
        //     )
        // }
        
        // Create extras bundle for Android Auto
        val extras = Bundle().apply {
            putBoolean(CONTENT_STYLE_SUPPORTED, true)
            putInt(CONTENT_STYLE_BROWSABLE_HINT, CONTENT_STYLE_LIST_ITEM_HINT_VALUE)
            putInt(CONTENT_STYLE_PLAYABLE_HINT, CONTENT_STYLE_LIST_ITEM_HINT_VALUE)
            putBoolean(SEARCH_SUPPORTED, true)
            
            // Additional Android Auto hints
            if (true) {
                putBoolean("android.media.browse.CONTENT_STYLE_SUPPORTED", true)
                putInt("android.media.browse.CONTENT_STYLE_BROWSABLE_HINT", 1)
                putInt("android.media.browse.CONTENT_STYLE_PLAYABLE_HINT", 1)
                putBoolean("android.media.browse.SEARCH_SUPPORTED", true)
                Log.d(TAG, "Added Android Auto specific extras")
            }
        }
        
        val libraryParams = MediaLibraryService.LibraryParams.Builder()
            .setExtras(extras)
            .build()
        
        val rootItem = browseTree?.getRoot() ?: run {
            Log.w(TAG, "browseTree is null, creating default root")
            // Create a default root MediaItem for Android Auto
            MediaItem.Builder()
                .setMediaId(AndroidAutoBrowseTree.ROOT_ID)
                .setMediaMetadata(
                    MediaMetadata.Builder()
                        .setTitle("SuaMusica")
                        .setSubtitle("Music Library")
                        .setIsBrowsable(true)
                        .setIsPlayable(false)
                        .setFolderType(MediaMetadata.FOLDER_TYPE_NONE)
                        .build()
                )
                .build()
        }
        Log.d(TAG, "Root item: ID=${rootItem.mediaId}, Title=${rootItem.mediaMetadata.title}")
        
        // Force initialization of browse tree content if not already done
        if (browseTree?.getChildren(AndroidAutoBrowseTree.ROOT_ID)?.isEmpty() != false) {
            Log.d(TAG, "Browse tree appears empty, initializing with sample content")
            browseTree?.initializeWithSampleContent()
        }
        
        return Futures.immediateFuture(
            LibraryResult.ofItem(rootItem, libraryParams)
        )
    }

    override fun onGetChildren(
        session: MediaLibraryService.MediaLibrarySession,
        browser: MediaSession.ControllerInfo,
        parentId: String,
        page: Int,
        pageSize: Int,
        params: MediaLibraryService.LibraryParams?
    ): ListenableFuture<LibraryResult<ImmutableList<MediaItem>>> {
        Log.d(TAG, "onGetChildren called for parentId: $parentId by ${browser.packageName}")
        
        val children = browseTree?.getChildren(parentId) ?: emptyList()
        val immutableChildren = ImmutableList.copyOf(children)
        
        return Futures.immediateFuture(
            LibraryResult.ofItemList(immutableChildren, params)
        )
    }

    @OptIn(UnstableApi::class)
    override fun onGetItem(
        session: MediaLibraryService.MediaLibrarySession,
        browser: MediaSession.ControllerInfo,
        mediaId: String
    ): ListenableFuture<LibraryResult<MediaItem>> {
        Log.d(TAG, "onGetItem called for mediaId: $mediaId by ${browser.packageName}")
        
        val item = browseTree?.getItem(mediaId)
        
        return if (item != null) {
            Futures.immediateFuture(LibraryResult.ofItem(item, null))
        } else {
            Log.w(TAG, "Item not found for mediaId: $mediaId")
            Futures.immediateFuture(LibraryResult.ofError(SessionError.ERROR_UNKNOWN))
        }
    }

    override fun onSearch(
        session: MediaLibraryService.MediaLibrarySession,
        browser: MediaSession.ControllerInfo,
        query: String,
        params: MediaLibraryService.LibraryParams?
    ): ListenableFuture<LibraryResult<Void>> {
        Log.d(TAG, "onSearch called with query: '$query' by ${browser.packageName}")
        
        // Perform search and notify results changed
        val searchResults = browseTree?.search(query) ?: emptyList()
        
        // Notify that search results have changed
        session.notifySearchResultChanged(browser, query, searchResults.size, params)
        
        return Futures.immediateFuture(LibraryResult.ofVoid())
    }

    override fun onGetSearchResult(
        session: MediaLibraryService.MediaLibrarySession,
        browser: MediaSession.ControllerInfo,
        query: String,
        page: Int,
        pageSize: Int,
        params: MediaLibraryService.LibraryParams?
    ): ListenableFuture<LibraryResult<ImmutableList<MediaItem>>> {
        Log.d(TAG, "onGetSearchResult called with query: '$query' by ${browser.packageName}")
        
        val searchResults = browseTree?.search(query) ?: emptyList()
        
        // Apply pagination
        val startIndex = page * pageSize
        val endIndex = minOf(startIndex + pageSize, searchResults.size)
        
        val paginatedResults = if (startIndex < searchResults.size) {
            searchResults.subList(startIndex, endIndex)
        } else {
            emptyList()
        }
        
        val immutableResults = ImmutableList.copyOf(paginatedResults)
        
        return Futures.immediateFuture(
            LibraryResult.ofItemList(immutableResults, params)
        )
    }

    override fun onAddMediaItems(
        mediaSession: MediaSession,
        browser: MediaSession.ControllerInfo,
        mediaItems: MutableList<MediaItem>
    ): ListenableFuture<MutableList<MediaItem>> {
        Log.d(TAG, "onAddMediaItems called with ${mediaItems.size} items by ${browser.packageName}")
        
        // Process media items and ensure they have proper URIs
        val processedItems = mediaItems.map { mediaItem ->
            if (mediaItem.localConfiguration?.uri != null) {
                mediaItem
            } else {
                // Try to get the item from browse tree to get proper URI
                browseTree?.getItem(mediaItem.mediaId) ?: mediaItem
            }
        }.toMutableList()
        
        return Futures.immediateFuture(processedItems)
    }

    // ======================
    // HELPER METHODS
    // ======================

    private fun updateFavoriteMetadata(
        player: Player,
        i: Int,
        mediaItem: MediaItem,
        isFavorite: Boolean
    ) {
        player.replaceMediaItem(
            i,
            mediaItem.buildUpon().setMediaMetadata(
                mediaItem.mediaMetadata.buildUpon().setExtras(
                    Bundle().apply {
                        putBoolean(IS_FAVORITE_ARGUMENT, isFavorite)
                    }
                ).build()
            ).build()
        )
    }

    fun buildIcons() {
        val isFavorite =
            getMediaService().smPlayer?.currentMediaItem?.mediaMetadata?.extras?.getBoolean(
                IS_FAVORITE_ARGUMENT
            ) ?: false

        val baseList = mutableListOf(
            CommandButton.Builder()
                .setDisplayName("Save to favorites")
                .setIconResId(if (isFavorite) drawable.media3_icon_heart_filled else drawable.media3_icon_heart_unfilled)
                .setSessionCommand(
                    SessionCommand(
                        if (isFavorite) "notification_desfavoritar" else "notification_favoritar",
                        Bundle()
                    )
                )
                .setEnabled(true)
                .build()
        )

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            baseList.add(
                CommandButton.Builder()
                    .setDisplayName("notification_next")
                    .setIconResId(drawable.media3_icon_next)
                    .setSessionCommand(SessionCommand("notification_next", Bundle.EMPTY))
                    .setEnabled(true)
                    .build()
            )
            baseList.add(
                CommandButton.Builder()
                    .setDisplayName("notification_previous")
                    .setIconResId(drawable.media3_icon_previous)
                    .setSessionCommand(SessionCommand("notification_previous", Bundle.EMPTY))
                    .setEnabled(true)
                    .build()
            )
        }
        return getMediaService().librarySession.setCustomLayout(baseList)
    }
} 
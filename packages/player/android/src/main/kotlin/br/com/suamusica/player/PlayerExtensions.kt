package br.com.suamusica.player

import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import com.google.android.gms.cast.MediaQueueItem
import java.util.WeakHashMap

val mediaItemMediaAssociations = WeakHashMap<MediaItem, Media>()


fun Player.getAllMediaItems(): List<MediaItem> {
    val items = mutableListOf<MediaItem>()
    for (i in 0 until mediaItemCount) {
        getMediaItemAt(i).let { items.add(it) }
    }
    return items
}

var MediaItem.associatedMedia: Media?
    get() = mediaItemMediaAssociations[this]
    set(value) {
        mediaItemMediaAssociations[this] = value
    }

fun Player.buildMediaQueueItems(convert: (MediaItem) -> MediaQueueItem): List<MediaQueueItem> {
    val items = mutableListOf<MediaQueueItem>()
    for (i in 0 until mediaItemCount) {
        getMediaItemAt(i).let { mediaItem ->
            items.add(convert(mediaItem))
        }
    }
    return items
}
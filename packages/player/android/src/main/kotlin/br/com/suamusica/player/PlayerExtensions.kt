package br.com.suamusica.player

import androidx.media3.common.MediaItem
import androidx.media3.common.Player
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
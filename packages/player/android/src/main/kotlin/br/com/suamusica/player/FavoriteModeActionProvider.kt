package br.com.suamusica.player

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.support.v4.media.session.PlaybackStateCompat
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.media3.common.Player
import com.google.android.exoplayer2.ext.mediasession.MediaSessionConnector
import java.util.*

class FavoriteModeActionProvider(private val context: Context) :
    MediaSessionConnector.CustomActionProvider {

    override fun onCustomAction(player: Player, action: String, extras: Bundle?) {
        PlayerSingleton.favorite(action == "Favoritar")
    }

    override fun getCustomAction(player: Player): PlaybackStateCompat.CustomAction? {
        if (PlayerSingleton.lastFavorite) {
            return PlaybackStateCompat.CustomAction.Builder("Desfavoritar", "Desfavoritar", R.drawable.ic_unfavorite_notification_player,).build()
        }
        return PlaybackStateCompat.CustomAction.Builder("Favoritar", "Favoritar", R.drawable.ic_favorite_notification_player,).build()
    }
}
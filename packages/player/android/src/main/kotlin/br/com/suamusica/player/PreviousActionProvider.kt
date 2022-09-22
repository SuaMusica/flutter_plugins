package br.com.suamusica.player

import android.os.Bundle
import android.support.v4.media.session.PlaybackStateCompat
import android.util.Log
import com.google.android.exoplayer2.Player
import com.google.android.exoplayer2.ext.mediasession.MediaSessionConnector

class PreviousActionProvider :
    MediaSessionConnector.CustomActionProvider {

    override fun onCustomAction(player: Player, action: String, extras: Bundle?) {
        PlayerSingleton.previous()
    }

    override fun getCustomAction(player: Player): PlaybackStateCompat.CustomAction? {
        return PlaybackStateCompat.CustomAction.Builder(
            "Voltar a música anterior",
            "Voltar a música anterior",
            R.drawable.ic_prev_notification_player,
        ).build()
    }
}
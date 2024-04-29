//package br.com.suamusica.player
//
//import android.os.Bundle
//import android.support.v4.media.session.PlaybackStateCompat
//import android.util.Log
//import androidx.media3.common.Player
//import com.google.android.exoplayer2.ext.mediasession.MediaSessionConnector
//
//class NextActionProvider :
//    MediaSessionConnector.CustomActionProvider {
//
//    override fun onCustomAction(player: Player, action: String, extras: Bundle?) {
//        PlayerSingleton.next()
//    }
//
//    override fun getCustomAction(player: Player): PlaybackStateCompat.CustomAction? {
//        return PlaybackStateCompat.CustomAction.Builder(
//            "Ir a próxima música",
//            "Ir a próxima música",
//            R.drawable.ic_next_notification_player,
//        ).build()
//    }
//}
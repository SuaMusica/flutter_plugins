package br.com.suamusica.player

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.media.MediaMetadata
import android.os.Build
import android.os.Bundle
import android.support.v4.media.MediaMetadataCompat
import android.support.v4.media.session.MediaSessionCompat
import android.support.v4.media.session.PlaybackStateCompat.*
import android.util.Log
import androidx.annotation.RequiresApi
import androidx.core.app.NotificationCompat
import androidx.media.app.NotificationCompat.MediaStyle
import androidx.media.session.MediaButtonReceiver
import androidx.media3.common.util.UnstableApi
import androidx.media3.session.CommandButton
import androidx.media3.session.MediaSession
import androidx.media3.session.MediaStyleNotificationHelper
import androidx.media3.session.SessionCommand
import com.bumptech.glide.load.engine.DiskCacheStrategy
import com.bumptech.glide.request.RequestOptions
import com.google.common.collect.ImmutableList
import kotlinx.coroutines.*
import java.util.*

const val NOW_PLAYING_CHANNEL: String = "br.com.suamusica.media.NOW_PLAYING"
const val NOW_PLAYING_NOTIFICATION: Int = 0xb339
const val FAVORITE: String = "favorite"

@UnstableApi
/**
 * Helper class to encapsulate code for building notifications.
 */
class NotificationBuilder(private val context: Context)  implements MediaNotification.Provider {
    private val platformNotificationManager: NotificationManager =
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    private val skipToPreviousAction = NotificationCompat.Action(
        R.drawable.ic_prev_notification_player,
        context.getString(R.string.notification_skip_to_previous),
        MediaButtonReceiver.buildMediaButtonPendingIntent(context, ACTION_SKIP_TO_PREVIOUS)
    )
    private val playAction = NotificationCompat.Action(
        R.drawable.ic_play_notification_player,
        context.getString(R.string.notification_play),
        MediaButtonReceiver.buildMediaButtonPendingIntent(context, ACTION_PLAY)
    )
    private val pauseAction = NotificationCompat.Action(
        R.drawable.ic_pause_notification_player,
        context.getString(R.string.notification_pause),
        MediaButtonReceiver.buildMediaButtonPendingIntent(context, ACTION_PAUSE)
    )

    private val favoriteAction = NotificationCompat.Action(
        R.drawable.ic_favorite_notification_player,
        context.getString(R.string.notification_favorite),
        PendingIntent.getBroadcast(
            context,
            UUID.randomUUID().hashCode(),
            Intent(context, MediaControlBroadcastReceiver::class.java).apply {
                putExtra(FAVORITE, true)
            },
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
        )
    )

    private val unFavoriteAction = NotificationCompat.Action(
        R.drawable.ic_unfavorite_notification_player,
        context.getString(R.string.notification_unfavorite),
        PendingIntent.getBroadcast(
            context,
            UUID.randomUUID().hashCode(),
            Intent(context, MediaControlBroadcastReceiver::class.java).apply {
                putExtra(FAVORITE, false)
            },
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
        )
    )

    private val skipToNextAction = NotificationCompat.Action(
        R.drawable.ic_next_notification_player,
        context.getString(R.string.notification_skip_to_next),
        MediaButtonReceiver.buildMediaButtonPendingIntent(context, ACTION_SKIP_TO_NEXT)
    )
    private val stopPendingIntent =
        MediaButtonReceiver.buildMediaButtonPendingIntent(context, ACTION_STOP)


    fun buildNotification(
        mediaSession: MediaSession,
        media: Media?,
        onGoing: Boolean,
        isPlayingExternal: Boolean?,
        isFavorite: Boolean?,
        mediaDuration: Long?,
        art: Bitmap?
    ): Notification {
        if (shouldCreateNowPlayingChannel()) {
            createNowPlayingChannel()
        }
        Log.i("NotificationBuilder", "TESTE1 buildNotification")
//        val playbackState = mediaSession.player.duration
        val builder = NotificationCompat.Builder(context, NOW_PLAYING_CHANNEL)
//        val actions = if (isFavorite == null) mutableListOf(0, 1, 2) else mutableListOf(
//            0,
//            2,
//            3
//        ) // favorite,play/pause,next
//        val duration = mediaDuration ?: 0L
//        val currentDuration =
//            mediaSession.player.currentPosition
        val shouldUseMetadata = Build.VERSION.SDK_INT >= Build.VERSION_CODES.R

//        isFavorite?.let {
//            builder.addAction(if (it) unFavoriteAction else favoriteAction)
//        }
//
//        builder.addAction(skipToPreviousAction)
//        when {
//            isPlayingExternal != null -> {
//                if (isPlayingExternal) {
//                    builder.addAction(pauseAction)
//                } else {
//                    builder.addAction(playAction)
//                }
//            }
//
//            //TODO: adicionar a variavel correta antes era um getter
//            mediaSession.player.isPlaying -> {
//                Log.i("NotificationBuilder", "Player is playing... onGoing: $onGoing")
//                builder.addAction(pauseAction)
//            }
//
//            //TODO: adicionar a variavel correta antes era um getter
//            mediaSession.player.isPlaying -> {
//                Log.i("NotificationBuilder", "Player is NOT playing... onGoing: $onGoing")
//                builder.addAction(playAction)
//            }
//
//            else -> {
//                Log.i("NotificationBuilder", "ELSE")
//                builder.addAction(playAction)
//            }
//        }
//
//        builder.addAction(skipToNextAction)

        val mediaStyle = MediaStyleNotificationHelper.MediaStyle(mediaSession)
            .setCancelButtonIntent(stopPendingIntent)
//            .setShowActionsInCompactView(*actions.toIntArray())
            .setShowCancelButton(true)

//        if (shouldUseMetadata && currentDuration != duration) {
//            mediaSession.setMetadata(
//                MediaMetadataCompat.Builder()
//                    .putString(MediaMetadata.METADATA_KEY_TITLE, media?.name ?: "Propaganda")
//                    .putString(MediaMetadata.METADATA_KEY_ARTIST, media?.author ?: "")
//                    .putBitmap(
//                        MediaMetadata.METADATA_KEY_ALBUM_ART, art
//                    )
//                    .putLong(MediaMetadata.METADATA_KEY_DURATION, duration) // 4
//                    .build()
//            )
//        }


        val notifyIntent = Intent("SUA_MUSICA_FLUTTER_NOTIFICATION_CLICK").apply {
            addCategory(Intent.CATEGORY_DEFAULT)
            flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val notifyPendingIntent = PendingIntent.getActivity(
            context,
            0,
            notifyIntent,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT else PendingIntent.FLAG_UPDATE_CURRENT
        )
        val notification = builder.apply {
            setContentIntent(notifyPendingIntent)
            setStyle(mediaStyle)
            setCategory(NotificationCompat.CATEGORY_PROGRESS)
            setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            setShowWhen(false)
            setColorized(true)
            setOnlyAlertOnce(false)
            setAutoCancel(false)
            setOngoing(onGoing)
            setSmallIcon(R.drawable.ic_notification)
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
                setDefaults(Notification.DEFAULT_LIGHTS)
                setVibrate(longArrayOf(0))
            } else {
                setDefaults(Notification.DEFAULT_LIGHTS)
            }
            if (!shouldUseMetadata) {
                setLargeIcon(art)
                setContentTitle(media?.name ?: "Propaganda")
                setContentText(media?.author ?: "")
            }

        }.build()

        if (onGoing) {
            notification.flags += Notification.FLAG_ONGOING_EVENT
            notification.flags += Notification.FLAG_NO_CLEAR
        }

        Log.i("NotificationBuilder", "Sending Notification onGoing: $onGoing")

        return notification
    }

    private fun shouldCreateNowPlayingChannel() =
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && !nowPlayingChannelExists()

    @RequiresApi(Build.VERSION_CODES.O)
    private fun nowPlayingChannelExists() =
        platformNotificationManager.getNotificationChannel(NOW_PLAYING_CHANNEL) != null

    @RequiresApi(Build.VERSION_CODES.O)
    private fun createNowPlayingChannel() {
        val notificationChannel = NotificationChannel(
            NOW_PLAYING_CHANNEL,
            context.getString(R.string.notification_channel),
            NotificationManager.IMPORTANCE_LOW
        )
            .apply {
                description = context.getString(R.string.notification_channel_description)
                if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.P) {
                    this.vibrationPattern = longArrayOf(0)
                    this.enableVibration(true)
                }
            }

        platformNotificationManager.createNotificationChannel(notificationChannel)
    }

package br.com.suamusica.player

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.graphics.Bitmap
import android.media.MediaMetadata
import android.os.Build
import android.support.v4.media.MediaMetadataCompat
import androidx.annotation.RequiresApi
import androidx.core.app.NotificationCompat
import androidx.media.app.NotificationCompat.MediaStyle
import androidx.media.session.MediaButtonReceiver
import android.support.v4.media.session.MediaControllerCompat
import android.support.v4.media.session.MediaSessionCompat
import android.support.v4.media.session.PlaybackStateCompat.ACTION_PAUSE
import android.support.v4.media.session.PlaybackStateCompat.ACTION_PLAY
import android.support.v4.media.session.PlaybackStateCompat.ACTION_SKIP_TO_NEXT
import android.support.v4.media.session.PlaybackStateCompat.ACTION_SKIP_TO_PREVIOUS
import android.support.v4.media.session.PlaybackStateCompat.ACTION_STOP
import android.util.Log
import com.bumptech.glide.Glide
import com.bumptech.glide.load.engine.DiskCacheStrategy
import com.bumptech.glide.request.RequestOptions
import com.google.android.exoplayer2.ExoPlayer
import com.google.android.exoplayer2.Player
import com.google.android.exoplayer2.ui.PlayerNotificationManager

const val NOW_PLAYING_CHANNEL: String = "br.com.suamusica.media.NOW_PLAYING"
const val NOW_PLAYING_NOTIFICATION: Int = 0xb339

/**
 * Helper class to encapsulate code for building notifications.
 */
class NotificationBuilder(private val context: Context) {
    private val platformNotificationManager: NotificationManager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    private val skipToPreviousAction = NotificationCompat.Action(
            handlePlayerIcons(R.drawable.old_prev_button, R.drawable.ic_prev_notification_player),
            context.getString(R.string.notification_skip_to_previous),
            MediaButtonReceiver.buildMediaButtonPendingIntent(context, ACTION_SKIP_TO_PREVIOUS))
    private val playAction = NotificationCompat.Action(
            handlePlayerIcons(R.drawable.old_play_button, R.drawable.ic_play_notification_player),
            context.getString(R.string.notification_play),
            MediaButtonReceiver.buildMediaButtonPendingIntent(context, ACTION_PLAY))
    private val pauseAction = NotificationCompat.Action(
            handlePlayerIcons(R.drawable.old_pause_button, R.drawable.ic_pause_notification_player),
            context.getString(R.string.notification_pause),
            MediaButtonReceiver.buildMediaButtonPendingIntent(context, ACTION_PAUSE))
    private val skipToNextAction = NotificationCompat.Action(
            handlePlayerIcons(R.drawable.old_next_button, R.drawable.ic_next_notification_player),
            context.getString(R.string.notification_skip_to_next),
            MediaButtonReceiver.buildMediaButtonPendingIntent(context, ACTION_SKIP_TO_NEXT))
    private val stopPendingIntent =
            MediaButtonReceiver.buildMediaButtonPendingIntent(context, ACTION_STOP)

    companion object {
        private val glideOptions = RequestOptions()
                .fallback(R.drawable.default_art)
                .diskCacheStrategy(DiskCacheStrategy.RESOURCE)

        private const val NOTIFICATION_LARGE_ICON_SIZE = 144 // px

        fun getArt(context: Context, artUri: String?) = try {
            when {
                artUri != null && artUri.isNotBlank() -> Glide.with(context)
                        .applyDefaultRequestOptions(glideOptions)
                        .asBitmap()
                        .load(artUri)
                        .submit(NOTIFICATION_LARGE_ICON_SIZE, NOTIFICATION_LARGE_ICON_SIZE)
                        .get()
                else -> null
            }
        } catch (e: Exception) {
            Log.e("NotificationBuilder", artUri?.toString() ?: "", e)
            null
        }

        fun createPlayerNotificationManager(context: Context,
                                            mediaSession: MediaSessionCompat,
                                            exoPlayer: ExoPlayer,
                                            media: Media) {
            val playerNotificationManager = PlayerNotificationManager.createWithNotificationChannel(
                    context,
                    NOW_PLAYING_CHANNEL,
                    R.string.notification_channel,
                    R.string.notification_channel_description,
                    NOW_PLAYING_NOTIFICATION,
                    object : PlayerNotificationManager.MediaDescriptionAdapter {
                        override fun createCurrentContentIntent(player: Player): PendingIntent? {
                            return null
                        }

                        override fun getCurrentContentText(player: Player) = media.author

                        override fun getCurrentContentTitle(player: Player) = media.name

                        override fun getCurrentLargeIcon(player: Player,
                                                         callback: PlayerNotificationManager.BitmapCallback)
                                = getArt(context, media.coverUrl)
                    },
                    object : PlayerNotificationManager.NotificationListener {
                    })

            playerNotificationManager.setMediaSessionToken(mediaSession.sessionToken)
            playerNotificationManager.setPlayer(exoPlayer)

            playerNotificationManager.setDefaults(Notification.DEFAULT_ALL)
            playerNotificationManager.setSmallIcon(R.drawable.ic_notification)
            playerNotificationManager.setUseNavigationActions(true)
            playerNotificationManager.setUseNavigationActionsInCompactView(true)
            // no fast-forward and rewind
            playerNotificationManager.setFastForwardIncrementMs(0)
            playerNotificationManager.setRewindIncrementMs(0)
            // no stop
            playerNotificationManager.setUseStopAction(false)
        }
    }

    fun buildNotification(mediaSession: MediaSessionCompat, media: Media, onGoing: Boolean): Notification? {
        if (shouldCreateNowPlayingChannel()) {
            createNowPlayingChannel()
        }

        val controller = MediaControllerCompat(context, mediaSession.sessionToken)
        val playbackState = controller.playbackState
        val builder = NotificationCompat.Builder(context, NOW_PLAYING_CHANNEL)
        val actions = mutableListOf(0)
        var playPauseIndex = 0
        builder.addAction(skipToPreviousAction)
        ++playPauseIndex
        actions.add(1)

        when {
            playbackState.isPlaying -> {
                Log.i("NotificationBuilder", "Player is playing... onGoing: $onGoing")
                builder.addAction(pauseAction)
            }
            playbackState.isPlayEnabled -> {
                Log.i("NotificationBuilder", "Player is NOT playing... onGoing: $onGoing")
                builder.addAction(playAction)
            }
            else -> {
                Log.i("NotificationBuilder", "ELSE")
                builder.addAction(playAction)
            }
        }

        builder.addAction(skipToNextAction)
        actions.add(playPauseIndex + 1)

        val mediaStyle = MediaStyle()
                .setCancelButtonIntent(stopPendingIntent)
                .setShowActionsInCompactView(*actions.toIntArray())
                .setShowCancelButton(true)
                .setMediaSession(mediaSession.sessionToken)

        val artUri = media.coverUrl

        val art = getArt(context, artUri)

        val notification = builder
                .setStyle(mediaStyle)
                .setCategory(NotificationCompat.CATEGORY_PROGRESS)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setShowWhen(false)
                .setContentTitle(media.name)
                .setContentText(media.author)
                .setLargeIcon(art)
                .setColorized(true)
                .setOnlyAlertOnce(false)
                .setAutoCancel(false)
                .setOngoing(onGoing)
                .setDefaults(Notification.DEFAULT_ALL)
                .setSmallIcon(R.drawable.ic_notification)
                .build()

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
        val notificationChannel = NotificationChannel(NOW_PLAYING_CHANNEL,
                context.getString(R.string.notification_channel),
                NotificationManager.IMPORTANCE_LOW)
                .apply {
                    description = context.getString(R.string.notification_channel_description)
                }

        platformNotificationManager.createNotificationChannel(notificationChannel)
    }

    private fun handlePlayerIcons(old: Int, new: Int): Int =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP)
                new
            else
                old
}


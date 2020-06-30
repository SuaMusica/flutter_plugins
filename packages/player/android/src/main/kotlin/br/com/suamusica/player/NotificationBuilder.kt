package br.com.suamusica.player

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.os.AsyncTask
import android.os.Build
import android.provider.Settings
import android.support.v4.media.session.MediaControllerCompat
import android.support.v4.media.session.MediaSessionCompat
import android.support.v4.media.session.PlaybackStateCompat.*
import android.util.Log
import androidx.annotation.RequiresApi
import androidx.core.app.NotificationCompat
import androidx.media.app.NotificationCompat.MediaStyle
import androidx.media.session.MediaButtonReceiver
import com.bumptech.glide.Glide
import com.bumptech.glide.load.engine.DiskCacheStrategy
import com.bumptech.glide.request.FutureTarget
import com.bumptech.glide.request.RequestOptions
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.async
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking

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

        fun getArt(context: Context, artUri: String?, size: Int? = null): Bitmap? {
            val glider = Glide.with(context)
                            .applyDefaultRequestOptions(glideOptions)
                            .asBitmap()
                            .load(artUri)
            var bitmap : Bitmap? = null
            val result = GlobalScope.async {
                bitmap = when {
                    artUri != null && artUri.isNotBlank() ->
                        when (size) {
                            null -> glider.submit().get()
                            else -> glider.submit(size, size).get()
                        }
                    else -> null
                }
            }

            return runBlocking {
                result.await()
                return@runBlocking bitmap
            }
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

        val art = getArt(context, artUri, NOTIFICATION_LARGE_ICON_SIZE)

        val notifyIntent = Intent("FLUTTER_NOTIFICATION_CLICK").apply {
            addCategory(Intent.CATEGORY_DEFAULT)
            flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val notifyPendingIntent = PendingIntent.getActivity(
                context, 0, notifyIntent, PendingIntent.FLAG_UPDATE_CURRENT
        )

        val notification = builder.apply{
                setContentIntent(notifyPendingIntent)
                setStyle(mediaStyle)
                setCategory(NotificationCompat.CATEGORY_PROGRESS)
                setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                setShowWhen(false)
                setContentTitle(media.name)
                setContentText(media.author)
                setLargeIcon(art)
                setColorized(true)
                setOnlyAlertOnce(false)
                setAutoCancel(false)
                setOngoing(onGoing)
                setSmallIcon(R.drawable.ic_notification)
                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O){
                    setDefaults(Notification.DEFAULT_LIGHTS)
                    setVibrate(longArrayOf(0))
                } else{
                    setDefaults(Notification.DEFAULT_LIGHTS)
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
        val notificationChannel = NotificationChannel(NOW_PLAYING_CHANNEL,
                context.getString(R.string.notification_channel),
                NotificationManager.IMPORTANCE_LOW)
                .apply {
                    description = context.getString(R.string.notification_channel_description)
                    if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.P){
                        this.setVibrationPattern(longArrayOf(0))
                        this.enableVibration(true)
                    }
                }

        platformNotificationManager.createNotificationChannel(notificationChannel)
    }

    private fun handlePlayerIcons(old: Int, new: Int): Int =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP)
                new
            else
                old
}


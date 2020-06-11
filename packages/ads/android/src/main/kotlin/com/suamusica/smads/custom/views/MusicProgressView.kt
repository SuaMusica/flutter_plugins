package com.suamusica.smads.custom.views

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.PorterDuff
import android.graphics.drawable.Drawable
import androidx.constraintlayout.widget.ConstraintLayout
import android.util.AttributeSet
import android.widget.SeekBar
import io.reactivex.Observable
import io.reactivex.subjects.PublishSubject
import kotlinx.android.synthetic.main.view_musicprogress.view.seekbar
import kotlinx.android.synthetic.main.view_musicprogress.view.textViewCurrentTime
import kotlinx.android.synthetic.main.view_musicprogress.view.textViewDuration
import android.graphics.drawable.BitmapDrawable
import com.squareup.picasso.Picasso
import com.squareup.picasso.Target
import com.suamusica.smads.R
import com.suamusica.smads.extensions.asFormattedTime
import com.suamusica.smads.extensions.isValidHexColor
import com.suamusica.smads.media.domain.MediaProgress
import com.suamusica.smads.media.domain.SeekProgress
import timber.log.Timber


class MusicProgressView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : ConstraintLayout(context, attrs, defStyleAttr) {

  private var currentMediaDuration = 0L

  private val seekBarTouchedDispatcher = PublishSubject.create<Unit>()

  init {
    inflate(context, R.layout.view_musicprogress, this)
  }

  fun bind(mediaProgress: MediaProgress, thumbSeekBarUrl: String?, progressColor: String? = null) {
    if (currentMediaDuration != 0L && mediaProgress == MediaProgress.NONE) return

    textViewCurrentTime.text = mediaProgress.current.toInt().asFormattedTime()
    textViewDuration.text = mediaProgress.total.toInt().asFormattedTime()
    seekbar.progress = mediaProgress.percentage().toInt()

    try {
      progressColor?.let { hexColor ->
        if (hexColor.isValidHexColor())
          seekbar.progressDrawable.setColorFilter(Color.parseColor(hexColor), PorterDuff.Mode.MULTIPLY)
      }
    } catch (e: Exception) {
      Timber.e(e)
    }

    currentMediaDuration = mediaProgress.total

    try {
      thumbSeekBarUrl?.let { url ->
        if (url.isBlank()) return@let

        Picasso.with(context)
            .load(url)
            .into(object: Target {
              override fun onBitmapLoaded(bitmap: Bitmap, from: Picasso.LoadedFrom) {
                try {
                  val thumb= Bitmap.createScaledBitmap(bitmap, 50, 50, false)
                  val drawable = BitmapDrawable(resources, thumb)
                  seekbar.thumb = drawable
                } catch (e: Exception) {
                  Timber.d("path from ThumbSeekBar is Null")
                }
              }

              override fun onBitmapFailed(errorDrawable: Drawable?) {}

              override fun onPrepareLoad(placeHolderDrawable: Drawable?) {}
            }
            )
      }
    } catch (e: Exception) {
      Timber.e(e)
    }
  }

  fun observableSeekBarTouched(): Observable<Unit> = seekBarTouchedDispatcher

  fun bindProgress(time: Long) {
    if (currentMediaDuration <= 0L) return
    textViewCurrentTime.text = time.toInt().asFormattedTime()
  }

  fun disableSeekBarTouch() {
    seekbar.setOnTouchListener { _, _ -> true }
  }

  fun seekBarChanges() : Observable<SeekProgress> {
    return Observable.create { emitter ->
      var seekPosition = 0L

      val listener = object : SeekBar.OnSeekBarChangeListener {
        override fun onProgressChanged(seekBar: SeekBar?, progress: Int, fromUser: Boolean) {
          val newPosition = currentMediaDuration * progress / 100L
          seekPosition = newPosition

          emitter.onNext(SeekProgress(seekPosition, false))
        }

        override fun onStartTrackingTouch(seekBar: SeekBar?) {
          seekBarTouchedDispatcher.onNext(Unit)
        }

        override fun onStopTrackingTouch(seekBar: SeekBar?) {
          emitter.onNext(SeekProgress(seekPosition, true))
        }
      }

      seekbar.setOnSeekBarChangeListener(listener)
    }
  }
}
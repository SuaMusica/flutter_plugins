package com.suamusica.smads.extensions

import android.animation.Animator
import android.animation.AnimatorListenerAdapter
import android.view.View
import android.view.View.GONE
import android.view.View.INVISIBLE
import android.view.View.VISIBLE
import android.widget.LinearLayout
import androidx.annotation.DrawableRes
import androidx.appcompat.content.res.AppCompatResources
import androidx.core.view.ViewCompat

fun View.show() {
  this.visibility = VISIBLE
}

fun View.hide() {
  this.visibility = INVISIBLE
}

fun View.gone() {
  this.visibility = GONE
}

fun View.setBackground(@DrawableRes resId: Int) {
  ViewCompat.setBackground(this, AppCompatResources.getDrawable(context, resId))
}

fun View.configParams(left: Int = 0, top: Int = 6, right: Int = 0, bottom: Int = 0) {
  val layoutParamsDefault = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT,
    LinearLayout.LayoutParams.WRAP_CONTENT)

  layoutParamsDefault.setMargins(left, top, right, bottom)

  layoutParams = layoutParamsDefault
}

fun View.crossFade(boolean: Boolean = false) {
  if (boolean) {
    if (visibility == VISIBLE) return

    show()
    alpha = 0f

    animate()
      .translationY(0f)
      .alpha(1f)
      .setListener(null)

  } else {
    if (visibility == GONE) return

    alpha = 1f

    this.animate()
      .translationY(height.toFloat())
      .alpha(0f)
      .setListener(object : AnimatorListenerAdapter() {
        override fun onAnimationEnd(animation: Animator?) {
          super.onAnimationEnd(animation)
          this@crossFade.gone()
        }
      })
  }
}


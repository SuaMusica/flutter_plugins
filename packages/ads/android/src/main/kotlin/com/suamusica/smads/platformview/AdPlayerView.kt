package com.suamusica.smads.platformview

import android.content.Context
import android.util.AttributeSet
import android.view.LayoutInflater
import androidx.constraintlayout.widget.ConstraintLayout
import com.suamusica.smads.R
import com.suamusica.smads.databinding.LayoutAdPlayerBinding

class AdPlayerView(
        context: Context,
        attrs: AttributeSet? = null,
        defStyleAttr: Int = 0
) : ConstraintLayout(context, attrs, defStyleAttr) {
    var binding: LayoutAdPlayerBinding

    init {
        binding = LayoutAdPlayerBinding.inflate(LayoutInflater.from(context), this,true)
    }
}
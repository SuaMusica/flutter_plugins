package com.suamusica.smads.platformview

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import timber.log.Timber

class AdPlayerFactory(private val messenger: BinaryMessenger): PlatformViewFactory(StandardMessageCodec.INSTANCE) {
  override fun create(context: Context, viewId: Int, args: Any): PlatformView {
    Timber.v("create(viewId = %s, args=%s)", viewId, args)
    return AdPlayer(context, messenger, viewId, AdPlayerParams(args))
  }
}
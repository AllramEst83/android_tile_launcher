package com.lottiefiles.dotlottie_flutter

import android.content.Context
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class DotLottieViewFactory(private val messenger: BinaryMessenger) :
    PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val creationParams = args as? Map<String, Any>
        val useOpenGL = creationParams?.get("useOpenGL") as? Boolean ?: false

        val view = DotLottiePlatformView(context, viewId, creationParams, messenger, useOpenGL)

        // Store reference
        DotLottieFlutterPlugin.platformViews[viewId] = view

        return view
    }
}
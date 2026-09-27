package com.codedbykay.android_tile_launcher

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var appsChannel: AppsChannelHandler? = null
    private var systemControlChannel: SystemControlChannelHandler? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        appsChannel = AppsChannelHandler(applicationContext, messenger)
        systemControlChannel = SystemControlChannelHandler(applicationContext, messenger)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        appsChannel?.dispose()
        appsChannel = null
        systemControlChannel?.dispose()
        systemControlChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}

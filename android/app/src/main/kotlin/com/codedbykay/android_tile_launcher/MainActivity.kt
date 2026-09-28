package com.codedbykay.android_tile_launcher

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var appsChannel: AppsChannelHandler? = null
    private var systemControlChannel: SystemControlChannelHandler? = null
    private var deviceChannel: DeviceChannelHandler? = null
    private var permissionsChannel: PermissionsChannelHandler? = null
    private var locationChannel: LocationChannelHandler? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        appsChannel = AppsChannelHandler(applicationContext, messenger)
        systemControlChannel = SystemControlChannelHandler(applicationContext, messenger)
        deviceChannel = DeviceChannelHandler(applicationContext, messenger)
        // Asking for a permission shows a dialog over an activity, so this one
        // needs `this`, not the application context.
        permissionsChannel = PermissionsChannelHandler(this, messenger)
        locationChannel = LocationChannelHandler(applicationContext, messenger)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        val handled =
            permissionsChannel?.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (handled != true) {
            super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        appsChannel?.dispose()
        appsChannel = null
        systemControlChannel?.dispose()
        systemControlChannel = null
        deviceChannel?.dispose()
        deviceChannel = null
        permissionsChannel?.dispose()
        permissionsChannel = null
        locationChannel?.dispose()
        locationChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}

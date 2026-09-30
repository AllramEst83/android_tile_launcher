package com.codedbykay.android_tile_launcher

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var appsChannel: AppsChannelHandler? = null
    private var systemControlChannel: SystemControlChannelHandler? = null
    private var deviceChannel: DeviceChannelHandler? = null
    private var permissionsChannel: PermissionsChannelHandler? = null
    private var locationChannel: LocationChannelHandler? = null
    private var calendarChannel: CalendarChannelHandler? = null
    private var contactsChannel: ContactsChannelHandler? = null
    private var phoneChannel: PhoneChannelHandler? = null
    private var smsChannel: SmsChannelHandler? = null
    private var whatsAppChannel: WhatsAppChannelHandler? = null
    private var alarmChannel: AlarmChannelHandler? = null
    private var homeRoleChannel: HomeRoleChannelHandler? = null
    private var shadeChannel: ShadeChannelHandler? = null
    private var wallpaperChannel: WallpaperChannelHandler? = null
    private var filesChannel: FilesChannelHandler? = null
    private var bluetoothChannel: BluetoothChannelHandler? = null
    private var attachmentChannel: AttachmentChannelHandler? = null
    private var linkChannel: LinkChannelHandler? = null

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
        calendarChannel = CalendarChannelHandler(applicationContext, messenger)
        contactsChannel = ContactsChannelHandler(applicationContext, messenger)
        phoneChannel = PhoneChannelHandler(applicationContext, messenger)
        smsChannel = SmsChannelHandler(applicationContext, messenger)
        whatsAppChannel = WhatsAppChannelHandler(applicationContext, messenger)
        alarmChannel = AlarmChannelHandler(applicationContext, messenger)
        homeRoleChannel = HomeRoleChannelHandler(applicationContext, messenger)
        shadeChannel = ShadeChannelHandler(applicationContext, messenger)
        wallpaperChannel = WallpaperChannelHandler(applicationContext, messenger)
        filesChannel = FilesChannelHandler(applicationContext, messenger)
        bluetoothChannel = BluetoothChannelHandler(applicationContext, messenger)
        attachmentChannel = AttachmentChannelHandler(applicationContext, messenger)
        linkChannel = LinkChannelHandler(applicationContext, messenger)
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
        calendarChannel?.dispose()
        calendarChannel = null
        contactsChannel?.dispose()
        contactsChannel = null
        phoneChannel?.dispose()
        phoneChannel = null
        smsChannel?.dispose()
        smsChannel = null
        whatsAppChannel?.dispose()
        whatsAppChannel = null
        alarmChannel?.dispose()
        alarmChannel = null
        homeRoleChannel?.dispose()
        homeRoleChannel = null
        shadeChannel?.dispose()
        shadeChannel = null
        wallpaperChannel?.dispose()
        wallpaperChannel = null
        filesChannel?.dispose()
        filesChannel = null
        bluetoothChannel?.dispose()
        bluetoothChannel = null
        attachmentChannel?.dispose()
        attachmentChannel = null
        linkChannel?.dispose()
        linkChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}

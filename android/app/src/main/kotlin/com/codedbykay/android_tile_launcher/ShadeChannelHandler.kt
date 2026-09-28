package com.codedbykay.android_tile_launcher

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Opens the notification shade or the quick-settings panel for the Dart
 * `AndroidShadeService`, the way a swipe from the top edge would.
 *
 * Android has no public API for it, so this calls `StatusBarManager` by
 * reflection (it needs the normal `EXPAND_STATUS_BAR` permission, granted at
 * install). Replies `true` when the call went through and `false` when this
 * Android version has taken the method away; never throws into Flutter.
 */
class ShadeChannelHandler(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {
    private val channel = MethodChannel(messenger, CHANNEL)

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "expandNotifications" -> result.success(expand("expandNotificationsPanel"))
            "expandQuickSettings" -> result.success(expand("expandSettingsPanel"))
            else -> result.notImplemented()
        }
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
    }

    private fun expand(method: String): Boolean {
        return try {
            val service = context.getSystemService("statusbar") ?: return false
            Class.forName("android.app.StatusBarManager")
                .getMethod(method)
                .invoke(service)
            true
        } catch (e: Exception) {
            false
        }
    }

    companion object {
        const val CHANNEL = "com.codedbykay.android_tile_launcher/shade"
    }
}

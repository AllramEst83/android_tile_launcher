package com.codedbykay.android_tile_launcher

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Tells the Dart `AndroidHomeRoleService` whether this launcher is the
 * phone's Home app, and opens Android's own page for choosing one. Android
 * decides which app is Home; nothing here changes it.
 *
 * `isDefault` replies whether the app that the Home button resolves to is this
 * one. `openSettings` replies `true` once the chooser was opened (the Home app
 * page, or on a phone without one the general default-apps page). Never throws
 * into Flutter.
 */
class HomeRoleChannelHandler(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {
    private val channel = MethodChannel(messenger, CHANNEL)

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isDefault" -> result.success(isDefault())
            "openSettings" -> result.success(openSettings())
            else -> result.notImplemented()
        }
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
    }

    private fun isDefault(): Boolean {
        val home = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
        val resolved = context.packageManager.resolveActivity(
            home,
            PackageManager.MATCH_DEFAULT_ONLY,
        )
        return resolved?.activityInfo?.packageName == context.packageName
    }

    private fun openSettings(): Boolean {
        for (action in listOf(
            Settings.ACTION_HOME_SETTINGS,
            Settings.ACTION_MANAGE_DEFAULT_APPS_SETTINGS,
        )) {
            try {
                val intent = Intent(action).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                context.startActivity(intent)
                return true
            } catch (e: ActivityNotFoundException) {
                // Try the next page.
            } catch (e: Exception) {
                return false
            }
        }
        return false
    }

    companion object {
        const val CHANNEL = "com.codedbykay.android_tile_launcher/home"
    }
}

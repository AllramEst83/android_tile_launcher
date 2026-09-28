package com.codedbykay.android_tile_launcher

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Environment
import android.os.StatFs
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Battery and storage for the Dart `AndroidDeviceRepository`.
 *
 * Both are cheap, permission-free reads (the battery from its sticky broadcast,
 * storage from a `StatFs` on the data partition), so they run on the calling
 * thread. Anything that can't be read is `null` in the reply rather than an
 * error; Dart shows it as dashes.
 */
class DeviceChannelHandler(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {
    private val channel = MethodChannel(messenger, CHANNEL)

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "status" -> result.success(status())
            else -> result.notImplemented()
        }
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
    }

    private fun status(): Map<String, Any?> {
        // A null receiver just returns the last sticky battery broadcast.
        val battery = context.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        val level = battery?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
        val scale = battery?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
        val state = battery?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1

        var free: Long? = null
        var total: Long? = null
        try {
            val stat = StatFs(Environment.getDataDirectory().path)
            free = stat.availableBytes
            total = stat.totalBytes
        } catch (e: IllegalArgumentException) {
            // Storage could not be read; leave both null.
        }

        return mapOf(
            "batteryPercent" to if (level >= 0 && scale > 0) level * 100 / scale else null,
            "charging" to
                (state == BatteryManager.BATTERY_STATUS_CHARGING ||
                    state == BatteryManager.BATTERY_STATUS_FULL),
            "storageFreeBytes" to free,
            "storageTotalBytes" to total,
        )
    }

    companion object {
        const val CHANNEL = "com.codedbykay.android_tile_launcher/device"
    }
}

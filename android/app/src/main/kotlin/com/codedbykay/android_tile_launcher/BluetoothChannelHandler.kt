package com.codedbykay.android_tile_launcher

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Reads Bluetooth's state for the Dart `AndroidBluetoothService`, and opens
 * what Android actually lets a third-party app open for the rest.
 * `Settings.Panel` (a quick, in-place overlay) only covers wifi, NFC, volume
 * and internet connectivity — there is no Bluetooth entry, despite one
 * looking plausible — so turning it on reuses the one real quick affordance
 * that exists, `BluetoothAdapter.ACTION_REQUEST_ENABLE` (a small system
 * confirm dialog, not a full navigation away); turning it off has no
 * equivalent "request disable" dialog at all, so that — and managing a
 * specific paired device — falls through to the full
 * `Settings.ACTION_BLUETOOTH_SETTINGS` screen instead. Neither
 * `BluetoothAdapter.enable`/`.disable` (removed for ordinary apps targeting
 * Android 13+) nor a profile's own `connect`/`disconnect` (always restricted
 * to system apps) is called here — there is no public way to do either from
 * a third-party app, so this does not pretend otherwise.
 */
class BluetoothChannelHandler(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {
    private val channel = MethodChannel(messenger, CHANNEL)
    private val manager =
        context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
    private val adapter: BluetoothAdapter? = manager?.adapter

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "status" -> result.success(status())
            "openPanel" -> open(panelIntent(), result)
            "openSettings" -> open(Intent(Settings.ACTION_BLUETOOTH_SETTINGS), result)
            else -> result.notImplemented()
        }
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
    }

    private fun status(): Map<String, Any?> {
        val adapter = adapter ?: return mapOf("supported" to false)
        if (!hasConnectPermission()) {
            return mapOf("supported" to true, "hasAccess" to false)
        }
        val enabled = try {
            adapter.isEnabled
        } catch (e: SecurityException) {
            return mapOf("supported" to true, "hasAccess" to false)
        }
        if (!enabled) {
            return mapOf("supported" to true, "hasAccess" to true, "enabled" to false)
        }
        val bonded = try {
            adapter.bondedDevices
        } catch (e: SecurityException) {
            return mapOf("supported" to true, "hasAccess" to false)
        }
        val devices = bonded.map { device ->
            mapOf(
                "name" to (device.name ?: device.address),
                "address" to device.address,
                // Whether a paired device is connected is a public,
                // per-profile read; connecting or disconnecting one is not
                // (see this class's own doc comment), so this only ever
                // reports state. A device counts as connected if any of the
                // profiles an ordinary peripheral actually uses reports it so.
                "connected" to CONNECTION_PROFILES.any { profile ->
                    manager?.getConnectionState(device, profile) ==
                        BluetoothProfile.STATE_CONNECTED
                },
            )
        }
        return mapOf(
            "supported" to true,
            "hasAccess" to true,
            "enabled" to true,
            "devices" to devices,
        )
    }

    // A normal, install-time permission before Android 12 (API 31) -
    // nothing to check at runtime on an older phone.
    private fun hasConnectPermission(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return true
        return context.checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT) ==
            PackageManager.PERMISSION_GRANTED
    }

    // Off: a quick system confirm dialog asking to turn it on, no full
    // navigation away. On: there is no equivalent "request disable" dialog,
    // so the only real destination left is the full settings screen, where
    // the toggle itself sits at the top.
    private fun panelIntent(): Intent {
        val isOn = try {
            adapter?.isEnabled == true
        } catch (e: SecurityException) {
            false
        }
        return if (adapter != null && !isOn) {
            Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE)
        } else {
            Intent(Settings.ACTION_BLUETOOTH_SETTINGS)
        }
    }

    private fun open(intent: Intent, result: MethodChannel.Result) {
        try {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
            result.success(null)
        } catch (e: Exception) {
            result.error("UNAVAILABLE", e.message, null)
        }
    }

    companion object {
        const val CHANNEL = "com.codedbykay.android_tile_launcher/bluetooth"
        private val CONNECTION_PROFILES = intArrayOf(
            BluetoothProfile.HEADSET,
            BluetoothProfile.A2DP,
            BluetoothProfile.GATT,
        )
    }
}

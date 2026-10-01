package com.codedbykay.android_tile_launcher

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
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
 * a third-party app, so this does not pretend otherwise. A second, event
 * channel pushes Dart a bare ping on the public broadcasts that *do* exist
 * for pairing, per-device connection, and the adapter's own on/off state, so
 * the tile can re-read [status] the moment one of those actually changes
 * instead of only on its own poll interval.
 */
class BluetoothChannelHandler(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    private val channel = MethodChannel(messenger, CHANNEL)
    private val eventChannel = EventChannel(messenger, EVENTS_CHANNEL)
    private val manager =
        context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
    private val adapter: BluetoothAdapter? = manager?.adapter

    // Pings Dart (a bare success(null), no payload — Dart re-reads [status]
    // itself) on pairing, a device connecting/disconnecting, or the adapter's
    // own on/off state, so the tile need not wait out a full poll interval
    // for any of those. Only live between onListen and onCancel: Dart's own
    // [changes] is a single cached broadcast stream, so there is never more
    // than one Flutter-side listener, and so never more than one of these
    // registered at a time.
    private var receiver: BroadcastReceiver? = null

    init {
        channel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            // A genuinely unexpected exception here must reach Dart as a
            // readable error, not crash the channel outright — the same
            // "never throw across the boundary" rule every other handler in
            // this app already follows.
            "status" -> try {
                result.success(status())
            } catch (e: Exception) {
                result.error("UNAVAILABLE", e.message, null)
            }
            "openPanel" -> open(panelIntent(), result)
            "openSettings" -> open(Intent(Settings.ACTION_BLUETOOTH_SETTINGS), result)
            else -> result.notImplemented()
        }
    }

    // The per-device broadcasts (bond state, ACL connect/disconnect) are
    // protected on API 31+: without BLUETOOTH_CONNECT, Android itself simply
    // never delivers them to this receiver, no exception and nothing extra to
    // check here — `ACTION_STATE_CHANGED` (the adapter's own on/off) needs no
    // permission and still gets through either way.
    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        val r = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                events.success(null)
            }
        }
        val filter = IntentFilter().apply {
            addAction(BluetoothDevice.ACTION_BOND_STATE_CHANGED)
            addAction(BluetoothDevice.ACTION_ACL_CONNECTED)
            addAction(BluetoothDevice.ACTION_ACL_DISCONNECTED)
            addAction(BluetoothAdapter.ACTION_STATE_CHANGED)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.registerReceiver(r, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            context.registerReceiver(r, filter)
        }
        receiver = r
    }

    override fun onCancel(arguments: Any?) {
        unregister()
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        unregister()
    }

    private fun unregister() {
        val r = receiver ?: return
        receiver = null
        try {
            context.unregisterReceiver(r)
        } catch (e: IllegalArgumentException) {
            // Already unregistered (e.g. dispose after onCancel already ran);
            // nothing left to clean up.
        }
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
                // profiles an ordinary peripheral actually uses reports it
                // so. Each read is its own try/catch, not one around the
                // whole map: a device or profile this device doesn't support
                // throwing here must not take the rest of the (working)
                // status down with it — first found reported as
                // "bluetooth is off" on a phone that plainly has it on.
                "connected" to CONNECTION_PROFILES.any { profile ->
                    try {
                        manager?.getConnectionState(device, profile) ==
                            BluetoothProfile.STATE_CONNECTED
                    } catch (e: Exception) {
                        false
                    }
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
        const val EVENTS_CHANNEL = "com.codedbykay.android_tile_launcher/bluetooth/events"
        private val CONNECTION_PROFILES = intArrayOf(
            BluetoothProfile.HEADSET,
            BluetoothProfile.A2DP,
            BluetoothProfile.GATT,
        )
    }
}

package com.codedbykay.android_tile_launcher

import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.hardware.camera2.CameraAccessException
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.media.AudioManager
import android.net.Uri
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Reads and changes three device-wide controls for the Dart
 * `AndroidSystemControlService`: the ringer mode (normal/vibrate/silent), the
 * torch, and locking the screen's orientation (the same as the quick-settings
 * auto-rotate tile, off).
 *
 * Ringer-mode, torch and orientation queries are cheap main-thread system
 * calls, unlike [AppsChannelHandler]'s package-manager query, so everything
 * here runs on the calling (platform) thread.
 */
class SystemControlChannelHandler(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {
    private val channel = MethodChannel(messenger, CHANNEL)
    private val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    private val notificationManager =
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    private val cameraManager = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
    private val torchCameraId: String? = findTorchCameraId()
    private var torchOn = false
    private val torchCallback =
        object : CameraManager.TorchCallback() {
            override fun onTorchModeChanged(cameraId: String, enabled: Boolean) {
                if (cameraId == torchCameraId) torchOn = enabled
            }
        }

    init {
        channel.setMethodCallHandler(this)
        cameraManager.registerTorchCallback(torchCallback, null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getSoundMode" -> result.success(soundMode())
            "setSoundMode" -> {
                setSoundMode(call.argument<String>("mode"))
                result.success(null)
            }
            "isOn" -> result.success(isOn(call.argument<String>("kind")))
            "setOn" -> {
                setOn(call.argument<String>("kind"), call.argument<Boolean>("on") ?: false)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        cameraManager.unregisterTorchCallback(torchCallback)
    }

    private fun soundMode(): String =
        when (audioManager.ringerMode) {
            AudioManager.RINGER_MODE_SILENT -> "silent"
            AudioManager.RINGER_MODE_VIBRATE -> "vibrate"
            else -> "normal"
        }

    private fun isOn(kind: String?): Boolean = when (kind) {
        "flashlight" -> torchOn
        // 0 is locked (auto-rotate off); default to 1 (unlocked) if the
        // setting is somehow missing, so a read error never claims a lock.
        "orientationLock" -> Settings.System.getInt(
            context.contentResolver,
            Settings.System.ACCELEROMETER_ROTATION,
            1,
        ) == 0
        else -> false
    }

    private fun setOn(kind: String?, on: Boolean) {
        when (kind) {
            "flashlight" -> setTorch(on)
            "orientationLock" -> setOrientationLock(on)
        }
    }

    // Silent is reached the way the volume rocker reaches it -- lowering the
    // ring volume while in vibrate -- not with setRingerMode(SILENT): an app's
    // silent request is treated as "turn Do Not Disturb on" and leaves the
    // ringer at vibrate, so the system's crossed-bell state is never entered.
    private fun setSoundMode(mode: String?) {
        val current = audioManager.ringerMode
        when (mode) {
            "normal" ->
                withPolicyAccess(needed = current == AudioManager.RINGER_MODE_SILENT) {
                    audioManager.ringerMode = AudioManager.RINGER_MODE_NORMAL
                }
            "vibrate" ->
                withPolicyAccess(needed = current == AudioManager.RINGER_MODE_SILENT) {
                    audioManager.ringerMode = AudioManager.RINGER_MODE_VIBRATE
                }
            "silent" ->
                withPolicyAccess(needed = true) {
                    if (current != AudioManager.RINGER_MODE_VIBRATE) {
                        audioManager.ringerMode = AudioManager.RINGER_MODE_VIBRATE
                    }
                    // The system only enters silent on a lower press that follows a
                    // press in another direction, and it remembers the last one, so
                    // a lower after an earlier lower is ignored for good. A raise
                    // (vibrate -> normal) resets that; then back to vibrate and lower.
                    audioManager.adjustStreamVolume(
                        AudioManager.STREAM_RING,
                        AudioManager.ADJUST_RAISE,
                        0,
                    )
                    audioManager.ringerMode = AudioManager.RINGER_MODE_VIBRATE
                    audioManager.adjustStreamVolume(
                        AudioManager.STREAM_RING,
                        AudioManager.ADJUST_LOWER,
                        0,
                    )
                }
        }
    }

    // Entering or leaving silent needs notification policy access -- a special
    // permission granted only via Settings, never a runtime dialog. Without it
    // this throws SecurityException on some OEMs and silently no-ops on others;
    // route to that Settings screen instead of failing either way.
    private fun withPolicyAccess(needed: Boolean, change: () -> Unit) {
        if (needed && !notificationManager.isNotificationPolicyAccessGranted) {
            val intent = Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
            return
        }
        try {
            change()
        } catch (e: SecurityException) {
            // Ignored: the settings screen above is the only recovery path.
        }
    }

    // Locking or unlocking the orientation writes a system setting, which
    // needs WRITE_SETTINGS -- a special permission granted only via Settings,
    // the same shape notification policy access takes for silent mode above.
    private fun setOrientationLock(locked: Boolean) {
        if (!Settings.System.canWrite(context)) {
            val intent = Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS)
            intent.data = Uri.parse("package:${context.packageName}")
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
            return
        }
        Settings.System.putInt(
            context.contentResolver,
            Settings.System.ACCELEROMETER_ROTATION,
            if (locked) 0 else 1,
        )
    }

    private fun setTorch(on: Boolean) {
        val id = torchCameraId ?: return
        try {
            cameraManager.setTorchMode(id, on)
        } catch (e: CameraAccessException) {
            // No flash, or the camera is in use elsewhere -- nothing to do.
        }
    }

    private fun findTorchCameraId(): String? =
        try {
            cameraManager.cameraIdList.firstOrNull { id ->
                cameraManager.getCameraCharacteristics(id)
                    .get(CameraCharacteristics.FLASH_INFO_AVAILABLE) == true
            }
        } catch (e: CameraAccessException) {
            null
        }

    companion object {
        const val CHANNEL = "com.codedbykay.android_tile_launcher/system_control"
    }
}

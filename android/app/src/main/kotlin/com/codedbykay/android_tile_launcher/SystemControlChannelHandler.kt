package com.codedbykay.android_tile_launcher

import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.hardware.camera2.CameraAccessException
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.media.AudioManager
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Reads and flips three device-wide toggles for the Dart `AndroidSystemControlService`:
 * silent mode and vibration mode (both the single ringer mode) and the torch.
 *
 * Ringer-mode and torch queries are cheap main-thread system calls, unlike
 * [AppsChannelHandler]'s package-manager query, so everything here runs on
 * the calling (platform) thread.
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
        val kind = call.argument<String>("kind")
        when (call.method) {
            "isOn" -> result.success(isOn(kind))
            "setOn" -> {
                setOn(kind, call.argument<Boolean>("on") ?: false)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        cameraManager.unregisterTorchCallback(torchCallback)
    }

    private fun isOn(kind: String?): Boolean =
        when (kind) {
            "silentMode" -> audioManager.ringerMode == AudioManager.RINGER_MODE_SILENT
            "vibrationMode" -> audioManager.ringerMode == AudioManager.RINGER_MODE_VIBRATE
            "flashlight" -> torchOn
            else -> false
        }

    private fun setOn(kind: String?, on: Boolean) {
        when (kind) {
            "silentMode" ->
                setRingerMode(
                    if (on) AudioManager.RINGER_MODE_SILENT else AudioManager.RINGER_MODE_NORMAL,
                )
            "vibrationMode" ->
                setRingerMode(
                    if (on) AudioManager.RINGER_MODE_VIBRATE else AudioManager.RINGER_MODE_NORMAL,
                )
            "flashlight" -> setTorch(on)
        }
    }

    // Changing the ringer mode to/from silent or vibrate needs notification
    // policy access -- a special permission granted only via Settings, never
    // a runtime dialog. Without it this throws SecurityException on some
    // OEMs and silently no-ops on others; route to that Settings screen
    // instead of failing either way.
    private fun setRingerMode(mode: Int) {
        if (!notificationManager.isNotificationPolicyAccessGranted) {
            val intent = Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
            return
        }
        try {
            audioManager.ringerMode = mode
        } catch (e: SecurityException) {
            // Ignored: the settings screen above is the only recovery path.
        }
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

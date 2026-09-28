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
 * Reads and changes three device-wide controls for the Dart `AndroidSystemControlService`:
 * the ringer mode (normal/vibrate/silent), Do Not Disturb and the torch.
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

    // While Do Not Disturb is on, Android reports the ringer as silent whatever
    // it was set to -- this is what the phone is actually doing, so it is what
    // the tile shows.
    private fun soundMode(): String =
        when (audioManager.ringerMode) {
            AudioManager.RINGER_MODE_SILENT -> "silent"
            AudioManager.RINGER_MODE_VIBRATE -> "vibrate"
            else -> "normal"
        }

    private fun isOn(kind: String?): Boolean =
        when (kind) {
            "doNotDisturb" ->
                notificationManager.currentInterruptionFilter !=
                    NotificationManager.INTERRUPTION_FILTER_ALL
            "flashlight" -> torchOn
            else -> false
        }

    private fun setOn(kind: String?, on: Boolean) {
        when (kind) {
            "doNotDisturb" ->
                withPolicyAccess {
                    notificationManager.setInterruptionFilter(
                        if (on) NotificationManager.INTERRUPTION_FILTER_PRIORITY
                        else NotificationManager.INTERRUPTION_FILTER_ALL,
                    )
                }
            "flashlight" -> setTorch(on)
        }
    }

    // Clears Do Not Disturb first: it masks the ringer (reads as silent), and
    // leaving silent only lifts "alarms only"/"total silence" DND on some
    // versions, so without this a tap could appear to do nothing.
    private fun setSoundMode(mode: String?) {
        val ringer =
            when (mode) {
                "vibrate" -> AudioManager.RINGER_MODE_VIBRATE
                "silent" -> AudioManager.RINGER_MODE_SILENT
                "normal" -> AudioManager.RINGER_MODE_NORMAL
                else -> return
            }
        withPolicyAccess {
            if (notificationManager.currentInterruptionFilter !=
                NotificationManager.INTERRUPTION_FILTER_ALL
            ) {
                notificationManager.setInterruptionFilter(
                    NotificationManager.INTERRUPTION_FILTER_ALL,
                )
            }
            audioManager.ringerMode = ringer
        }
    }

    // Changing the ringer to/from silent and changing Do Not Disturb both need
    // notification policy access -- a special permission granted only via
    // Settings, never a runtime dialog. Without it these throw
    // SecurityException on some OEMs and silently no-op on others; route to that
    // Settings screen instead of failing either way.
    private fun withPolicyAccess(change: () -> Unit) {
        if (!notificationManager.isNotificationPolicyAccessGranted) {
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

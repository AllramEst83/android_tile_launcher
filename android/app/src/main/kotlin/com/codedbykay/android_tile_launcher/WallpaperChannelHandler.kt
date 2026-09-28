package com.codedbykay.android_tile_launcher

import android.app.WallpaperManager
import android.content.Context
import android.graphics.BitmapFactory
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/**
 * Sets or clears the phone's lock-screen and home-screen wallpaper for the
 * Dart `AndroidWallpaperService`. Only ever called for a tap on the settings
 * screen; nothing here acts on its own.
 *
 * `set` takes the bytes of a PNG or JPEG and a target (`lock`, `home` or
 * `both`); `clear` takes a target and puts the phone's default back. Both reply
 * `done`, `refused` (the phone or a policy does not allow it) or `failed`,
 * and never throw into Flutter. Decoding a large picture is done off the main
 * thread. Choosing the lock screen alone needs Android 7 (API 24); on older
 * versions only the home screen can be set.
 */
class WallpaperChannelHandler(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {
    private val channel = MethodChannel(messenger, CHANNEL)
    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val method = call.method
        if (method != "set" && method != "clear") {
            result.notImplemented()
            return
        }
        val target = call.argument<String>("target")
        val image = call.argument<ByteArray>("image")
        worker.execute {
            val reply = try {
                if (method == "set") set(image, target) else clear(target)
            } catch (e: SecurityException) {
                "refused"
            } catch (e: Exception) {
                "failed"
            }
            main.post { result.success(reply) }
        }
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        worker.shutdown()
    }

    private fun manager(): WallpaperManager? {
        val manager = WallpaperManager.getInstance(context)
        if (Build.VERSION.SDK_INT >= 23 && !manager.isWallpaperSupported) return null
        return manager
    }

    private fun allowed(manager: WallpaperManager): Boolean =
        Build.VERSION.SDK_INT < 24 || manager.isSetWallpaperAllowed

    private fun flagsOf(target: String?): Int? {
        val lock = WallpaperManager.FLAG_LOCK
        val system = WallpaperManager.FLAG_SYSTEM
        return when (target) {
            "lock" -> lock
            "home" -> system
            "both" -> lock or system
            else -> null
        }
    }

    private fun set(image: ByteArray?, target: String?): String {
        if (image == null) return "failed"
        val flags = flagsOf(target) ?: return "failed"
        val manager = manager() ?: return "refused"
        if (!allowed(manager)) return "refused"
        val bitmap = BitmapFactory.decodeByteArray(image, 0, image.size) ?: return "failed"
        try {
            if (Build.VERSION.SDK_INT >= 24) {
                manager.setBitmap(bitmap, null, true, flags)
            } else if (flags == WallpaperManager.FLAG_SYSTEM) {
                manager.setBitmap(bitmap)
            } else {
                return "failed"
            }
        } finally {
            bitmap.recycle()
        }
        return "done"
    }

    private fun clear(target: String?): String {
        val flags = flagsOf(target) ?: return "failed"
        val manager = manager() ?: return "refused"
        if (!allowed(manager)) return "refused"
        if (Build.VERSION.SDK_INT >= 24) {
            manager.clear(flags)
        } else if (flags == WallpaperManager.FLAG_SYSTEM) {
            manager.clear()
        } else {
            return "failed"
        }
        return "done"
    }

    companion object {
        const val CHANNEL = "com.codedbykay.android_tile_launcher/wallpaper"
    }
}

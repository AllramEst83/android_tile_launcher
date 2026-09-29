package com.codedbykay.android_tile_launcher

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * One thing the files tile's Dart side cannot get from `dart:io` alone: which
 * storage volumes exist (internal, an SD card, ...) and where each one's root
 * actually is. `dart:io` can read any path once given it, but has no way to
 * ask Android what the paths even are; browsing and deleting, once a root is
 * known, need no platform call at all and stay in Dart.
 *
 * Reads no permission and needs none: `getExternalFilesDirs` is this app's
 * own sandboxed folder on each volume, always readable. It is only used here
 * to find the volume's *root* — four segments up from
 * `.../Android/data/<package>/files` — which the files tile then needs "all
 * files access" for.
 */
class FilesChannelHandler(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {
    private val channel = MethodChannel(messenger, CHANNEL)

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "storageRoots" -> result.success(storageRoots())
            else -> result.notImplemented()
        }
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
    }

    private fun storageRoots(): List<String> =
        context.getExternalFilesDirs(null)
            .filterNotNull()
            .map { dir ->
                var root = dir
                repeat(4) { root = root.parentFile ?: root }
                root.absolutePath
            }

    companion object {
        const val CHANNEL = "com.codedbykay.android_tile_launcher/files"
    }
}

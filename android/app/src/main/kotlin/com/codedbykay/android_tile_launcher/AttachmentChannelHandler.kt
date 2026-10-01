package com.codedbykay.android_tile_launcher

import android.content.ContentValues
import android.content.Context
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/**
 * Saves a mail attachment's bytes to the phone's own Downloads folder for the
 * Dart `AndroidAttachmentDownloadService`. Written through the `MediaStore
 * .Downloads` collection (API 29+), so no storage permission is needed and
 * nothing else on the phone has to know the real file path; on an older phone
 * this replies `failed` rather than trying a legacy, permission-gated path.
 */
class AttachmentChannelHandler(
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
        if (call.method != "save") {
            result.notImplemented()
            return
        }
        val bytes = call.argument<ByteArray>("bytes")
        val fileName = call.argument<String>("fileName")
        val mimeType = call.argument<String>("mimeType")
        worker.execute {
            val reply = try {
                save(bytes, fileName, mimeType)
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

    private fun save(bytes: ByteArray?, fileName: String?, mimeType: String?): String {
        if (bytes == null || fileName.isNullOrBlank()) return "failed"
        if (Build.VERSION.SDK_INT < 29) return "failed"
        val values = ContentValues().apply {
            put(MediaStore.Downloads.DISPLAY_NAME, fileName)
            put(MediaStore.Downloads.MIME_TYPE, mimeType ?: "application/octet-stream")
            put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
        }
        val resolver = context.contentResolver
        val uri: Uri =
            resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                ?: return "failed"
        val stream = resolver.openOutputStream(uri) ?: return "failed"
        stream.use { it.write(bytes) }
        return "saved"
    }

    companion object {
        const val CHANNEL = "com.codedbykay.android_tile_launcher/attachments"
    }
}

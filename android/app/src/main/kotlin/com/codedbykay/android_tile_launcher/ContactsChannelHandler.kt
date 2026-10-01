package com.codedbykay.android_tile_launcher

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Handler
import android.os.Looper
import android.provider.ContactsContract.CommonDataKinds.Email
import android.provider.ContactsContract.CommonDataKinds.Phone
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * Reads the phone book for the Dart `AndroidContactsService`.
 *
 * `all` replies one `{key, name, number, label}` per phone number, sorted by
 * name; `emails` replies one `{key, email}` per email address, in no
 * particular order (compose's autocomplete is the only reader, and it sorts
 * nothing). `key` is Android's lookup key for the person, which is what a
 * pinned tile remembers them by. Grouping the rows into people, and matching
 * a typed name, are done in Dart where they are tested. Permission is asked
 * for in Dart first; this only checks it and replies `NO_PERMISSION` or
 * `QUERY_FAILED`. Never throws into Flutter.
 */
class ContactsChannelHandler(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {
    private val channel = MethodChannel(messenger, CHANNEL)
    private val executor: ExecutorService = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "all" -> all(result)
            "emails" -> emails(result)
            else -> result.notImplemented()
        }
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        executor.shutdown()
    }

    private fun all(result: MethodChannel.Result) {
        if (context.checkSelfPermission(Manifest.permission.READ_CONTACTS) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            result.error("NO_PERMISSION", "contacts permission not granted", null)
            return
        }
        // A content query can be slow, so it runs off the main thread.
        executor.execute {
            try {
                val rows = query()
                mainHandler.post { result.success(rows) }
            } catch (e: SecurityException) {
                mainHandler.post { result.error("NO_PERMISSION", e.message, null) }
            } catch (e: Exception) {
                mainHandler.post { result.error("QUERY_FAILED", e.message, null) }
            }
        }
    }

    private fun query(): List<Map<String, String?>> {
        val projection = arrayOf(
            Phone.DISPLAY_NAME,
            Phone.NUMBER,
            Phone.TYPE,
            Phone.LABEL,
            Phone.LOOKUP_KEY,
        )
        val rows = mutableListOf<Map<String, String?>>()
        context.contentResolver
            .query(Phone.CONTENT_URI, projection, null, null, "${Phone.DISPLAY_NAME} COLLATE LOCALIZED ASC")
            ?.use { cursor ->
                while (cursor.moveToNext() && rows.size < MAX_ROWS) {
                    val label = Phone.getTypeLabel(
                        context.resources,
                        cursor.getInt(2),
                        cursor.getString(3),
                    )
                    rows.add(
                        mapOf(
                            "key" to cursor.getString(4),
                            "name" to cursor.getString(0),
                            "number" to cursor.getString(1),
                            "label" to label.toString(),
                        ),
                    )
                }
            }
        return rows
    }

    private fun emails(result: MethodChannel.Result) {
        if (context.checkSelfPermission(Manifest.permission.READ_CONTACTS) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            result.error("NO_PERMISSION", "contacts permission not granted", null)
            return
        }
        executor.execute {
            try {
                val rows = queryEmails()
                mainHandler.post { result.success(rows) }
            } catch (e: SecurityException) {
                mainHandler.post { result.error("NO_PERMISSION", e.message, null) }
            } catch (e: Exception) {
                mainHandler.post { result.error("QUERY_FAILED", e.message, null) }
            }
        }
    }

    private fun queryEmails(): List<Map<String, String?>> {
        val projection = arrayOf(Email.LOOKUP_KEY, Email.ADDRESS)
        val rows = mutableListOf<Map<String, String?>>()
        context.contentResolver
            .query(Email.CONTENT_URI, projection, null, null, null)
            ?.use { cursor ->
                while (cursor.moveToNext() && rows.size < MAX_ROWS) {
                    rows.add(
                        mapOf(
                            "key" to cursor.getString(0),
                            "email" to cursor.getString(1),
                        ),
                    )
                }
            }
        return rows
    }

    companion object {
        const val CHANNEL = "com.codedbykay.android_tile_launcher/contacts"

        // Far more than any phone book; a guard, not a limit anyone should meet.
        private const val MAX_ROWS = 20_000
    }
}

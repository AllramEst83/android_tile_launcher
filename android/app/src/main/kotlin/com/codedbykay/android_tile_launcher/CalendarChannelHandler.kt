package com.codedbykay.android_tile_launcher

import android.Manifest
import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.content.pm.PackageManager
import android.os.Handler
import android.os.Looper
import android.provider.CalendarContract
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.TimeZone
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * Reads and writes events for the Dart `AndroidCalendarService` from
 * Android's calendar provider (no library: each is a handful of calls).
 *
 * `events` takes `begin`/`end` in epoch milliseconds and replies a list of
 * `{id, title, begin, end, allDay, location, description, calendarId}`, one
 * per occurrence (repeating events are already expanded by `Instances`). Times
 * are raw: an all-day event's are UTC midnights, and turning them into local
 * dates is the Dart side's job, where it is tested. `calendars` replies every
 * calendar Android will accept an insert for (`CALENDAR_ACCESS_LEVEL` at
 * least contributor), as `{id, name, primary}`. `insertEvent` and
 * `updateEvent` take `calendarId, title, location, description, begin, end`
 * (timed events only) and reply the event's id; `updateEvent` also takes `id`
 * and replies `NOT_FOUND` if it no longer exists. `deleteEvent` takes `id`
 * and replies whether a row was actually removed (false: already gone).
 * Reading is guarded by `READ_CALENDAR`, writing by `WRITE_CALENDAR`;
 * permission is asked for in Dart first, this only checks it and replies
 * `NO_PERMISSION`. Never throws into Flutter.
 */
class CalendarChannelHandler(
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
            "events" -> events(
                call.argument<Number>("begin")?.toLong(),
                call.argument<Number>("end")?.toLong(),
                result,
            )
            "calendars" -> calendars(result)
            "insertEvent" -> writeEvent(call, result, id = null)
            "updateEvent" -> writeEvent(call, result, id = call.argument<Number>("id")?.toLong())
            "deleteEvent" -> deleteEvent(call.argument<Number>("id")?.toLong(), result)
            else -> result.notImplemented()
        }
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        executor.shutdown()
    }

    private fun events(begin: Long?, end: Long?, result: MethodChannel.Result) {
        if (begin == null || end == null || end < begin) {
            result.error("QUERY_FAILED", "bad range", null)
            return
        }
        if (context.checkSelfPermission(Manifest.permission.READ_CALENDAR) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            result.error("NO_PERMISSION", "calendar permission not granted", null)
            return
        }
        // A content query can be slow, so it runs off the main thread.
        executor.execute {
            try {
                val events = query(begin, end)
                mainHandler.post { result.success(events) }
            } catch (e: SecurityException) {
                mainHandler.post { result.error("NO_PERMISSION", e.message, null) }
            } catch (e: Exception) {
                mainHandler.post { result.error("QUERY_FAILED", e.message, null) }
            }
        }
    }

    private fun query(begin: Long, end: Long): List<Map<String, Any?>> {
        val uri = CalendarContract.Instances.CONTENT_URI.buildUpon().also {
            ContentUris.appendId(it, begin)
            ContentUris.appendId(it, end)
        }.build()
        val projection = arrayOf(
            CalendarContract.Instances.EVENT_ID,
            CalendarContract.Instances.TITLE,
            CalendarContract.Instances.BEGIN,
            CalendarContract.Instances.END,
            CalendarContract.Instances.ALL_DAY,
            CalendarContract.Instances.EVENT_LOCATION,
            CalendarContract.Instances.DESCRIPTION,
            CalendarContract.Instances.CALENDAR_ID,
        )
        // Only calendars the user has switched on, and not cancelled events.
        val selection = "${CalendarContract.Instances.VISIBLE} = 1 AND " +
            "(${CalendarContract.Instances.STATUS} IS NULL OR " +
            "${CalendarContract.Instances.STATUS} != ${CalendarContract.Events.STATUS_CANCELED})"
        val events = mutableListOf<Map<String, Any?>>()
        context.contentResolver
            .query(uri, projection, selection, null, "${CalendarContract.Instances.BEGIN} ASC")
            ?.use { cursor ->
                while (cursor.moveToNext() && events.size < MAX_EVENTS) {
                    events.add(
                        mapOf(
                            "id" to cursor.getLong(0),
                            "title" to cursor.getString(1),
                            "begin" to cursor.getLong(2),
                            "end" to cursor.getLong(3),
                            "allDay" to (cursor.getInt(4) != 0),
                            "location" to cursor.getString(5),
                            "description" to cursor.getString(6),
                            "calendarId" to cursor.getLong(7),
                        ),
                    )
                }
            }
        return events
    }

    private fun calendars(result: MethodChannel.Result) {
        if (context.checkSelfPermission(Manifest.permission.READ_CALENDAR) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            result.error("NO_PERMISSION", "calendar permission not granted", null)
            return
        }
        executor.execute {
            try {
                val calendars = queryCalendars()
                mainHandler.post { result.success(calendars) }
            } catch (e: SecurityException) {
                mainHandler.post { result.error("NO_PERMISSION", e.message, null) }
            } catch (e: Exception) {
                mainHandler.post { result.error("QUERY_FAILED", e.message, null) }
            }
        }
    }

    private fun queryCalendars(): List<Map<String, Any?>> {
        val projection = arrayOf(
            CalendarContract.Calendars._ID,
            CalendarContract.Calendars.CALENDAR_DISPLAY_NAME,
            CalendarContract.Calendars.ACCOUNT_NAME,
            CalendarContract.Calendars.IS_PRIMARY,
        )
        // Contributor access or better is what lets an insert succeed; a
        // calendar someone shared read-only never qualifies.
        val selection = "${CalendarContract.Calendars.VISIBLE} = 1 AND " +
            "${CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL} >= " +
            "${CalendarContract.Calendars.CAL_ACCESS_CONTRIBUTOR}"
        val order = "${CalendarContract.Calendars.IS_PRIMARY} DESC, " +
            "${CalendarContract.Calendars.CALENDAR_DISPLAY_NAME} ASC"
        val calendars = mutableListOf<Map<String, Any?>>()
        context.contentResolver
            .query(CalendarContract.Calendars.CONTENT_URI, projection, selection, null, order)
            ?.use { cursor ->
                while (cursor.moveToNext()) {
                    val name = cursor.getString(1)
                    calendars.add(
                        mapOf(
                            "id" to cursor.getLong(0),
                            "name" to (if (name.isNullOrBlank()) cursor.getString(2) else name),
                            "primary" to (cursor.getInt(3) != 0),
                        ),
                    )
                }
            }
        return calendars
    }

    private fun writeEvent(call: MethodCall, result: MethodChannel.Result, id: Long?) {
        val calendarId = call.argument<Number>("calendarId")?.toLong()
        val title = call.argument<String>("title")
        val begin = call.argument<Number>("begin")?.toLong()
        val end = call.argument<Number>("end")?.toLong()
        // An insert must name a calendar; an update with none keeps the
        // event's existing one, so nothing is silently moved between accounts.
        if (title == null || begin == null || end == null || (id == null && calendarId == null)) {
            result.error("QUERY_FAILED", "bad event", null)
            return
        }
        if (context.checkSelfPermission(Manifest.permission.WRITE_CALENDAR) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            result.error("NO_PERMISSION", "calendar write permission not granted", null)
            return
        }
        val values = ContentValues().apply {
            if (calendarId != null) put(CalendarContract.Events.CALENDAR_ID, calendarId)
            put(CalendarContract.Events.TITLE, title)
            put(CalendarContract.Events.EVENT_LOCATION, call.argument<String>("location"))
            put(CalendarContract.Events.DESCRIPTION, call.argument<String>("description"))
            put(CalendarContract.Events.DTSTART, begin)
            put(CalendarContract.Events.DTEND, end)
            put(CalendarContract.Events.EVENT_TIMEZONE, TimeZone.getDefault().id)
        }
        executor.execute {
            try {
                if (id == null) {
                    val uri = context.contentResolver.insert(CalendarContract.Events.CONTENT_URI, values)
                    val newId = uri?.let { ContentUris.parseId(it) }
                    mainHandler.post {
                        if (newId == null) {
                            result.error("QUERY_FAILED", "insert failed", null)
                        } else {
                            result.success(newId)
                        }
                    }
                } else {
                    val rows = context.contentResolver.update(
                        ContentUris.withAppendedId(CalendarContract.Events.CONTENT_URI, id),
                        values,
                        null,
                        null,
                    )
                    mainHandler.post {
                        if (rows > 0) {
                            result.success(id)
                        } else {
                            result.error("NOT_FOUND", "event no longer exists", null)
                        }
                    }
                }
            } catch (e: SecurityException) {
                mainHandler.post { result.error("NO_PERMISSION", e.message, null) }
            } catch (e: Exception) {
                mainHandler.post { result.error("QUERY_FAILED", e.message, null) }
            }
        }
    }

    private fun deleteEvent(id: Long?, result: MethodChannel.Result) {
        if (id == null) {
            result.error("QUERY_FAILED", "bad id", null)
            return
        }
        if (context.checkSelfPermission(Manifest.permission.WRITE_CALENDAR) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            result.error("NO_PERMISSION", "calendar write permission not granted", null)
            return
        }
        executor.execute {
            try {
                val rows = context.contentResolver.delete(
                    ContentUris.withAppendedId(CalendarContract.Events.CONTENT_URI, id),
                    null,
                    null,
                )
                mainHandler.post { result.success(rows > 0) }
            } catch (e: SecurityException) {
                mainHandler.post { result.error("NO_PERMISSION", e.message, null) }
            } catch (e: Exception) {
                mainHandler.post { result.error("QUERY_FAILED", e.message, null) }
            }
        }
    }

    companion object {
        const val CHANNEL = "com.codedbykay.android_tile_launcher/calendar"

        // A week of a very busy calendar; more would only slow the tile down.
        private const val MAX_EVENTS = 500
    }
}

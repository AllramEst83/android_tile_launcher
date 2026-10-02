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
 * `{id, title, begin, end, allDay, location, description, calendarId,
 * calendarVisible, repeating, exception}`, one per occurrence (repeating
 * events are already expanded by `Instances`), from every calendar whatever
 * its system visibility: which calendars show is the Dart side's choice, with
 * `calendarVisible` (the calendar app's own switch) as its default.
 * `repeating` is an occurrence of a series (RRULE/RDATE), `exception` a single
 * occurrence already split off from one (ORIGINAL_ID). Times are raw: an
 * all-day event's are UTC midnights, and turning them into local dates is the
 * Dart side's job, where it is tested. `calendars` replies every calendar the
 * phone has, as `{id, name, account, primary, visible, writable}`; `writable`
 * is `CALENDAR_ACCESS_LEVEL` at least contributor, what lets an insert
 * succeed. `insertEvent` and `updateEvent` take `calendarId, title, location,
 * description, begin, end` (timed events only) and reply the event's id;
 * `updateEvent` also takes `id` and replies `NOT_FOUND` if it no longer
 * exists. Given `instanceBegin` (an occurrence of a series: its original
 * BEGIN), `updateEvent` changes only that occurrence, by inserting an
 * exception, and replies the exception's id. `deleteEvent` takes `id` and
 * replies whether a row was actually removed (false: already gone); with
 * `instanceBegin` it cancels just that occurrence, and with `exception` it
 * cancels the split-off occurrence rather than deleting its row (which would
 * bring the series' own occurrence back in its place).
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
            "deleteEvent" -> deleteEvent(
                call.argument<Number>("id")?.toLong(),
                call.argument<Number>("instanceBegin")?.toLong(),
                call.argument<Boolean>("exception") == true,
                result,
            )
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
            CalendarContract.Instances.VISIBLE,
            CalendarContract.Instances.RRULE,
            CalendarContract.Instances.RDATE,
            CalendarContract.Instances.ORIGINAL_ID,
        )
        // Every calendar (which ones show is chosen on the Dart side), but
        // not cancelled events.
        val selection = "(${CalendarContract.Instances.STATUS} IS NULL OR " +
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
                            "calendarVisible" to (cursor.getInt(8) != 0),
                            "repeating" to (
                                !cursor.getString(9).isNullOrBlank() ||
                                    !cursor.getString(10).isNullOrBlank()
                                ),
                            "exception" to !cursor.isNull(11),
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
            CalendarContract.Calendars.VISIBLE,
            CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL,
        )
        val order = "${CalendarContract.Calendars.ACCOUNT_NAME} ASC, " +
            "${CalendarContract.Calendars.IS_PRIMARY} DESC, " +
            "${CalendarContract.Calendars.CALENDAR_DISPLAY_NAME} ASC"
        val calendars = mutableListOf<Map<String, Any?>>()
        context.contentResolver
            .query(CalendarContract.Calendars.CONTENT_URI, projection, null, null, order)
            ?.use { cursor ->
                while (cursor.moveToNext()) {
                    val name = cursor.getString(1)
                    val account = cursor.getString(2)
                    calendars.add(
                        mapOf(
                            "id" to cursor.getLong(0),
                            "name" to (if (name.isNullOrBlank()) account else name),
                            "account" to account,
                            "primary" to (cursor.getInt(3) != 0),
                            "visible" to (cursor.getInt(4) != 0),
                            // Contributor access or better is what lets an
                            // insert succeed; a calendar someone shared
                            // read-only never qualifies.
                            "writable" to (
                                cursor.getInt(5) >=
                                    CalendarContract.Calendars.CAL_ACCESS_CONTRIBUTOR
                                ),
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
        val instanceBegin = call.argument<Number>("instanceBegin")?.toLong()
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
                if (id != null && instanceBegin != null) {
                    // One occurrence of a series: an exception for it, never a
                    // rewrite of the series itself (which would move every
                    // occurrence, and a series has a DURATION, not a DTEND).
                    values.remove(CalendarContract.Events.CALENDAR_ID)
                    values.put(CalendarContract.Events.ORIGINAL_INSTANCE_TIME, instanceBegin)
                    val newId = insertException(id, values)
                    mainHandler.post {
                        if (newId == null) {
                            result.error("NOT_FOUND", "event no longer exists", null)
                        } else {
                            result.success(newId)
                        }
                    }
                } else if (id == null) {
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

    /** Inserts an exception to the series [id]; its id, or null if refused. */
    private fun insertException(id: Long, values: ContentValues): Long? {
        val uri = context.contentResolver.insert(
            ContentUris.withAppendedId(CalendarContract.Events.CONTENT_EXCEPTION_URI, id),
            values,
        )
        return uri?.let { ContentUris.parseId(it) }?.takeIf { it > 0 }
    }

    private fun deleteEvent(
        id: Long?,
        instanceBegin: Long?,
        exception: Boolean,
        result: MethodChannel.Result,
    ) {
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
                val removed = when {
                    // One occurrence of a series: cancel just it.
                    instanceBegin != null -> insertException(
                        id,
                        ContentValues().apply {
                            put(CalendarContract.Events.ORIGINAL_INSTANCE_TIME, instanceBegin)
                            put(CalendarContract.Events.STATUS, CalendarContract.Events.STATUS_CANCELED)
                        },
                    ) != null
                    // An occurrence already split off: cancelling it keeps the
                    // series' own occurrence from coming back in its place.
                    exception -> context.contentResolver.update(
                        ContentUris.withAppendedId(CalendarContract.Events.CONTENT_URI, id),
                        ContentValues().apply {
                            put(CalendarContract.Events.STATUS, CalendarContract.Events.STATUS_CANCELED)
                        },
                        null,
                        null,
                    ) > 0
                    else -> context.contentResolver.delete(
                        ContentUris.withAppendedId(CalendarContract.Events.CONTENT_URI, id),
                        null,
                        null,
                    ) > 0
                }
                mainHandler.post { result.success(removed) }
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
        // Counted before the Dart side drops hidden calendars.
        private const val MAX_EVENTS = 500
    }
}

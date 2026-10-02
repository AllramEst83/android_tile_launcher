import 'dart:async';

import 'package:android_tile_launcher/model/calendar_event.dart';
import 'package:android_tile_launcher/services/calendar_service.dart';
import 'package:android_tile_launcher/services/permission_service.dart';
import 'package:flutter/services.dart';

/// [CalendarService] backed by the Kotlin `CalendarChannelHandler`. The only
/// file that knows about the channel. [events] never asks for permission
/// itself (it is polled in the background); every write, and listing which
/// calendars can be written to, asks [permissions] first, which is safe
/// because they are only ever reached from an explicit tap.
class AndroidCalendarService implements CalendarService {
  const AndroidCalendarService({
    required this.permissions,
    this.channel = const MethodChannel(channelName),
    this.timeout = const Duration(seconds: 15),
  });

  static const String channelName =
      'com.codedbykay.android_tile_launcher/calendar';

  final PermissionService permissions;
  final MethodChannel channel;

  /// Only guards against a reply that never comes.
  final Duration timeout;

  @override
  Future<CalendarResult> events({
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      // All-day events are stored as UTC midnights, so near the edge of the
      // range one can sit up to a day outside it in UTC terms. Ask for a day
      // either side and filter properly once the times are local.
      final List<Map<Object?, Object?>>? raw = await channel
          .invokeListMethod<Map<Object?, Object?>>('events', <String, Object?>{
            'begin': from
                .subtract(const Duration(days: 1))
                .millisecondsSinceEpoch,
            'end': to.add(const Duration(days: 1)).millisecondsSinceEpoch,
          })
          .timeout(timeout);
      final List<CalendarEvent> events =
          <CalendarEvent>[
              for (final Map<Object?, Object?> entry
                  in raw ?? const <Map<Object?, Object?>>[])
                ?_parse(entry),
            ].where((CalendarEvent e) => _overlaps(e, from, to)).toList()
            ..sort(_byStart);
      return CalendarEvents(List<CalendarEvent>.unmodifiable(events));
    } on PlatformException catch (error) {
      return switch (error.code) {
        'NO_PERMISSION' => const CalendarNoAccess(),
        _ => const CalendarUnavailable('could not read the calendar'),
      };
    } on MissingPluginException {
      return const CalendarUnavailable('calendar is not supported here');
    } on TimeoutException {
      return const CalendarUnavailable('the calendar did not answer');
    }
  }

  @override
  Future<CalendarListResult> writableCalendars() async {
    final PermissionStatus status = await permissions.request(
      AppPermission.calendar,
    );
    if (status != PermissionStatus.granted) {
      return CalendarListDenied(
        permanent: status == PermissionStatus.permanentlyDenied,
      );
    }
    return switch (await calendars()) {
      CalendarList(:final List<CalendarInfo> calendars) => CalendarList(
        List<CalendarInfo>.unmodifiable(
          calendars.where((CalendarInfo c) => c.writable),
        ),
      ),
      final CalendarListResult other => other,
    };
  }

  @override
  Future<CalendarListResult> calendars() async {
    try {
      final List<Map<Object?, Object?>>? raw = await channel
          .invokeListMethod<Map<Object?, Object?>>('calendars')
          .timeout(timeout);
      final List<CalendarInfo> calendars = <CalendarInfo>[
        for (final Map<Object?, Object?> entry
            in raw ?? const <Map<Object?, Object?>>[])
          ?_parseCalendar(entry),
      ];
      return CalendarList(List<CalendarInfo>.unmodifiable(calendars));
    } on PlatformException catch (error) {
      return switch (error.code) {
        'NO_PERMISSION' => const CalendarListDenied(permanent: false),
        _ => const CalendarListUnavailable('could not read the calendars'),
      };
    } on MissingPluginException {
      return const CalendarListUnavailable('calendar is not supported here');
    } on TimeoutException {
      return const CalendarListUnavailable('the calendar did not answer');
    }
  }

  @override
  Future<CalendarWriteResult> createEvent(NewCalendarEvent event) =>
      _write('insertEvent', event);

  @override
  Future<CalendarWriteResult> updateEvent(
    CalendarEvent event,
    NewCalendarEvent draft,
  ) => _write(
    'updateEvent',
    draft,
    id: event.id,
    instanceBegin: event.isOccurrence ? event.occurrenceMillis : null,
  );

  Future<CalendarWriteResult> _write(
    String method,
    NewCalendarEvent event, {
    int? id,
    int? instanceBegin,
  }) async {
    final PermissionStatus status = await permissions.request(
      AppPermission.calendarWrite,
    );
    if (status != PermissionStatus.granted) {
      return CalendarWriteDenied(
        permanent: status == PermissionStatus.permanentlyDenied,
      );
    }
    try {
      final int? result = await channel
          .invokeMethod<int>(method, <String, Object?>{
            'id': ?id,
            'instanceBegin': ?instanceBegin,
            'calendarId': ?event.calendarId,
            'title': event.title,
            'location': event.location,
            'description': event.description,
            'begin': event.start.millisecondsSinceEpoch,
            'end': event.end.millisecondsSinceEpoch,
          })
          .timeout(timeout);
      if (result == null) {
        return const CalendarWriteFailed('could not save the event');
      }
      return CalendarEventSaved(result);
    } on PlatformException catch (error) {
      return switch (error.code) {
        'NO_PERMISSION' => const CalendarWriteDenied(permanent: false),
        'NOT_FOUND' => const CalendarWriteFailed('that event is gone'),
        _ => const CalendarWriteFailed('could not save the event'),
      };
    } on MissingPluginException {
      return const CalendarWriteFailed('calendar is not supported here');
    } on TimeoutException {
      return const CalendarWriteFailed('the calendar did not answer');
    }
  }

  @override
  Future<CalendarDeleteResult> deleteEvent(CalendarEvent event) async {
    final PermissionStatus status = await permissions.request(
      AppPermission.calendarWrite,
    );
    if (status != PermissionStatus.granted) {
      return CalendarDeleteDenied(
        permanent: status == PermissionStatus.permanentlyDenied,
      );
    }
    try {
      final bool? removed = await channel
          .invokeMethod<bool>('deleteEvent', <String, Object?>{
            'id': event.id,
            if (event.isOccurrence) 'instanceBegin': event.occurrenceMillis,
            if (event.splitOff) 'exception': true,
          })
          .timeout(timeout);
      return removed == true
          ? const CalendarEventDeleted()
          : const CalendarEventAlreadyGone();
    } on PlatformException catch (error) {
      return switch (error.code) {
        'NO_PERMISSION' => const CalendarDeleteDenied(permanent: false),
        _ => const CalendarDeleteFailed('could not delete the event'),
      };
    } on MissingPluginException {
      return const CalendarDeleteFailed('calendar is not supported here');
    } on TimeoutException {
      return const CalendarDeleteFailed('the calendar did not answer');
    }
  }

  static CalendarInfo? _parseCalendar(Map<Object?, Object?> entry) {
    final Object? id = entry['id'];
    final Object? name = entry['name'];
    if (id is! int || name is! String) return null;
    final Object? account = entry['account'];
    return CalendarInfo(
      id: id,
      name: name.trim().isEmpty ? '?' : name.trim(),
      primary: entry['primary'] == true,
      account: account is String && account.trim().isNotEmpty
          ? account.trim()
          : null,
      // Absent means an older reply: what the list used to hold, which was
      // only shown, writable calendars.
      visible: entry['visible'] != false,
      writable: entry['writable'] != false,
    );
  }

  static CalendarEvent? _parse(Map<Object?, Object?> entry) {
    final Object? id = entry['id'];
    final Object? begin = entry['begin'];
    final Object? end = entry['end'];
    if (id is! int || begin is! int || end is! int) return null;
    final bool allDay = entry['allDay'] == true;
    final DateTime start = _local(begin, allDay);
    DateTime stop = _local(end, allDay);
    // A broken range would never show; make it the shortest sensible one.
    if (stop.isBefore(start)) {
      stop = allDay ? DateTime(start.year, start.month, start.day + 1) : start;
    }
    final Object? title = entry['title'];
    final Object? location = entry['location'];
    final Object? description = entry['description'];
    final Object? calendarId = entry['calendarId'];
    return CalendarEvent(
      id: id,
      title: title is String ? title.trim() : '',
      start: start,
      end: stop,
      allDay: allDay,
      location: location is String && location.trim().isNotEmpty
          ? location.trim()
          : null,
      description: description is String && description.trim().isNotEmpty
          ? description.trim()
          : null,
      calendarId: calendarId is int ? calendarId : null,
      calendarVisible: entry['calendarVisible'] != false,
      repeating: entry['repeating'] == true,
      splitOff: entry['exception'] == true,
      occurrenceMillis: begin,
    );
  }

  /// A timed event is an instant; an all-day one is a *date*, stored as UTC
  /// midnight, whose calendar day must not shift with the time zone.
  static DateTime _local(int millis, bool allDay) {
    if (!allDay) return DateTime.fromMillisecondsSinceEpoch(millis);
    final DateTime utc = DateTime.fromMillisecondsSinceEpoch(
      millis,
      isUtc: true,
    );
    return DateTime(utc.year, utc.month, utc.day);
  }

  static bool _overlaps(CalendarEvent event, DateTime from, DateTime to) =>
      event.start.isBefore(to) &&
      (event.end.isAfter(from) ||
          // An event with no length is a moment: it is in range if it is in it.
          (event.end == event.start && !event.start.isBefore(from)));

  static int _byStart(CalendarEvent a, CalendarEvent b) {
    final int byStart = a.start.compareTo(b.start);
    if (byStart != 0) return byStart;
    if (a.allDay != b.allDay) return a.allDay ? -1 : 1;
    return a.title.toLowerCase().compareTo(b.title.toLowerCase());
  }
}

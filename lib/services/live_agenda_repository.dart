import 'package:android_tile_launcher/model/agenda_snapshot.dart';
import 'package:android_tile_launcher/model/calendar_choices.dart';
import 'package:android_tile_launcher/model/calendar_event.dart';
import 'package:android_tile_launcher/services/agenda_repository.dart';
import 'package:android_tile_launcher/services/calendar_service.dart';
import 'package:android_tile_launcher/services/local_store.dart';
import 'package:android_tile_launcher/services/permission_service.dart';

/// [AgendaRepository] on a [CalendarService] (the events) and a
/// [PermissionService] (asked only from [allow]). Which calendars show is
/// kept in [store] under [choicesKey] — its own key, not the settings, since
/// calendar ids mean nothing on another phone and the settings travel with an
/// exported layout. No [store] keeps them for this run only.
class LiveAgendaRepository implements AgendaRepository {
  LiveAgendaRepository({
    required this.calendar,
    required this.permissions,
    this.store,
  });

  static const String choicesKey = 'calendar_choices';

  final CalendarService calendar;
  final PermissionService permissions;
  final LocalStore? store;

  // Why the last request for access failed. Kept because Android reports "no
  // access" the same way whether it was never asked or was refused, and the
  // tile re-reads right after a tap: without this it would say "tap to allow"
  // again as if nothing had happened. Cleared as soon as a read succeeds, so
  // allowing it from Android's settings heals the tile at the next poll.
  AgendaDenied? _denied;

  // One request at a time: a second tap while the dialog is up joins it.
  Future<void>? _asking;

  // Read from [store] once, then kept here; every change is written through.
  CalendarChoices? _choices;

  @override
  Future<AgendaSnapshot> between(DateTime from, DateTime to) async {
    final CalendarResult result = await calendar.events(from: from, to: to);
    switch (result) {
      case CalendarEvents(:final List<CalendarEvent> events):
        _denied = null;
        final CalendarChoices choices = await calendarChoices();
        return AgendaReady(
          List<CalendarEvent>.unmodifiable(choices.filter(events)),
        );
      case CalendarNoAccess():
        return _denied ?? const AgendaNeedsPermission();
      case CalendarUnavailable(:final String reason):
        return AgendaUnavailable(reason);
    }
  }

  @override
  Future<void> allow() =>
      _asking ??= _allow().whenComplete(() => _asking = null);

  @override
  Future<CalendarListResult> calendars() => calendar.calendars();

  @override
  Future<CalendarChoices> calendarChoices() async {
    final CalendarChoices? known = _choices;
    if (known != null) return known;
    CalendarChoices read = const CalendarChoices();
    try {
      read = CalendarChoices.fromJson(await store?.read(choicesKey));
    } on Exception {
      // Unreadable choices are no choices: every calendar as the phone's own
      // calendar app shows it.
    }
    return _choices ??= read;
  }

  @override
  Future<void> setCalendarShown(int id, {required bool shown}) async {
    final CalendarChoices next = (await calendarChoices()).withShown(
      id,
      shown: shown,
    );
    _choices = next;
    try {
      await store?.write(choicesKey, next.toJson());
    } on Exception {
      // Kept for this run even if it could not be saved.
    }
  }

  @override
  Future<CalendarListResult> writableCalendars() async {
    final CalendarListResult result = await calendar.writableCalendars();
    if (result is! CalendarList) return result;
    final CalendarChoices choices = await calendarChoices();
    final List<CalendarInfo> shown = <CalendarInfo>[
      for (final CalendarInfo c in result.calendars)
        if (choices.shows(c)) c,
    ];
    return shown.isEmpty ? result : CalendarList(shown);
  }

  @override
  Future<CalendarWriteResult> createEvent(NewCalendarEvent event) =>
      calendar.createEvent(event);

  @override
  Future<CalendarWriteResult> updateEvent(
    CalendarEvent event,
    NewCalendarEvent draft,
  ) async {
    final int? from = event.calendarId;
    final int? to = draft.calendarId;
    final bool moving =
        from != null && to != null && from != to && !event.repeating;
    if (!moving) {
      // In place: the event's calendar is never rewritten, which sync
      // adapters (Google's among them) do not support for an existing event.
      return calendar.updateEvent(event, draft.onSameCalendar());
    }
    // Another calendar: a new event there, then the old one removed — a
    // calendar provider cannot move a synced event between accounts. If the
    // removal fails the user is left with two copies, never with none.
    final CalendarWriteResult created = await calendar.createEvent(draft);
    if (created is CalendarEventSaved) await calendar.deleteEvent(event);
    return created;
  }

  @override
  Future<CalendarDeleteResult> deleteEvent(CalendarEvent event) =>
      calendar.deleteEvent(event);

  Future<void> _allow() async {
    final PermissionStatus status = await permissions.request(
      AppPermission.calendar,
    );
    _denied = switch (status) {
      PermissionStatus.granted => null,
      PermissionStatus.denied => const AgendaDenied(permanent: false),
      PermissionStatus.permanentlyDenied => const AgendaDenied(permanent: true),
    };
  }
}

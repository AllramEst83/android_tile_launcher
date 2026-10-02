import 'package:android_tile_launcher/model/calendar_event.dart';

sealed class CalendarResult {
  const CalendarResult();
}

/// [events] is every occurrence that overlaps the range asked for, all-day
/// events first and then by start time.
class CalendarEvents extends CalendarResult {
  const CalendarEvents(this.events);

  final List<CalendarEvent> events;
}

/// Android has not given calendar access. Reading never asks; whoever wants
/// the dialog asks `PermissionService` first.
class CalendarNoAccess extends CalendarResult {
  const CalendarNoAccess();
}

/// Access is fine but the calendar could not be read; [reason] is short.
class CalendarUnavailable extends CalendarResult {
  const CalendarUnavailable(this.reason);

  final String reason;
}

sealed class CalendarListResult {
  const CalendarListResult();
}

class CalendarList extends CalendarListResult {
  const CalendarList(this.calendars);

  final List<CalendarInfo> calendars;
}

/// The user said no. [permanent] means Android will no longer ask, so the
/// caller should say where the setting is instead of asking again.
class CalendarListDenied extends CalendarListResult {
  const CalendarListDenied({required this.permanent});

  final bool permanent;
}

class CalendarListUnavailable extends CalendarListResult {
  const CalendarListUnavailable(this.reason);

  final String reason;
}

sealed class CalendarWriteResult {
  const CalendarWriteResult();
}

/// The event now exists (an add) or was changed (an edit); [id] is its
/// Android id either way.
class CalendarEventSaved extends CalendarWriteResult {
  const CalendarEventSaved(this.id);

  final int id;
}

class CalendarWriteDenied extends CalendarWriteResult {
  const CalendarWriteDenied({required this.permanent});

  final bool permanent;
}

class CalendarWriteFailed extends CalendarWriteResult {
  const CalendarWriteFailed(this.reason);

  final String reason;
}

sealed class CalendarDeleteResult {
  const CalendarDeleteResult();
}

class CalendarEventDeleted extends CalendarDeleteResult {
  const CalendarEventDeleted();
}

/// It was gone already (deleted elsewhere, or twice from this phone): not a
/// failure, since the end state is what was wanted.
class CalendarEventAlreadyGone extends CalendarDeleteResult {
  const CalendarEventAlreadyGone();
}

class CalendarDeleteDenied extends CalendarDeleteResult {
  const CalendarDeleteDenied({required this.permanent});

  final bool permanent;
}

class CalendarDeleteFailed extends CalendarDeleteResult {
  const CalendarDeleteFailed(this.reason);

  final String reason;
}

/// The phone's calendars (every account Android syncs), read through
/// Android's calendar provider.
abstract interface class CalendarService {
  /// Events overlapping the half-open range [from, to), from every calendar
  /// whether the phone's calendar app shows it or not (each event says, as
  /// `CalendarEvent.calendarVisible`). Never throws; never asks for
  /// permission itself.
  Future<CalendarResult> events({required DateTime from, required DateTime to});

  /// Every calendar on the phone, writable or not, grouped by account. Never
  /// asks for permission itself (no access is a [CalendarListDenied]); never
  /// throws.
  Future<CalendarListResult> calendars();

  /// The calendars an event could be added to. Asks for calendar permission
  /// itself; only ever called from an explicit tap (the add/edit form
  /// opening). Never throws.
  Future<CalendarListResult> writableCalendars();

  /// Adds [event] as a new event. Asks for calendar write permission itself;
  /// only ever called from an explicit Save tap. Never throws.
  Future<CalendarWriteResult> createEvent(NewCalendarEvent event);

  /// Replaces [event]'s fields with [draft]'s — only that occurrence when it
  /// is one of a repeating series (`CalendarEvent.isOccurrence`). Same
  /// permission behaviour as [createEvent]. Never throws; an event that no
  /// longer exists is a [CalendarWriteFailed].
  Future<CalendarWriteResult> updateEvent(
    CalendarEvent event,
    NewCalendarEvent draft,
  );

  /// Removes [event] — only that occurrence when it is one of a repeating
  /// series. Asks for calendar write permission itself; only ever called from
  /// an explicit Delete tap. Never throws.
  Future<CalendarDeleteResult> deleteEvent(CalendarEvent event);
}

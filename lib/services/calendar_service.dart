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

/// The phone's calendars (every account Android syncs), read through Android's
/// calendar provider. Read only; writing arrives in a later phase.
abstract interface class CalendarService {
  /// Events overlapping the half-open range [from, to). Never throws.
  Future<CalendarResult> events({required DateTime from, required DateTime to});
}

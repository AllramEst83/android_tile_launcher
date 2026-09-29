import 'package:android_tile_launcher/model/agenda_snapshot.dart';
import 'package:android_tile_launcher/model/calendar_event.dart';
import 'package:android_tile_launcher/services/calendar_service.dart';

/// The calendar for the agenda tile and its sheet. Both calls never throw:
/// every failure is an [AgendaSnapshot] the tile can word.
abstract interface class AgendaRepository {
  /// Events overlapping [from, to), or why there are none to show.
  Future<AgendaSnapshot> between(DateTime from, DateTime to);

  /// Asks Android for calendar access (showing its dialog if it still will).
  /// Only ever called from a tap: a permission dialog must never appear on its
  /// own. The outcome shows up in the next [between].
  Future<void> allow();

  /// The calendars an event could be added to. Only ever called from the
  /// add/edit form opening.
  Future<CalendarListResult> writableCalendars();

  /// Adds [event] as a new event. Only ever called from an explicit Save tap.
  Future<CalendarWriteResult> createEvent(NewCalendarEvent event);

  /// Replaces the event [id]'s fields with [event]'s. Only ever called from an
  /// explicit Save tap.
  Future<CalendarWriteResult> updateEvent(int id, NewCalendarEvent event);

  /// Removes the event [id]. Only ever called from an explicit Delete tap.
  Future<CalendarDeleteResult> deleteEvent(int id);
}

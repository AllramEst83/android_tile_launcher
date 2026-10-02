import 'package:android_tile_launcher/model/agenda_snapshot.dart';
import 'package:android_tile_launcher/model/calendar_choices.dart';
import 'package:android_tile_launcher/model/calendar_event.dart';
import 'package:android_tile_launcher/services/calendar_service.dart';

/// The calendar for the agenda tile and its sheet. Both calls never throw:
/// every failure is an [AgendaSnapshot] the tile can word.
abstract interface class AgendaRepository {
  /// Events overlapping [from, to) on the calendars [calendarChoices] shows,
  /// or why there are none to show.
  Future<AgendaSnapshot> between(DateTime from, DateTime to);

  /// Every calendar on the phone, for choosing which ones show. Never asks
  /// for permission.
  Future<CalendarListResult> calendars();

  /// Which calendars show.
  Future<CalendarChoices> calendarChoices();

  /// Shows or hides the calendar [id] from now on (the tile and the sheet
  /// both, at their next read).
  Future<void> setCalendarShown(int id, {required bool shown});

  /// Asks Android for calendar access (showing its dialog if it still will).
  /// Only ever called from a tap: a permission dialog must never appear on its
  /// own. The outcome shows up in the next [between].
  Future<void> allow();

  /// The calendars an event could be added to — of those, only the ones that
  /// show, so a new event never lands where it cannot be seen (unless every
  /// writable calendar is hidden). Only ever called from the add/edit form
  /// opening.
  Future<CalendarListResult> writableCalendars();

  /// Adds [event] as a new event. Only ever called from an explicit Save tap.
  Future<CalendarWriteResult> createEvent(NewCalendarEvent event);

  /// Replaces [event]'s fields with [draft]'s (only that occurrence, for one
  /// of a repeating series). A [draft] naming another calendar moves it
  /// there. Only ever called from an explicit Save tap.
  Future<CalendarWriteResult> updateEvent(
    CalendarEvent event,
    NewCalendarEvent draft,
  );

  /// Removes [event] (only that occurrence, for one of a repeating series).
  /// Only ever called from an explicit Delete tap.
  Future<CalendarDeleteResult> deleteEvent(CalendarEvent event);
}

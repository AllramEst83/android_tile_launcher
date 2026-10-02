import 'package:android_tile_launcher/model/agenda_snapshot.dart';
import 'package:android_tile_launcher/model/calendar_choices.dart';
import 'package:android_tile_launcher/model/calendar_event.dart';
import 'package:android_tile_launcher/services/agenda_repository.dart';
import 'package:android_tile_launcher/services/calendar_service.dart';

/// Answers with [snapshot] (less any events on a calendar [choices] hides);
/// [allow] switches to [afterAllow] and counts how often each was asked.
/// Remembers the last range asked for. The write calls each answer a
/// configurable result and record what they were given.
class FakeAgendaRepository implements AgendaRepository {
  FakeAgendaRepository([
    this.snapshot = const AgendaNeedsPermission(),
    this.afterAllow,
  ]);

  AgendaSnapshot snapshot;
  AgendaSnapshot? afterAllow;
  int betweenCalls = 0;
  int allowCalls = 0;
  DateTime? lastFrom;
  DateTime? lastTo;

  @override
  Future<AgendaSnapshot> between(DateTime from, DateTime to) async {
    betweenCalls++;
    lastFrom = from;
    lastTo = to;
    final AgendaSnapshot current = snapshot;
    if (current is AgendaReady) {
      return AgendaReady(choices.filter(current.events));
    }
    return current;
  }

  @override
  Future<void> allow() async {
    allowCalls++;
    snapshot = afterAllow ?? snapshot;
  }

  CalendarListResult calendarsResult = const CalendarList(<CalendarInfo>[]);
  CalendarChoices choices = const CalendarChoices();
  final List<(int, bool)> switched = <(int, bool)>[];

  @override
  Future<CalendarListResult> calendars() async => calendarsResult;

  @override
  Future<CalendarChoices> calendarChoices() async => choices;

  @override
  Future<void> setCalendarShown(int id, {required bool shown}) async {
    switched.add((id, shown));
    choices = choices.withShown(id, shown: shown);
  }

  CalendarListResult listResult = const CalendarList(<CalendarInfo>[]);

  @override
  Future<CalendarListResult> writableCalendars() async => listResult;

  CalendarWriteResult writeResult = const CalendarEventSaved(1);
  final List<NewCalendarEvent> created = <NewCalendarEvent>[];

  /// The id of each event updated, with the draft it was given.
  final List<(int, NewCalendarEvent)> updated = <(int, NewCalendarEvent)>[];
  final List<CalendarEvent> updatedEvents = <CalendarEvent>[];

  @override
  Future<CalendarWriteResult> createEvent(NewCalendarEvent event) async {
    created.add(event);
    return writeResult;
  }

  @override
  Future<CalendarWriteResult> updateEvent(
    CalendarEvent event,
    NewCalendarEvent draft,
  ) async {
    updated.add((event.id, draft));
    updatedEvents.add(event);
    return writeResult;
  }

  CalendarDeleteResult deleteResult = const CalendarEventDeleted();

  /// The id of each event deleted.
  final List<int> deleted = <int>[];
  final List<CalendarEvent> deletedEvents = <CalendarEvent>[];

  @override
  Future<CalendarDeleteResult> deleteEvent(CalendarEvent event) async {
    deleted.add(event.id);
    deletedEvents.add(event);
    return deleteResult;
  }
}

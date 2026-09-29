import 'package:android_tile_launcher/model/agenda_snapshot.dart';
import 'package:android_tile_launcher/model/calendar_event.dart';
import 'package:android_tile_launcher/services/agenda_repository.dart';
import 'package:android_tile_launcher/services/calendar_service.dart';

/// Answers with [snapshot]; [allow] switches to [afterAllow] and counts how
/// often each was asked. Remembers the last range asked for. The write calls
/// each answer a configurable result and record what they were given.
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
    return snapshot;
  }

  @override
  Future<void> allow() async {
    allowCalls++;
    snapshot = afterAllow ?? snapshot;
  }

  CalendarListResult listResult = const CalendarList(<CalendarInfo>[]);

  @override
  Future<CalendarListResult> writableCalendars() async => listResult;

  CalendarWriteResult writeResult = const CalendarEventSaved(1);
  final List<NewCalendarEvent> created = <NewCalendarEvent>[];
  final List<(int, NewCalendarEvent)> updated = <(int, NewCalendarEvent)>[];

  @override
  Future<CalendarWriteResult> createEvent(NewCalendarEvent event) async {
    created.add(event);
    return writeResult;
  }

  @override
  Future<CalendarWriteResult> updateEvent(
    int id,
    NewCalendarEvent event,
  ) async {
    updated.add((id, event));
    return writeResult;
  }

  CalendarDeleteResult deleteResult = const CalendarEventDeleted();
  final List<int> deleted = <int>[];

  @override
  Future<CalendarDeleteResult> deleteEvent(int id) async {
    deleted.add(id);
    return deleteResult;
  }
}

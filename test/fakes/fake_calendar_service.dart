import 'package:android_tile_launcher/model/calendar_event.dart';
import 'package:android_tile_launcher/services/calendar_service.dart';

/// Answers every read with [result] and records the range asked for; the
/// write calls each answer a configurable result and record what they were
/// given, so a service under test can be driven without a server.
class FakeCalendarService implements CalendarService {
  FakeCalendarService([this.result = const CalendarNoAccess()]);

  CalendarResult result;
  int calls = 0;
  DateTime? lastFrom;
  DateTime? lastTo;

  @override
  Future<CalendarResult> events({
    required DateTime from,
    required DateTime to,
  }) async {
    calls++;
    lastFrom = from;
    lastTo = to;
    return result;
  }

  CalendarListResult listResult = const CalendarList(<CalendarInfo>[]);
  int listCalls = 0;

  @override
  Future<CalendarListResult> writableCalendars() async {
    listCalls++;
    return listResult;
  }

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

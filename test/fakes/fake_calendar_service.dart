import 'package:android_tile_launcher/services/calendar_service.dart';

/// Answers every read with [result] and records the range asked for.
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
}

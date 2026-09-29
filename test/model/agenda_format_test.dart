import 'package:android_tile_launcher/model/agenda_format.dart';
import 'package:android_tile_launcher/model/calendar_event.dart';
import 'package:flutter_test/flutter_test.dart';

// Monday 28 September 2026.
final DateTime _now = DateTime(2026, 9, 28, 10, 30);

CalendarEvent _timed(
  String title,
  DateTime start,
  DateTime end, {
  String? location,
}) => CalendarEvent(
  id: title.hashCode,
  title: title,
  start: start,
  end: end,
  location: location,
);

CalendarEvent _allDay(String title, DateTime day, {int days = 1}) =>
    CalendarEvent(
      id: title.hashCode,
      title: title,
      start: day,
      end: DateTime(day.year, day.month, day.day + days),
      allDay: true,
    );

void main() {
  group('days', () {
    test('startOfDay drops the time', () {
      expect(startOfDay(_now), DateTime(2026, 9, 28));
    });

    test('addDays counts calendar days, across a month end', () {
      expect(addDays(DateTime(2026, 9, 30), 1), DateTime(2026, 10, 1));
    });

    test('addDays is one day across a daylight-saving change', () {
      // Sweden went back to standard time on 25 October 2026 (25-hour day).
      expect(addDays(DateTime(2026, 10, 25), 1), DateTime(2026, 10, 26));
    });
  });

  group('occursOn', () {
    final DateTime day = DateTime(2026, 9, 28);

    test('an event inside the day', () {
      expect(
        occursOn(
          _timed('a', DateTime(2026, 9, 28, 9), DateTime(2026, 9, 28, 10)),
          day,
        ),
        isTrue,
      );
    });

    test('one that ends at midnight is not on the next day', () {
      final CalendarEvent late = _timed(
        'a',
        DateTime(2026, 9, 27, 22),
        DateTime(2026, 9, 28),
      );

      expect(occursOn(late, day), isFalse);
      expect(occursOn(late, DateTime(2026, 9, 27)), isTrue);
    });

    test('one that runs over midnight is on both days', () {
      final CalendarEvent late = _timed(
        'a',
        DateTime(2026, 9, 28, 22),
        DateTime(2026, 9, 29, 1),
      );

      expect(occursOn(late, day), isTrue);
      expect(occursOn(late, DateTime(2026, 9, 29)), isTrue);
    });

    test('a moment is on its own day only', () {
      final DateTime at = DateTime(2026, 9, 28, 8);
      final CalendarEvent ping = _timed('a', at, at);

      expect(occursOn(ping, day), isTrue);
      expect(occursOn(ping, DateTime(2026, 9, 29)), isFalse);
      expect(occursOn(ping, DateTime(2026, 9, 27)), isFalse);
    });
  });

  group('groupByDay', () {
    test('lists an event under every day it spans, and skips empty days', () {
      final CalendarEvent trip = _allDay(
        'trip',
        DateTime(2026, 9, 29),
        days: 2,
      );
      final CalendarEvent lunch = _timed(
        'lunch',
        DateTime(2026, 9, 28, 12),
        DateTime(2026, 9, 28, 13),
      );

      final List<AgendaDay> days = groupByDay(
        <CalendarEvent>[lunch, trip],
        from: _now,
        days: 7,
      );

      expect(days.map((AgendaDay d) => d.day), <DateTime>[
        DateTime(2026, 9, 28),
        DateTime(2026, 9, 29),
        DateTime(2026, 9, 30),
      ]);
      expect(days[0].events, <CalendarEvent>[lunch]);
      expect(days[1].events, <CalendarEvent>[trip]);
      expect(days[2].events, <CalendarEvent>[trip]);
    });

    test('leaves out days beyond the range', () {
      final CalendarEvent later = _allDay('later', DateTime(2026, 10, 20));

      expect(groupByDay(<CalendarEvent>[later], from: _now, days: 7), isEmpty);
    });
  });

  group('nextEvent', () {
    test('prefers a timed event over an all-day one before it', () {
      final CalendarEvent holiday = _allDay('holiday', DateTime(2026, 9, 28));
      final CalendarEvent meeting = _timed(
        'meeting',
        DateTime(2026, 9, 28, 14),
        DateTime(2026, 9, 28, 15),
      );

      expect(nextEvent(<CalendarEvent>[holiday, meeting]), meeting);
    });

    test('falls back to the all-day event when that is all there is', () {
      final CalendarEvent holiday = _allDay('holiday', DateTime(2026, 9, 28));

      expect(nextEvent(<CalendarEvent>[holiday]), holiday);
    });

    test('is null with no events', () {
      expect(nextEvent(const <CalendarEvent>[]), isNull);
    });
  });

  group('formatDayHeading', () {
    test('today, tomorrow, yesterday, then the date', () {
      expect(formatDayHeading(DateTime(2026, 9, 28), _now), 'TODAY');
      expect(formatDayHeading(DateTime(2026, 9, 29), _now), 'TOMORROW');
      expect(formatDayHeading(DateTime(2026, 9, 27), _now), 'YESTERDAY');
      expect(formatDayHeading(DateTime(2026, 9, 30), _now), 'WED 30 SEP');
    });
  });

  group('formatWeekHeading', () {
    test('this week, next week, last week, then the range', () {
      expect(formatWeekHeading(DateTime(2026, 9, 28), _now), 'THIS WEEK');
      expect(formatWeekHeading(DateTime(2026, 10, 5), _now), 'NEXT WEEK');
      expect(formatWeekHeading(DateTime(2026, 9, 21), _now), 'LAST WEEK');
      expect(formatWeekHeading(DateTime(2026, 10, 12), _now), '12 OCT-18 OCT');
    });

    test('a range that crosses a month end', () {
      expect(formatWeekHeading(DateTime(2026, 9, 29), _now), '29 SEP-5 OCT');
    });
  });

  group('formatWhen', () {
    test('a later time today is just the time', () {
      expect(
        formatWhen(
          _timed('a', DateTime(2026, 9, 28, 14, 5), DateTime(2026, 9, 28, 15)),
          _now,
        ),
        '14:05',
      );
    });

    test('an event under way is NOW', () {
      expect(
        formatWhen(
          _timed('a', DateTime(2026, 9, 28, 10), DateTime(2026, 9, 28, 11)),
          _now,
        ),
        'NOW',
      );
    });

    test('one that began yesterday and is still going is NOW', () {
      expect(
        formatWhen(
          _timed('a', DateTime(2026, 9, 27, 22), DateTime(2026, 9, 28, 12)),
          _now,
        ),
        'NOW',
      );
    });

    test('a later day gets its weekday', () {
      expect(
        formatWhen(
          _timed('a', DateTime(2026, 9, 30, 9), DateTime(2026, 9, 30, 10)),
          _now,
        ),
        'WED 09:00',
      );
    });

    test('an all-day event today, and on a later day', () {
      expect(formatWhen(_allDay('a', DateTime(2026, 9, 28)), _now), 'ALL DAY');
      expect(
        formatWhen(_allDay('a', DateTime(2026, 9, 30)), _now),
        'WED ALL DAY',
      );
    });

    test('a multi-day all-day event already under way counts as today', () {
      expect(
        formatWhen(_allDay('a', DateTime(2026, 9, 26), days: 5), _now),
        'ALL DAY',
      );
    });
  });

  group('formatSpan', () {
    final DateTime day = DateTime(2026, 9, 28);

    test('hours within the day', () {
      expect(
        formatSpan(
          _timed('a', DateTime(2026, 9, 28, 9), DateTime(2026, 9, 28, 10, 30)),
          day,
        ),
        '09:00-10:30',
      );
    });

    test('runs on past midnight', () {
      expect(
        formatSpan(
          _timed('a', DateTime(2026, 9, 28, 22), DateTime(2026, 9, 29, 1)),
          day,
        ),
        'FROM 22:00',
      );
    });

    test('began the day before', () {
      expect(
        formatSpan(
          _timed('a', DateTime(2026, 9, 27, 22), DateTime(2026, 9, 28, 2)),
          day,
        ),
        'UNTIL 02:00',
      );
    });

    test('covers the whole day', () {
      expect(
        formatSpan(
          _timed('a', DateTime(2026, 9, 27, 22), DateTime(2026, 9, 29, 2)),
          day,
        ),
        'ALL DAY',
      );
    });

    test('an all-day event, and a moment', () {
      expect(formatSpan(_allDay('a', day), day), 'ALL DAY');
      final DateTime at = DateTime(2026, 9, 28, 8, 15);
      expect(formatSpan(_timed('a', at, at), day), '08:15');
    });
  });
}

import 'package:android_tile_launcher/model/clock_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatDuration', () {
    test('as short as it can be', () {
      expect(formatDuration(const Duration(minutes: 10)), '10 min');
      expect(
        formatDuration(const Duration(hours: 1, minutes: 30)),
        '1 h 30 min',
      );
      expect(formatDuration(const Duration(seconds: 45)), '45 s');
      expect(formatDuration(const Duration(hours: 2)), '2 h');
      expect(
        formatDuration(const Duration(hours: 1, minutes: 2, seconds: 3)),
        '1 h 2 min 3 s',
      );
    });
  });

  group('nextOccurrence', () {
    final DateTime now = DateTime(2026, 9, 28, 10, 30);

    test('today if the time is still to come', () {
      expect(
        nextOccurrence(now, (hour: 18, minute: 0)),
        DateTime(2026, 9, 28, 18),
      );
    });

    test('tomorrow if it has passed, or is this very minute', () {
      expect(
        nextOccurrence(now, (hour: 7, minute: 30)),
        DateTime(2026, 9, 29, 7, 30),
      );
      expect(
        nextOccurrence(now, (hour: 10, minute: 30)),
        DateTime(2026, 9, 29, 10, 30),
      );
    });

    test('tomorrow can be the next month', () {
      expect(
        nextOccurrence(DateTime(2026, 9, 30, 23), (hour: 6, minute: 0)),
        DateTime(2026, 10, 1, 6),
      );
    });
  });

  group('clockText and dayName', () {
    test('two digits each', () {
      expect(clockText(7, 5), '07:05');
      expect(clockText(19, 45), '19:45');
    });

    test('days are three capitals, Monday first', () {
      expect(dayName(1), 'MON');
      expect(dayName(7), 'SUN');
    });
  });

  group('describeDays', () {
    test('a run of days is first and last', () {
      expect(describeDays(<int>[1, 2, 3, 4, 5]), 'MON-FRI');
      expect(describeDays(<int>[2, 3, 4]), 'TUE-THU');
    });

    test('other days are listed', () {
      expect(describeDays(<int>[6, 7]), 'SAT SUN');
      expect(describeDays(<int>[1, 3, 5]), 'MON WED FRI');
      expect(describeDays(<int>[4]), 'THU');
    });

    test('every day is daily, whatever the order', () {
      expect(describeDays(<int>[7, 6, 5, 4, 3, 2, 1]), 'DAILY');
    });

    test('a day given twice counts once', () {
      expect(describeDays(<int>[1, 1, 2]), 'MON TUE');
    });
  });

  test('a timer is at most 24 hours', () {
    expect(maxTimer, const Duration(hours: 24));
  });
}

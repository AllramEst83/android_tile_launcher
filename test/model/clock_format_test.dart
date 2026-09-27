import 'package:android_tile_launcher/model/clock_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatClockTime', () {
    test('pads a single-digit hour and minute', () {
      expect(formatClockTime(DateTime(2026, 1, 1, 9, 5)), '09:05');
    });

    test('keeps 24-hour time as-is', () {
      expect(formatClockTime(DateTime(2026, 1, 1, 14, 32)), '14:32');
    });

    test('midnight is 00:00', () {
      expect(formatClockTime(DateTime(2026, 1, 1)), '00:00');
    });
  });

  group('formatClockDate', () {
    test('weekday, day, month, all uppercase', () {
      // 2026-09-27 is a Sunday.
      expect(formatClockDate(DateTime(2026, 9, 27)), 'SUN 27 SEP');
    });

    test('Monday through Sunday map correctly', () {
      expect(formatClockDate(DateTime(2026, 9, 21)), 'MON 21 SEP');
      expect(formatClockDate(DateTime(2026, 9, 22)), 'TUE 22 SEP');
      expect(formatClockDate(DateTime(2026, 9, 23)), 'WED 23 SEP');
      expect(formatClockDate(DateTime(2026, 9, 24)), 'THU 24 SEP');
      expect(formatClockDate(DateTime(2026, 9, 25)), 'FRI 25 SEP');
      expect(formatClockDate(DateTime(2026, 9, 26)), 'SAT 26 SEP');
    });

    test('does not pad the day of month', () {
      expect(formatClockDate(DateTime(2026, 1, 5)), 'MON 5 JAN');
    });
  });
}

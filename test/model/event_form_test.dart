import 'package:android_tile_launcher/model/event_form.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatEventDate / formatEventTime', () {
    test('pads to two digits', () {
      expect(formatEventDate(DateTime(2026, 1, 5)), '2026-01-05');
      expect(formatEventTime(DateTime(2026, 1, 5, 9, 5)), '09:05');
    });
  });

  group('parseEventDate', () {
    test('reads a valid date', () {
      expect(parseEventDate('2026-09-28'), DateTime(2026, 9, 28));
    });

    test('trims surrounding space', () {
      expect(parseEventDate(' 2026-09-28 '), DateTime(2026, 9, 28));
    });

    test('refuses a day that does not exist rather than rounding it', () {
      expect(parseEventDate('2026-02-30'), isNull);
    });

    test('refuses anything not shaped like a date', () {
      expect(parseEventDate('28/9/2026'), isNull);
      expect(parseEventDate('today'), isNull);
      expect(parseEventDate(''), isNull);
    });
  });

  group('parseEventTime', () {
    final DateTime day = DateTime(2026, 9, 28);

    test('combines the day with a valid time', () {
      expect(parseEventTime(day, '14:30'), DateTime(2026, 9, 28, 14, 30));
    });

    test('accepts a single-digit hour', () {
      expect(parseEventTime(day, '9:05'), DateTime(2026, 9, 28, 9, 5));
    });

    test('refuses an hour or minute out of range', () {
      expect(parseEventTime(day, '24:00'), isNull);
      expect(parseEventTime(day, '12:60'), isNull);
    });

    test('refuses anything not shaped like a time', () {
      expect(parseEventTime(day, 'noon'), isNull);
      expect(parseEventTime(day, ''), isNull);
    });
  });
}

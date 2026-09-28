import 'package:android_tile_launcher/model/timer_entry.dart';
import 'package:flutter_test/flutter_test.dart';

TimerEntry _keyed(List<int> digits) =>
    digits.fold(const TimerEntry(), (TimerEntry e, int d) => e.press(d));

void main() {
  group('keying', () {
    test('digits shift in from the right, like a microwave', () {
      expect(_keyed(<int>[1]).display, '00:00:01');
      expect(_keyed(<int>[1, 0]).display, '00:00:10');
      expect(_keyed(<int>[1, 0, 0, 0]).display, '00:10:00');
      expect(_keyed(<int>[1, 3, 0, 0, 0, 0]).display, '13:00:00');
    });

    test('nothing keyed reads all zeros, and cannot be started', () {
      expect(const TimerEntry().display, '00:00:00');
      expect(const TimerEntry().canStart, isFalse);
    });

    test('a zero to start with is nothing', () {
      expect(_keyed(<int>[0, 0, 5]).display, '00:00:05');
      expect(_keyed(<int>[0]).digits, '');
    });

    test('takes six digits and no more', () {
      expect(_keyed(<int>[1, 2, 3, 4, 5, 6, 7, 8]).digits, '123456');
    });

    test('DEL takes back the last digit, clear all of them', () {
      expect(_keyed(<int>[1, 2, 3]).backspace().digits, '12');
      expect(const TimerEntry().backspace().digits, '');
      expect(_keyed(<int>[1, 2, 3]).clear().digits, '');
    });
  });

  group('the length', () {
    test('the last two digits are seconds, then minutes, then hours', () {
      expect(_keyed(<int>[1, 0, 0, 0]).length, const Duration(minutes: 10));
      expect(
        _keyed(<int>[1, 2, 3, 4, 5, 6]).length,
        const Duration(hours: 12, minutes: 34, seconds: 56),
      );
    });

    test('90 is 90 seconds, not an error', () {
      expect(_keyed(<int>[9, 0]).length, const Duration(seconds: 90));
      expect(_keyed(<int>[9, 0]).canStart, isTrue);
    });
  });

  group('limits', () {
    test('up to 24 hours can be started, no more', () {
      expect(_keyed(<int>[2, 4, 0, 0, 0, 0]).canStart, isTrue);
      expect(_keyed(<int>[2, 4, 0, 0, 0, 1]).canStart, isFalse);
      expect(_keyed(<int>[2, 4, 0, 0, 0, 1]).tooLong, isTrue);
      expect(_keyed(<int>[9, 9, 9, 9, 9, 9]).tooLong, isTrue);
    });

    test('a length that is fine is not too long', () {
      expect(_keyed(<int>[1, 0, 0, 0]).tooLong, isFalse);
    });
  });

  group('TimerEntry.of', () {
    test('a length already keyed, as the presets are', () {
      expect(TimerEntry.of(const Duration(minutes: 5)).display, '00:05:00');
      expect(TimerEntry.of(const Duration(hours: 1)).display, '01:00:00');
      expect(TimerEntry.of(const Duration(seconds: 90)).display, '00:01:30');
      expect(
        TimerEntry.of(const Duration(minutes: 5)).length,
        const Duration(minutes: 5),
      );
    });

    test('can be added to like any other entry', () {
      expect(
        TimerEntry.of(const Duration(minutes: 5)).press(0).length,
        const Duration(minutes: 50),
      );
    });
  });
}

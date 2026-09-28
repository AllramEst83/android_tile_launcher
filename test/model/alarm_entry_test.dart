import 'package:android_tile_launcher/model/alarm_entry.dart';
import 'package:flutter_test/flutter_test.dart';

AlarmEntry _keyed(List<int> digits) =>
    digits.fold(const AlarmEntry(), (AlarmEntry e, int d) => e.press(d));

void main() {
  group('keying', () {
    test('digits go left to right, with dashes for the rest', () {
      expect(const AlarmEntry().display, '--:--');
      expect(_keyed(<int>[0]).display, '0-:--');
      expect(_keyed(<int>[0, 7]).display, '07:--');
      expect(_keyed(<int>[0, 7, 3]).display, '07:3-');
      expect(_keyed(<int>[0, 7, 3, 0]).display, '07:30');
    });

    test('is complete only with all four digits', () {
      expect(_keyed(<int>[0, 7, 3]).complete, isFalse);
      expect(_keyed(<int>[0, 7, 3]).time, isNull);
      expect(_keyed(<int>[0, 7, 3, 0]).complete, isTrue);
      expect(_keyed(<int>[0, 7, 3, 0]).time, (hour: 7, minute: 30));
    });

    test('takes four digits and no more', () {
      expect(_keyed(<int>[0, 7, 3, 0, 5]).digits, '0730');
    });

    test('DEL takes back a digit, clear all of them', () {
      expect(_keyed(<int>[0, 7, 3]).backspace().display, '07:--');
      expect(const AlarmEntry().backspace().digits, '');
      expect(_keyed(<int>[0, 7, 3, 0]).clear().display, '--:--');
    });
  });

  group('only real times', () {
    test('the first hour digit is 0, 1 or 2', () {
      expect(_keyed(<int>[3]).digits, '');
      expect(_keyed(<int>[9]).digits, '');
      expect(_keyed(<int>[2]).digits, '2');
    });

    test('after a 2 the hour goes to 23 at most', () {
      expect(_keyed(<int>[2, 4]).digits, '2');
      expect(_keyed(<int>[2, 3]).digits, '23');
    });

    test('after a 0 or 1 any digit does for the hour', () {
      expect(_keyed(<int>[0, 9]).digits, '09');
      expect(_keyed(<int>[1, 9]).digits, '19');
    });

    test('the tens of minutes are 0 to 5', () {
      expect(_keyed(<int>[0, 7, 6]).digits, '07');
      expect(_keyed(<int>[0, 7, 5]).digits, '075');
    });

    test('so 23:59 can be keyed and nothing past it', () {
      expect(_keyed(<int>[2, 3, 5, 9]).time, (hour: 23, minute: 59));
      expect(_keyed(<int>[2, 4, 0, 0]).time, isNull);
    });

    test('a rejected digit does not stop the next good one', () {
      expect(_keyed(<int>[3, 0, 7]).display, '07:--');
    });
  });
}

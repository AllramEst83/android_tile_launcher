import 'package:android_tile_launcher/model/clock_input.dart';

/// The time of day keyed on the alarm pad, left to right like a page number:
/// keying 0, 7, 3, 0 reads `07:30`, with `-` where a digit is still to come.
/// A digit that could not lead to a real time (a 3 first, a 7 for the tens of
/// minutes) is ignored, so a finished entry is always a valid time. Pure:
/// every key returns the next entry.
class AlarmEntry {
  const AlarmEntry([this.digits = '']);

  /// Up to four digits, hour then minute.
  final String digits;

  AlarmEntry press(int digit) {
    if (digits.length >= 4) return this;
    final bool fits = switch (digits.length) {
      // The first hour digit: 0, 1 or 2.
      0 => digit <= 2,
      // The second: any after 0 or 1, but not past 23 after a 2.
      1 => digits == '2' ? digit <= 3 : true,
      // The first minute digit: 0 to 5.
      2 => digit <= 5,
      _ => true,
    };
    return fits ? AlarmEntry('$digits$digit') : this;
  }

  AlarmEntry backspace() => digits.isEmpty
      ? this
      : AlarmEntry(digits.substring(0, digits.length - 1));

  AlarmEntry clear() => const AlarmEntry();

  /// `07:30`, or `07:--` / `--:--` while it is being keyed.
  String get display {
    final String padded = digits.padRight(4, '-');
    return '${padded.substring(0, 2)}:${padded.substring(2, 4)}';
  }

  /// The time keyed, once all four digits are there.
  ClockTime? get time {
    if (digits.length < 4) return null;
    return (
      hour: int.parse(digits.substring(0, 2)),
      minute: int.parse(digits.substring(2, 4)),
    );
  }

  bool get complete => time != null;
}

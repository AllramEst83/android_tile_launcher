import 'package:android_tile_launcher/model/clock_input.dart';

/// The most digits a timer takes: hours, minutes and seconds, two each.
const int _maxDigits = 6;

/// The length keyed on the timer pad, as digits that shift in from the right
/// like a microwave's: keying 1, 0, 0, 0 reads `00:10:00`. Pure: every key
/// returns the next entry.
class TimerEntry {
  const TimerEntry([this.digits = '']);

  /// The digits keyed, without leading zeros (a 0 keyed first is nothing).
  final String digits;

  /// A timer of [length] already keyed, as the presets do.
  factory TimerEntry.of(Duration length) {
    final int total = length.inSeconds;
    final int hours = total ~/ 3600;
    final int minutes = total % 3600 ~/ 60;
    final int seconds = total % 60;
    final String raw =
        '${hours.toString().padLeft(2, '0')}'
        '${minutes.toString().padLeft(2, '0')}'
        '${seconds.toString().padLeft(2, '0')}';
    return TimerEntry(raw.replaceFirst(RegExp(r'^0+'), ''));
  }

  TimerEntry press(int digit) {
    if (digits.length >= _maxDigits) return this;
    if (digits.isEmpty && digit == 0) return this;
    return TimerEntry('$digits$digit');
  }

  TimerEntry backspace() => digits.isEmpty
      ? this
      : TimerEntry(digits.substring(0, digits.length - 1));

  TimerEntry clear() => const TimerEntry();

  /// The length as keyed: the last two digits are seconds, the two before
  /// minutes and the rest hours, so keying `90` reads as 90 seconds (a minute
  /// and a half), not as an error.
  Duration get length {
    final String padded = digits.padLeft(_maxDigits, '0');
    return Duration(
      hours: int.parse(padded.substring(0, 2)),
      minutes: int.parse(padded.substring(2, 4)),
      seconds: int.parse(padded.substring(4, 6)),
    );
  }

  /// The length as it is shown while keying, `00:10:00`: the digits as keyed,
  /// not normalised, so what is typed is what is seen.
  String get display {
    final String padded = digits.padLeft(_maxDigits, '0');
    return '${padded.substring(0, 2)}:${padded.substring(2, 4)}:${padded.substring(4, 6)}';
  }

  /// Whether the timer can be started: something keyed, and no more than the
  /// 24 hours Android's clock takes.
  bool get canStart => length > Duration.zero && length <= maxTimer;

  /// Keyed longer than a clock's timer can be.
  bool get tooLong => length > maxTimer;
}

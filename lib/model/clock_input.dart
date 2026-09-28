/// The longest a timer may be: Android's clock takes one to 86,400 seconds.
const Duration maxTimer = Duration(hours: 24);

/// `10 min`, `1 h 30 min`, `45 s`, `2 h`: as short as it can be.
String formatDuration(Duration length) {
  final int hours = length.inHours;
  final int minutes = length.inMinutes % 60;
  final int seconds = length.inSeconds % 60;
  return <String>[
    if (hours > 0) '$hours h',
    if (minutes > 0) '$minutes min',
    if (seconds > 0) '$seconds s',
  ].join(' ');
}

/// A time of day as `(hour, minute)` on a 24-hour clock.
typedef ClockTime = ({int hour, int minute});

/// The next time the clock reads [time] after [now]: today if that is still to
/// come, else tomorrow. Calendar days, so a daylight-saving change never lands
/// it an hour off.
DateTime nextOccurrence(DateTime now, ClockTime time) {
  final DateTime today = DateTime(
    now.year,
    now.month,
    now.day,
    time.hour,
    time.minute,
  );
  return today.isAfter(now)
      ? today
      : DateTime(now.year, now.month, now.day + 1, time.hour, time.minute);
}

/// `07:30`.
String clockText(int hour, int minute) =>
    '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

const List<String> _dayNames = <String>[
  'MON',
  'TUE',
  'WED',
  'THU',
  'FRI',
  'SAT',
  'SUN',
];

/// The three letters for a day of the week, `DateTime.monday` (1) to
/// `DateTime.sunday` (7).
String dayName(int day) => _dayNames[day - 1];

/// `MON-FRI`, `SAT SUN`, `DAILY`: [days] (1 to 7) as short as it reads.
String describeDays(Iterable<int> days) {
  final List<int> sorted = <int>{...days}.toList()..sort();
  if (sorted.length == 7) return 'DAILY';
  final List<String> names = <String>[for (final int d in sorted) dayName(d)];
  final bool consecutive =
      sorted.length >= 3 &&
      <int>[for (int i = 1; i < sorted.length; i++) sorted[i] - sorted[i - 1]]
          .every((int step) => step == 1);
  return consecutive ? '${names.first}-${names.last}' : names.join(' ');
}

/// `12°`, `-3°`; never `-0°`.
String formatDegrees(double celsius) {
  final int whole = celsius.round();
  return '${whole == 0 ? 0 : whole}°';
}

const List<String> _weekdays = <String>[
  'MON',
  'TUE',
  'WED',
  'THU',
  'FRI',
  'SAT',
  'SUN',
];

/// `MON`..`SUN` for [date].
String weekdayAbbreviation(DateTime date) => _weekdays[date.weekday - 1];

const List<String> _weekdays = <String>[
  'MON',
  'TUE',
  'WED',
  'THU',
  'FRI',
  'SAT',
  'SUN',
];

const List<String> _months = <String>[
  'JAN',
  'FEB',
  'MAR',
  'APR',
  'MAY',
  'JUN',
  'JUL',
  'AUG',
  'SEP',
  'OCT',
  'NOV',
  'DEC',
];

/// `14:32`, 24-hour, in the device's local time.
String formatClockTime(DateTime t) => '${_two(t.hour)}:${_two(t.minute)}';

/// `FRI 27 SEP`.
String formatClockDate(DateTime t) =>
    '${_weekdays[t.weekday - 1]} ${t.day} ${_months[t.month - 1]}';

/// `SEP` — [month] is 1-based (`DateTime.month`'s own numbering).
String monthAbbreviation(int month) => _months[month - 1];

String _two(int n) => n.toString().padLeft(2, '0');

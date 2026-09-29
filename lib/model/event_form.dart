/// Parsing and formatting for the event add/edit form's date and time text
/// fields (`YYYY-MM-DD` and `HH:MM`), kept apart from the widget so it is
/// unit-tested without pumping a sheet.
library;

/// `2026-09-28`, from [date]'s own calendar day.
String formatEventDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// `14:30`, from [time]'s own hour and minute.
String formatEventTime(DateTime time) =>
    '${time.hour.toString().padLeft(2, '0')}:'
    '${time.minute.toString().padLeft(2, '0')}';

/// [text] as a calendar day, or null if it is not `YYYY-MM-DD` naming one
/// that exists (`2026-02-30` is refused, not rounded into March).
DateTime? parseEventDate(String text) {
  final RegExpMatch? match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$')
      .firstMatch(text.trim());
  if (match == null) return null;
  final int year = int.parse(match.group(1)!);
  final int month = int.parse(match.group(2)!);
  final int day = int.parse(match.group(3)!);
  final DateTime date = DateTime(year, month, day);
  if (date.year != year || date.month != month || date.day != day) {
    return null;
  }
  return date;
}

/// [date]'s own day at the time [text] names (`HH:MM`, 24-hour), or null if
/// it is not a valid time.
DateTime? parseEventTime(DateTime date, String text) {
  final RegExpMatch? match = RegExp(r'^(\d{1,2}):(\d{2})$')
      .firstMatch(text.trim());
  if (match == null) return null;
  final int hour = int.parse(match.group(1)!);
  final int minute = int.parse(match.group(2)!);
  if (hour > 23 || minute > 59) return null;
  return DateTime(date.year, date.month, date.day, hour, minute);
}

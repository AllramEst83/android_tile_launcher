import 'package:android_tile_launcher/model/calendar_event.dart';
import 'package:android_tile_launcher/model/clock_format.dart';
import 'package:android_tile_launcher/model/weather_format.dart';

/// Midnight at the start of [t]'s day.
DateTime startOfDay(DateTime t) => DateTime(t.year, t.month, t.day);

/// The day [days] after [day], at midnight. Built from the calendar date,
/// never by adding 24 hours, so a daylight-saving day is still one day.
DateTime addDays(DateTime day, int days) =>
    DateTime(day.year, day.month, day.day + days);

/// The Monday, at midnight, of the week [t] falls in — the agenda's week
/// runs Monday to Sunday, not a rolling seven days from whatever day it was
/// opened on.
DateTime mondayOf(DateTime t) => addDays(startOfDay(t), -(t.weekday - 1));

/// Whether [event] takes up any of the day starting at [day].
bool occursOn(CalendarEvent event, DateTime day) {
  final DateTime next = addDays(day, 1);
  return event.start.isBefore(next) &&
      (event.end.isAfter(day) ||
          // An event with no length is a moment: it is on the day it is in.
          (event.end == event.start && !event.start.isBefore(day)));
}

/// One day of an agenda and what happens on it.
class AgendaDay {
  const AgendaDay({required this.day, required this.events});

  final DateTime day;
  final List<CalendarEvent> events;
}

/// [events] laid out by day for the [days] days from [from]'s day. An event
/// that spans several days is listed under each of them; a day with nothing
/// on is left out.
List<AgendaDay> groupByDay(
  List<CalendarEvent> events, {
  required DateTime from,
  required int days,
}) {
  final DateTime first = startOfDay(from);
  return <AgendaDay>[
    for (int i = 0; i < days; i++)
      if (events.any((CalendarEvent e) => occursOn(e, addDays(first, i))))
        AgendaDay(
          day: addDays(first, i),
          events: <CalendarEvent>[
            for (final CalendarEvent e in events)
              if (occursOn(e, addDays(first, i))) e,
          ],
        ),
  ];
}

/// The event the tile leads with: the first timed one (a meeting is more
/// useful to see than a birthday), else the first of whatever there is.
CalendarEvent? nextEvent(List<CalendarEvent> events) {
  for (final CalendarEvent e in events) {
    if (!e.allDay) return e;
  }
  return events.isEmpty ? null : events.first;
}

/// `TODAY`, `TOMORROW`, `YESTERDAY`, else `TUE 29 SEP` — for a day the agenda
/// sheet may have navigated to, not only today's own group heading.
String formatDayHeading(DateTime day, DateTime now) {
  final DateTime today = startOfDay(now);
  if (day == today) return 'TODAY';
  if (day == addDays(today, 1)) return 'TOMORROW';
  if (day == addDays(today, -1)) return 'YESTERDAY';
  return formatClockDate(day);
}

/// `THIS WEEK`, `NEXT WEEK`, `LAST WEEK`, else the Monday-to-Sunday week's
/// first and last day, `29 SEP-5 OCT` (the agenda's week is never far enough
/// out to need a year). [weekStart] is the week's own Monday, the same one
/// [groupByDay]'s own `from` would be given.
String formatWeekHeading(DateTime weekStart, DateTime now) {
  final DateTime thisWeek = mondayOf(now);
  if (weekStart == thisWeek) return 'THIS WEEK';
  if (weekStart == addDays(thisWeek, 7)) return 'NEXT WEEK';
  if (weekStart == addDays(thisWeek, -7)) return 'LAST WEEK';
  final DateTime last = addDays(weekStart, 6);
  return '${weekStart.day} ${monthAbbreviation(weekStart.month)}'
      '-${last.day} ${monthAbbreviation(last.month)}';
}

/// When [event] happens, for a tile line: `NOW` if under way, `14:30` today,
/// `TUE 09:00` on a later day, `ALL DAY` or `TUE ALL DAY` for a date.
String formatWhen(CalendarEvent event, DateTime now) {
  final DateTime today = startOfDay(now);
  final DateTime day = event.start.isBefore(today)
      ? today
      : startOfDay(event.start);
  final String prefix = day == today ? '' : '${weekdayAbbreviation(day)} ';
  if (event.allDay) return '${prefix}ALL DAY';
  if (!event.start.isAfter(now)) return 'NOW';
  return '$prefix${formatClockTime(event.start)}';
}

/// The hours of [event] on the day starting at [day], for the agenda sheet:
/// `09:00-10:30`, `FROM 22:00` if it runs on past midnight, `UNTIL 02:00` if it
/// began the day before, `ALL DAY` for a date or a span covering the day.
String formatSpan(CalendarEvent event, DateTime day) {
  if (event.allDay) return 'ALL DAY';
  final DateTime next = addDays(day, 1);
  final bool before = event.start.isBefore(day);
  final bool after = event.end.isAfter(next);
  if (before && after) return 'ALL DAY';
  if (before) return 'UNTIL ${formatClockTime(event.end)}';
  if (after) return 'FROM ${formatClockTime(event.start)}';
  if (event.end == event.start) return formatClockTime(event.start);
  return '${formatClockTime(event.start)}-${formatClockTime(event.end)}';
}

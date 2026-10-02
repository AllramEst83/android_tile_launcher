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

/// The portion of [event] that falls within the day starting at [day]: its
/// start and end clamped to that day's bounds (`day` to `day` + 1 day).
/// `null` when [event] does not occur on [day] at all, or occurs on it for
/// zero length (it merely touches the boundary — ends exactly at [day]'s
/// start, or starts exactly at its end). For a view that draws one block per
/// day (the agenda week grid) rather than the agenda list's own text span
/// (`formatSpan`), since a multi-day event needs its own start/end on each
/// day it touches, not just the one day its own `CalendarEvent.start` is on.
({DateTime start, DateTime end})? clampToDay(
  CalendarEvent event,
  DateTime day,
) {
  final DateTime next = addDays(day, 1);
  final DateTime start = event.start.isBefore(day) ? day : event.start;
  final DateTime end = event.end.isAfter(next) ? next : event.end;
  if (!end.isAfter(start)) return null;
  return (start: start, end: end);
}

/// One day of an agenda and what happens on it.
class AgendaDay {
  const AgendaDay({required this.day, required this.events});

  final DateTime day;
  final List<CalendarEvent> events;
}

/// Whether [event] fills the whole day starting at [day]: an all-day event,
/// or a timed one that began before it and runs on past it (the middle day of
/// a three-day trip) — what the agenda list calls `ALL DAY` and the week grid
/// puts in its all-day row rather than as a block.
bool coversDay(CalendarEvent event, DateTime day) {
  if (event.allDay) return occursOn(event, day);
  return !event.start.isAfter(day) && !event.end.isBefore(addDays(day, 1));
}

/// [events] laid out by day for the [days] days from [from]'s day. An event
/// that spans several days is listed under each of them; a day with nothing
/// on is left out. Within a day, whatever fills it ([coversDay]) comes first,
/// then the rest by when they start *on that day* — so an overnight event
/// that began yesterday sorts by its midnight, not by yesterday's start.
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
          events: _inDayOrder(<CalendarEvent>[
            for (final CalendarEvent e in events)
              if (occursOn(e, addDays(first, i))) e,
          ], addDays(first, i)),
        ),
  ];
}

List<CalendarEvent> _inDayOrder(List<CalendarEvent> events, DateTime day) {
  int rank(CalendarEvent e) => coversDay(e, day) ? 0 : 1;
  DateTime startOn(CalendarEvent e) => e.start.isBefore(day) ? day : e.start;
  // Indexed so events that tie keep the order they came in (List.sort is
  // not stable).
  final List<(int, CalendarEvent)> indexed = events.indexed.toList()
    ..sort(((int, CalendarEvent) a, (int, CalendarEvent) b) {
      final int byRank = rank(a.$2).compareTo(rank(b.$2));
      if (byRank != 0) return byRank;
      final int byStart = startOn(a.$2).compareTo(startOn(b.$2));
      if (byStart != 0) return byStart;
      return a.$1.compareTo(b.$1);
    });
  return <CalendarEvent>[for (final (_, CalendarEvent e) in indexed) e];
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

/// The whole of [event], for its own detail view (not one day's share of it,
/// as [formatSpan] gives): `TUE 29 SEP 09:00-10:30`, `SAT 4 OCT 18:00 - SUN
/// 5 OCT 14:00` across midnight, `TUE 29 SEP ALL DAY`, or `SAT 4 OCT - MON 6
/// OCT ALL DAY` for an all-day event of several days (whose own end is the
/// midnight after its last day).
String formatEventRange(CalendarEvent event) {
  if (event.allDay) {
    final DateTime first = startOfDay(event.start);
    final DateTime last = addDays(startOfDay(event.end), -1);
    if (!last.isAfter(first)) return '${formatClockDate(first)} ALL DAY';
    return '${formatClockDate(first)} - ${formatClockDate(last)} ALL DAY';
  }
  final String date = formatClockDate(event.start);
  final String from = formatClockTime(event.start);
  if (event.end == event.start) return '$date $from';
  // Ending exactly at midnight still ends on the day it started, as far as a
  // reader is concerned: `22:00-00:00`, not a second date.
  final bool sameDay =
      startOfDay(event.end) == startOfDay(event.start) ||
      event.end == addDays(startOfDay(event.start), 1);
  if (sameDay) return '$date $from-${formatClockTime(event.end)}';
  return '$date $from - ${formatClockDate(event.end)} '
      '${formatClockTime(event.end)}';
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

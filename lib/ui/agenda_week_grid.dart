import 'dart:async';

import 'package:android_tile_launcher/model/calendar_event.dart';
import 'package:android_tile_launcher/model/clock_format.dart';
import 'package:android_tile_launcher/model/weather_format.dart';
import 'package:android_tile_launcher/services/agenda_repository.dart';
import 'package:android_tile_launcher/ui/event_detail_sheet.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';

/// Keys so tests can find the parts.
const Key agendaGridKey = ValueKey<String>('agenda-grid');
Key agendaGridEventKey(int id) => ValueKey<String>('agenda-grid-event-$id');

/// The week's timed events as a time grid — hours down the side, the seven
/// days across the top, each event a block positioned and sized by its own
/// start and end. Built on `calendar_view`'s [WeekView] for the scroll and
/// layout engine only: every visible part (hour labels, day headers, event
/// blocks) is drawn by this launcher's own flat, hard-edged builders, never
/// the package's own Material look. Its own paging is pinned to exactly
/// [weekStart]'s week — the agenda sheet's PREV/NEXT chevrons drive
/// navigation, not a second, redundant control inside the grid. All-day
/// events have no time to place on a grid, so (as in the week list) they are
/// left out here.
class AgendaWeekGrid extends StatefulWidget {
  const AgendaWeekGrid({
    super.key,
    required this.events,
    required this.weekStart,
    required this.now,
    required this.repository,
    required this.onChanged,
  });

  final List<CalendarEvent> events;

  /// The first day of the week to show — must be a day this launcher's own
  /// rolling week already starts on, so the grid lines up with the
  /// PREV/NEXT chevrons and the heading above it.
  final DateTime weekStart;

  final DateTime now;
  final AgendaRepository repository;

  /// Called after an event is added, edited or deleted from the grid, so the
  /// sheet's own snapshot can be reloaded.
  final VoidCallback onChanged;

  @override
  State<AgendaWeekGrid> createState() => _AgendaWeekGridState();
}

class _AgendaWeekGridState extends State<AgendaWeekGrid> {
  late final EventController<CalendarEvent> _controller =
      EventController<CalendarEvent>();

  @override
  void initState() {
    super.initState();
    _fill();
  }

  @override
  void didUpdateWidget(AgendaWeekGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.events != widget.events) {
      _controller.removeWhere((CalendarEventData<CalendarEvent> e) => true);
      _fill();
    }
  }

  void _fill() {
    _controller.addAll(<CalendarEventData<CalendarEvent>>[
      for (final CalendarEvent event in widget.events)
        if (!event.allDay)
          CalendarEventData<CalendarEvent>(
            title: event.title,
            date: _dateOnly(event.start),
            startTime: event.start,
            endTime: event.end,
            event: event,
          ),
    ]);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openEvent(CalendarEvent event, DateTime day) async {
    final bool changed = await showEventDetailSheet(
      context,
      repository: widget.repository,
      event: event,
      day: day,
    );
    if (changed) widget.onChanged();
  }

  Future<void> _addAt(DateTime moment) async {
    final bool changed = await showEventDetailSheet(
      context,
      repository: widget.repository,
      day: moment,
    );
    if (changed) widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return SizedBox(
      key: agendaGridKey,
      // WeekView measures its own width from the nearest bounded ancestor;
      // it does not stretch to fill a loose one.
      width: double.infinity,
      child: WeekView<CalendarEvent>(
        controller: _controller,
        initialDay: widget.weekStart,
        minDay: widget.weekStart,
        maxDay: widget.weekStart,
        startDay: WeekDays.values[widget.weekStart.weekday - 1],
        scrollOffset: 7 * 60,
        backgroundColor: TileColors.canvas,
        weekTitleBackgroundColor: TileColors.canvas,
        weekTitleHeight: 40,
        showVerticalLines: true,
        hourIndicatorSettings: HourIndicatorSettings(
          color: TileColors.bezel,
          height: TileMetrics.bevel,
        ),
        liveTimeIndicatorSettings: LiveTimeIndicatorSettings(
          color: TileColors.accent,
          height: TileMetrics.bevel,
          showBullet: false,
        ),
        // The sheet's own PREV/NEXT chevrons and heading do this job already.
        weekPageHeaderBuilder: (DateTime start, DateTime end) =>
            const SizedBox.shrink(),
        weekDayBuilder: (DateTime date) =>
            _DayHeader(date: date, now: widget.now, text: text),
        timeLineBuilder: (DateTime time) => _HourLabel(time: time, text: text),
        eventTileBuilder: (
          DateTime date,
          List<CalendarEventData<CalendarEvent>> events,
          Rect boundary,
          DateTime start,
          DateTime end,
        ) => _EventBlock(events: events, text: text),
        onDateTap: (DateTime date) => unawaited(_addAt(date)),
        onEventTap:
            (List<CalendarEventData<CalendarEvent>> events, DateTime date) {
              final CalendarEvent? event = events.firstOrNull?.event;
              if (event != null) unawaited(_openEvent(event, date));
            },
      ),
    );
  }
}

DateTime _dateOnly(DateTime t) => DateTime(t.year, t.month, t.day);

/// One day's column header: weekday and day number, the day number boxed
/// (flat, square) rather than circled when it is [now]'s own day — a bordered
/// badge stands in for the rounded highlight a calendar app would use.
class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.date, required this.now, required this.text});

  final DateTime date;
  final DateTime now;
  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    final bool today =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final Color colour = today ? TileColors.accent : TileColors.textBright;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            weekdayAbbreviation(date),
            style: text.bodySmall?.copyWith(fontSize: 9, color: colour),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: today
                ? BoxDecoration(
                    border: Border.all(
                      color: TileColors.accent,
                      width: TileMetrics.bevel,
                    ),
                  )
                : null,
            child: Text(
              '${date.day}',
              style: text.bodySmall?.copyWith(fontSize: 11, color: colour),
            ),
          ),
        ],
      ),
    );
  }
}

/// One hour's label on the left of the grid.
class _HourLabel extends StatelessWidget {
  const _HourLabel({required this.time, required this.text});

  final DateTime time;
  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Align(
        alignment: Alignment.topRight,
        child: Text(
          formatClockTime(time),
          style: text.bodySmall?.copyWith(fontSize: 8, color: TileColors.muted),
        ),
      ),
    );
  }
}

/// One event's block: flat, bordered, opaque — no gradient or shadow — filled
/// with as much of its title and time span as its own [Positioned] box (set
/// by the package's own event arranger) leaves room for.
class _EventBlock extends StatelessWidget {
  const _EventBlock({required this.events, required this.text});

  final List<CalendarEventData<CalendarEvent>> events;
  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    final CalendarEventData<CalendarEvent>? data = events.firstOrNull;
    if (data == null) return const SizedBox.shrink();
    final DateTime? start = data.startTime;
    final DateTime? end = data.endTime;
    return Container(
      margin: const EdgeInsets.all(1),
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      decoration: BoxDecoration(
        color: TileColors.bezel,
        border: Border.all(color: TileColors.accent, width: TileMetrics.bevel),
      ),
      alignment: Alignment.topLeft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (start != null && end != null)
            Text(
              '${formatClockTime(start)}-${formatClockTime(end)}',
              style: text.bodySmall?.copyWith(
                fontSize: 7,
                color: TileColors.accent,
              ),
              maxLines: 1,
              overflow: TextOverflow.clip,
            ),
          Flexible(
            child: Text(
              data.title.toUpperCase(),
              style: text.bodySmall?.copyWith(
                fontSize: 8,
                color: TileColors.textBright,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

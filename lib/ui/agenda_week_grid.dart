import 'dart:async';

import 'package:android_tile_launcher/model/agenda_format.dart';
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
Key agendaGridAllDayKey(int id, DateTime day) =>
    ValueKey<String>('agenda-grid-all-day-$id-${day.month}-${day.day}');

/// The week's timed events as a time grid — hours down the side, the seven
/// days across the top, each event a block positioned and sized by its own
/// start and end. Built on `calendar_view`'s [WeekView] for the scroll and
/// layout engine only: every visible part (hour labels, day headers, event
/// blocks) is drawn by this launcher's own flat, hard-edged builders, never
/// the package's own Material look. Its own paging is pinned to exactly
/// [weekStart]'s week — the agenda sheet's PREV/NEXT chevrons drive
/// navigation, not a second, redundant control inside the grid. All-day
/// events have no time to place on a grid, so they sit in a row of their own
/// under the day headers, one chip per day they fall on — and so does any day
/// a timed event fills from midnight to midnight (the middle of a three-day
/// trip), the same day the agenda list calls `ALL DAY`. A two-finger pinch
/// anywhere on it zooms: shrinks or grows how tall an hour is drawn, so more
/// or fewer of them fit at once.
class AgendaWeekGrid extends StatefulWidget {
  const AgendaWeekGrid({
    super.key,
    required this.events,
    required this.weekStart,
    required this.now,
    required this.repository,
    required this.onChanged,
    required this.initialHeightPerMinute,
    required this.onHeightPerMinuteChanged,
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

  /// What `heightPerMinute` (see below) starts at: the sheet's own saved
  /// zoom, so stepping to another week (which rebuilds this widget fresh)
  /// keeps whatever the last pinch here left it at.
  final double initialHeightPerMinute;

  /// Called once a pinch ends, with the new `heightPerMinute`, so the sheet
  /// can save it — not on every frame of the gesture, which would be a lot
  /// of writes for something only ever read back at the next rebuild.
  final ValueChanged<double> onHeightPerMinuteChanged;

  @override
  State<AgendaWeekGrid> createState() => _AgendaWeekGridState();
}

class _AgendaWeekGridState extends State<AgendaWeekGrid> {
  late final EventController<CalendarEvent> _controller =
      EventController<CalendarEvent>();

  /// How tall an hour is drawn, as `WeekView`'s own `heightPerMinute` (its
  /// height for one minute; an hour is 60 of them) — `1` is the package's
  /// own default (a 60px hour), [AgendaWeekGrid.initialHeightPerMinute] is
  /// this launcher's own remembered one. Pinch to zoom changes this, clamped
  /// so an hour never shrinks to where its own indicator lines would not
  /// fit, nor grows past showing only a couple of hours at once.
  late double _heightPerMinute = widget.initialHeightPerMinute.clamp(
    _minHeightPerMinute,
    _maxHeightPerMinute,
  );
  static const double _minHeightPerMinute = 0.4;
  static const double _maxHeightPerMinute = 2.5;

  /// Where the grid opens: 07:00, in pixels at the zoom it opens with — the
  /// package's `scrollOffset` is pixels, not minutes, so an unscaled `7 * 60`
  /// opened a zoomed-out grid in the evening and a zoomed-in one at night.
  /// Fixed once: a changed `scrollOffset` makes the package jump to it, which
  /// on every pinch frame would yank the grid back to 07:00.
  late final double _openingScroll = 7 * 60 * _heightPerMinute;

  /// How many all-day chips one day's cell shows before a `+N`.
  static const int _allDayShown = 2;

  /// Two-finger pinch tracking: raw pointers, not `GestureDetector.onScale*`,
  /// which would contend with the grid's own one-finger vertical scroll for
  /// every drag, pinch or not — a `Listener` never claims the gesture arena,
  /// so the grid's own scrolling is untouched.
  final Map<int, Offset> _pointers = <int, Offset>{};
  double? _pinchStartDistance;
  double? _pinchStartHeightPerMinute;

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

  // `calendar_view`'s own `CalendarEventData` expects `startTime`/`endTime`
  // on the same day as `date` — an event that runs past midnight (a ferry
  // booked from Saturday evening to Sunday afternoon, say) needs one entry
  // per day it touches, each clamped to that day's bounds, or the package
  // either drops it from every day but its first or draws a nonsense-sized
  // block from a negative/huge same-day duration. The agenda list already
  // does the equivalent per-day split (`occursOn`/`formatSpan`); this is
  // that same idea for a view that draws a block instead of a line of text.
  //
  // A day the event fills completely goes in the all-day row instead
  // (`startTime`/`endTime` left null): the package counts any 00:00-to-00:00
  // block as "full day" whatever we say, and would otherwise draw it in that
  // row with its own default (Material, coloured) widget. All-day events go
  // there too, one entry per day they fall on, so the row is the launcher's
  // own drawing ([_AllDayCell]) throughout.
  void _fill() {
    _controller.addAll(<CalendarEventData<CalendarEvent>>[
      for (final CalendarEvent event in widget.events)
        for (int i = 0; i < 7; i++)
          ?_entryFor(event, addDays(widget.weekStart, i)),
    ]);
  }

  CalendarEventData<CalendarEvent>? _entryFor(
    CalendarEvent event,
    DateTime day,
  ) {
    if (coversDay(event, day)) {
      return CalendarEventData<CalendarEvent>(
        title: event.title,
        date: day,
        event: event,
      );
    }
    if (event.allDay) return null;
    final ({DateTime start, DateTime end})? span = clampToDay(event, day);
    if (span == null) return null;
    return CalendarEventData<CalendarEvent>(
      title: event.title,
      date: day,
      startTime: span.start,
      endTime: span.end,
      event: event,
    );
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
      // The slot tapped is the start time too, not just the date.
      startAt: moment,
    );
    if (changed) widget.onChanged();
  }

  void _onPointerDown(PointerEvent event) {
    _pointers[event.pointer] = event.position;
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_pointers.containsKey(event.pointer)) return;
    _pointers[event.pointer] = event.position;
    if (_pointers.length != 2) return;
    final List<Offset> positions = _pointers.values.toList();
    final double distance = (positions[0] - positions[1]).distance;
    final double? start = _pinchStartDistance;
    if (start == null) {
      _pinchStartDistance = distance;
      _pinchStartHeightPerMinute = _heightPerMinute;
      return;
    }
    if (start <= 0) return;
    final double next = (_pinchStartHeightPerMinute! * distance / start).clamp(
      _minHeightPerMinute,
      _maxHeightPerMinute,
    );
    if (next != _heightPerMinute) setState(() => _heightPerMinute = next);
  }

  void _onPointerUp(PointerEvent event) {
    _pointers.remove(event.pointer);
    if (_pointers.length < 2) {
      // A pinch was actually in progress (not just a stray second finger):
      // save where it ended.
      if (_pinchStartDistance != null) {
        widget.onHeightPerMinuteChanged(_heightPerMinute);
      }
      _pinchStartDistance = null;
      _pinchStartHeightPerMinute = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerUp,
      child: SizedBox(
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
          scrollOffset: _openingScroll,
          heightPerMinute: _heightPerMinute,
          backgroundColor: TileColors.canvas,
          weekTitleBackgroundColor: TileColors.canvas,
          weekTitleHeight: 40,
          showVerticalLines: true,
          fullDayEventBuilder:
              (List<CalendarEventData<CalendarEvent>> events, DateTime date) =>
                  _AllDayCell(
                    events: events,
                    day: date,
                    shown: _allDayShown,
                    text: text,
                    onTap: (CalendarEvent event) =>
                        unawaited(_openEvent(event, date)),
                  ),
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
          timeLineBuilder: (DateTime time) =>
              _HourLabel(time: time, text: text),
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
      ),
    );
  }
}

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

/// One day's share of the all-day row: a flat chip per event that fills the
/// day (at most [shown], then `+N` for the rest), each opening its event.
class _AllDayCell extends StatelessWidget {
  const _AllDayCell({
    required this.events,
    required this.day,
    required this.shown,
    required this.text,
    required this.onTap,
  });

  final List<CalendarEventData<CalendarEvent>> events;
  final DateTime day;
  final int shown;
  final TextTheme text;
  final ValueChanged<CalendarEvent> onTap;

  @override
  Widget build(BuildContext context) {
    final List<CalendarEvent> all = <CalendarEvent>[
      for (final CalendarEventData<CalendarEvent> e in events) ?e.event,
    ];
    final int hidden = all.length - shown;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final CalendarEvent event in all.take(shown))
            GestureDetector(
              key: agendaGridAllDayKey(event.id, day),
              behavior: HitTestBehavior.opaque,
              onTap: () => onTap(event),
              child: Container(
                margin: const EdgeInsets.all(1),
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                color: TileColors.accent,
                child: Text(
                  event.title.isEmpty ? '?' : event.title.toUpperCase(),
                  style: text.bodySmall?.copyWith(
                    fontSize: 7,
                    color: TileColors.canvas,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  softWrap: false,
                ),
              ),
            ),
          if (hidden > 0)
            // The rest open from the first hidden one; the agenda list has
            // them all.
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTap(all[shown]),
              child: Text(
                '+$hidden',
                textAlign: TextAlign.center,
                style: text.bodySmall?.copyWith(
                  fontSize: 7,
                  color: TileColors.accent,
                ),
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

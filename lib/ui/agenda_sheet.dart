import 'dart:math' as math;

import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/agenda_format.dart';
import 'package:android_tile_launcher/model/agenda_snapshot.dart';
import 'package:android_tile_launcher/model/calendar_choices.dart';
import 'package:android_tile_launcher/model/calendar_event.dart';
import 'package:android_tile_launcher/model/settings.dart';
import 'package:android_tile_launcher/services/agenda_repository.dart';
import 'package:android_tile_launcher/services/calendar_service.dart';
import 'package:android_tile_launcher/ui/agenda_week_grid.dart';
import 'package:android_tile_launcher/ui/calendar_filter_sheet.dart';
import 'package:android_tile_launcher/ui/event_detail_sheet.dart';
import 'package:android_tile_launcher/ui/pad_key.dart';
import 'package:android_tile_launcher/ui/settings_scope.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';

/// Keys so tests can find the parts.
const Key agendaDayToggleKey = ValueKey<String>('agenda-day');
const Key agendaWeekToggleKey = ValueKey<String>('agenda-week');
const Key agendaWeekGridToggleKey = ValueKey<String>('agenda-week-grid');
const Key agendaNavBackKey = ValueKey<String>('agenda-nav-back');
const Key agendaNavForwardKey = ValueKey<String>('agenda-nav-forward');
const Key agendaNavLabelKey = ValueKey<String>('agenda-nav-label');
const Key agendaAddEventKey = ValueKey<String>('agenda-add-event');
const Key agendaTodayKey = ValueKey<String>('agenda-today');
const Key agendaCloseKey = ValueKey<String>('agenda-close');
const Key agendaFilterKey = ValueKey<String>('agenda-filter');

DateTime _systemNow() => DateTime.now();

/// The sheet a tap on a ready agenda tile opens: today, or its own
/// Monday-to-Sunday week (the toggle at the top, remembered as the
/// `agendaWeekView` setting so the sheet reopens on whichever the user
/// looked at last), with chevrons either side of a heading to step a day or
/// a week at a time — the navigated offset itself is not remembered, so the
/// sheet always opens back on today's own day or week. Every event under its
/// day. FILTER, beside the close key, picks which calendars show (in every
/// view, and on the tile); it reads `FILTER 3/5` while some are hidden, so a
/// thin week is never mistaken for an empty calendar. Completes once the
/// sheet is closed, so the tile can read again (an event may have been
/// added, changed or deleted, or a calendar hidden).
Future<void> showAgendaSheet(
  BuildContext context, {
  required AgendaRepository repository,
  DateTime Function() clock = _systemNow,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: TileColors.canvas,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) {
      final MediaQueryData media = MediaQuery.of(sheetContext);
      return SizedBox(
        // As tall as the screen allows, short of the status bar/camera
        // cutout at the top (plus a little breathing room below it), and
        // always that tall: a sheet that shrank to its content jumped in
        // size (showing what is behind it) at every step from one day or
        // week to the next.
        height: math.min(
          media.size.height * 0.92,
          media.size.height - media.padding.top - TileMetrics.margin,
        ),
        child: _AgendaSheet(repository: repository, clock: clock),
      );
    },
  );
}

class _AgendaSheet extends StatefulWidget {
  const _AgendaSheet({required this.repository, required this.clock});

  final AgendaRepository repository;
  final DateTime Function() clock;

  @override
  State<_AgendaSheet> createState() => _AgendaSheetState();
}

/// What the sheet is showing now: the answer for one day or week in one view.
/// Kept apart from what has been asked for, so the page on screen stays until
/// the next one has arrived and can slide in.
class _Page {
  const _Page({
    required this.snapshot,
    required this.start,
    required this.week,
    required this.grid,
    required this.now,
  });

  final AgendaSnapshot snapshot;
  final DateTime start;
  final bool week;
  final bool grid;
  final DateTime now;

  /// The same for the same day/week and view, so a reload in place (an event
  /// was edited) swaps content without a slide.
  Key get key => ValueKey<(DateTime, bool, bool)>((start, week, grid));
}

class _AgendaSheetState extends State<_AgendaSheet> {
  bool _week = false;

  /// Whether the week tab shows as a time grid rather than the list. Only
  /// meaningful while [_week] is true.
  bool _grid = false;
  bool _initialised = false;

  /// Steps of a day (Day view) or a week (Week view) from today; navigated
  /// with the chevrons, reset to `0` whenever the sheet itself
  /// reopens. Not persisted: only which tab was last chosen is.
  ///
  /// Each view (day, agenda, grid) keeps its own, for as long as the sheet is
  /// open, so going to another view and back finds it where it was left.
  final Map<int, int> _offsets = <int, int>{};

  int get _view => !_week ? 0 : (_grid ? 2 : 1);
  int get _offset => _offsets[_view] ?? 0;
  set _offset(int value) => _offsets[_view] = value;

  _Page? _page;

  /// Which way the last step went, for the slide: 1 is forward (the new page
  /// comes in from the right), -1 back, 0 a change of view (a fade).
  int _direction = 0;
  late DateTime _now;

  /// Bumped by every [_load]: a reply that lands after a newer request was
  /// made (stepping weeks faster than the calendar answers) is dropped
  /// rather than shown under the wrong heading.
  int _request = 0;

  /// The phone's calendars and which show, for FILTER's own label; null
  /// until read (or if they could not be).
  List<CalendarInfo>? _calendars;
  CalendarChoices _choices = const CalendarChoices();

  @override
  void initState() {
    super.initState();
    // So `_navLabel` has something to read even before the first `_load`
    // reply lands; `_load` refreshes it with a live reading regardless.
    _now = widget.clock();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialised) {
      _initialised = true;
      final LauncherSettings settings = SettingsScope.of(context);
      _week = settings.agendaWeekView;
      _grid = settings.agendaGridView;
      _load();
      _loadCalendars();
    }
  }

  Future<void> _loadCalendars() async {
    final CalendarListResult list = await widget.repository.calendars();
    final CalendarChoices choices = await widget.repository.calendarChoices();
    if (!mounted) return;
    setState(() {
      _calendars = list is CalendarList ? list.calendars : null;
      _choices = choices;
    });
  }

  Future<void> _filter() async {
    await showCalendarFilterSheet(context, repository: widget.repository);
    if (!mounted) return;
    await Future.wait(<Future<void>>[_load(), _loadCalendars()]);
  }

  String _filterLabel() {
    final List<CalendarInfo>? calendars = _calendars;
    if (calendars == null) return Messages.agendaFilter;
    final int hidden = _choices.hiddenAmong(calendars);
    if (hidden == 0) return Messages.agendaFilter;
    return '${Messages.agendaFilter} ${calendars.length - hidden}'
        '/${calendars.length}';
  }

  bool get _everyCalendarHidden {
    final List<CalendarInfo>? calendars = _calendars;
    return calendars != null &&
        calendars.isNotEmpty &&
        _choices.hiddenAmong(calendars) == calendars.length;
  }

  int get _span => _week ? 7 : 1;

  DateTime _startFor(DateTime now) => _week
      ? addDays(mondayOf(now), _offset * 7)
      : addDays(startOfDay(now), _offset);

  DateTime get _rangeStart => _startFor(_now);

  Future<void> _load() async {
    final int request = ++_request;
    final DateTime now = widget.clock();
    final DateTime start = _startFor(now);
    final AgendaSnapshot snapshot = await widget.repository.between(
      start,
      addDays(start, _span),
    );
    if (!mounted || request != _request) return;
    setState(() {
      _now = now;
      _page = _Page(
        snapshot: snapshot,
        start: start,
        week: _week,
        grid: _grid,
        now: now,
      );
    });
  }

  void _show({required bool week, bool grid = false}) {
    if (week != _week || grid != _grid) {
      SettingsScope.stateOf(context)?.update(
        SettingsScope.of(context)
            .copyWith(agendaWeekView: week, agendaGridView: grid),
      );
    }
    if (week == _week && grid == _grid) return;
    setState(() {
      _week = week;
      _grid = grid;
      _direction = 0;
    });
    _load();
  }

  void _navigate(int delta) {
    setState(() {
      _offset += delta;
      _direction = delta > 0 ? 1 : -1;
    });
    _load();
  }

  void _goToday() {
    if (_offset == 0) return;
    setState(() {
      // Today is back from the future, or forward from the past.
      _direction = _offset > 0 ? -1 : 1;
      _offset = 0;
    });
    _load();
  }

  Future<void> _addEvent() async {
    final bool changed = await showEventDetailSheet(
      context,
      repository: widget.repository,
      day: _rangeStart,
    );
    if (changed) await _load();
  }

  String _navLabel() => _week
      ? formatWeekHeading(_rangeStart, _now)
      : formatDayHeading(_rangeStart, _now);

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final _Page? page = _page;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(TileMetrics.margin),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // So the title is not flush against the sheet's own top edge.
            const SizedBox(height: TileMetrics.gutter),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(Messages.agendaTitle, style: text.bodyMedium),
                ),
                PadKey(
                  key: agendaFilterKey,
                  label: _filterLabel(),
                  height: 32,
                  fontSize: 11,
                  accent:
                      _calendars != null &&
                      _choices.hiddenAmong(_calendars!) > 0,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  onTap: _filter,
                ),
                const SizedBox(width: TileMetrics.gutter),
                SizedBox(
                  width: 48,
                  child: PadKey(
                    key: agendaCloseKey,
                    label: 'X',
                    height: 32,
                    fontSize: 12,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: TileMetrics.gutter),
            // Its own row, under the title's (three toggles beside it would
            // not fit a narrow phone), split into equal thirds so DAY,
            // AGENDA and GRID always spread evenly across whatever width the
            // sheet has, rather than clustering to one side of it.
            Row(
              children: <Widget>[
                for (final Widget toggle in <Widget>[
                  _Toggle(
                    key: agendaDayToggleKey,
                    label: Messages.agendaDay,
                    selected: !_week,
                    onTap: () => _show(week: false),
                  ),
                  _Toggle(
                    key: agendaWeekToggleKey,
                    label: Messages.agendaWeek,
                    selected: _week && !_grid,
                    onTap: () => _show(week: true),
                  ),
                  _Toggle(
                    key: agendaWeekGridToggleKey,
                    label: Messages.agendaWeekGrid,
                    selected: _week && _grid,
                    onTap: () => _show(week: true, grid: true),
                  ),
                ])
                  Expanded(
                    child: Center(
                      child: FittedBox(fit: BoxFit.scaleDown, child: toggle),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: TileMetrics.gutter),
            Row(
              children: <Widget>[
                SizedBox(
                  width: 36,
                  child: PadKey(
                    key: agendaNavBackKey,
                    label: '<',
                    height: 28,
                    fontSize: 11,
                    onTap: () => _navigate(-1),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      _navLabel(),
                      key: agendaNavLabelKey,
                      style: text.bodySmall?.copyWith(
                        fontSize: 10,
                        color: TileColors.textBright,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 36,
                  child: PadKey(
                    key: agendaNavForwardKey,
                    label: '>',
                    height: 28,
                    fontSize: 11,
                    onTap: () => _navigate(1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: TileMetrics.gutter),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                _AddEventButton(key: agendaAddEventKey, onTap: _addEvent),
                PadKey(
                  key: agendaTodayKey,
                  label: Messages.agendaToday,
                  height: 28,
                  fontSize: 11,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  onTap: _offset == 0 ? null : _goToday,
                ),
              ],
            ),
            const SizedBox(height: TileMetrics.margin),
            Expanded(
              child: page == null
                  ? const SizedBox.shrink()
                  : _SwipeNavigator(
                      onSwipe: _navigate,
                      child: ClipRect(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 240),
                          layoutBuilder: (Widget? current, List<Widget> old) =>
                              Stack(
                                fit: StackFit.expand,
                                alignment: Alignment.topLeft,
                                children: <Widget>[...old, ?current],
                              ),
                          transitionBuilder: (
                            Widget child,
                            Animation<double> animation,
                          ) => _transition(child, animation, page.key),
                          child: KeyedSubtree(
                            key: page.key,
                            child: _body(page, text),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// The page coming in slides from the side the step went towards while the
  /// one leaving slides out the other way; a change of view just fades.
  Widget _transition(Widget child, Animation<double> animation, Key current) {
    final int direction = _direction;
    if (direction == 0) {
      return FadeTransition(opacity: animation, child: child);
    }
    final bool incoming = child.key == current;
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset((incoming ? direction : -direction).toDouble(), 0),
        end: Offset.zero,
      ).animate(animation),
      child: child,
    );
  }

  Widget _body(_Page page, TextTheme text) {
    final bool week = page.week;
    final bool grid = page.grid;
    final DateTime start = page.start;
    final DateTime now = page.now;
    switch (page.snapshot) {
      case AgendaReady(:final List<CalendarEvent> events):
        if (week && grid) {
          return AgendaWeekGrid(
            events: events,
            weekStart: start,
            now: now,
            repository: widget.repository,
            onChanged: _load,
            initialHeightPerMinute: SettingsScope.of(context).agendaGridZoom,
            onHeightPerMinuteChanged: (double value) =>
                SettingsScope.stateOf(context)?.update(
                  SettingsScope.of(context).copyWith(agendaGridZoom: value),
                ),
          );
        }
        final List<AgendaDay> days = groupByDay(
          events,
          from: start,
          days: week ? 7 : 1,
        );
        if (days.isEmpty) {
          return Text(
            _everyCalendarHidden
                ? Messages.agendaCalendarsAllHidden
                : !week && start == startOfDay(now)
                ? Messages.agendaNothingToday
                : Messages.agendaNothingPlanned,
            style: text.bodyMedium,
          );
        }
        return ListView(
          shrinkWrap: true,
          children: <Widget>[
            for (final AgendaDay day in days) ...<Widget>[
              // The day view is one day, so its heading adds nothing.
              if (week)
                Padding(
                  padding: const EdgeInsets.only(top: TileMetrics.margin),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        formatDayHeading(day.day, now),
                        style: text.bodyMedium?.copyWith(
                          color: TileColors.textBright,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // A rule under the heading, so each day reads as a block.
                      Container(height: 2, color: TileColors.bezel),
                    ],
                  ),
                ),
              for (final CalendarEvent event in day.events)
                _EventRow(
                  event: event,
                  day: day.day,
                  repository: widget.repository,
                  onChanged: _load,
                ),
            ],
          ],
        );
      case AgendaNeedsPermission():
      case AgendaDenied():
        return Text(Messages.agendaTapToAllow, style: text.bodyMedium);
      case AgendaUnavailable(:final String reason):
        return Text(reason.toUpperCase(), style: text.bodyMedium);
    }
  }
}

/// A small bordered text button, the same look the mail and event sheets'
/// own buttons use, rather than home's full-width bevelled key.
class _AddEventButton extends StatelessWidget {
  const _AddEventButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(
            color: TileColors.textBright,
            width: TileMetrics.bevel,
          ),
        ),
        child: Text(
          Messages.agendaAddEvent,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(fontSize: 11, color: TileColors.textBright),
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Text(
          selected ? '[$label]' : ' $label ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: selected ? TileColors.textBright : TileColors.muted,
          ),
        ),
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({
    required this.event,
    required this.day,
    required this.repository,
    required this.onChanged,
  });

  final CalendarEvent event;
  final DateTime day;
  final AgendaRepository repository;

  /// Reloads the sheet's own list once the detail sheet reports a change
  /// (an edit or a delete).
  final VoidCallback onChanged;

  Future<void> _open(BuildContext context) async {
    final bool changed = await showEventDetailSheet(
      context,
      repository: repository,
      event: event,
      day: day,
    );
    if (changed) onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final String? location = event.location;
    // The hours sit above the title, not beside it: a span like
    // `12:43-13:13` is too wide for a side column on a narrow phone.
    return InkWell(
      onTap: () => _open(context),
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              formatSpan(event, day),
              style: text.bodySmall?.copyWith(
                fontSize: 10,
                color: TileColors.accent,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              event.title.isEmpty
                  ? Messages.agendaUntitled
                  : event.title.toUpperCase(),
              style: text.bodySmall?.copyWith(
                fontSize: 10,
                color: TileColors.textBright,
              ),
            ),
            if (location != null)
              Text(
                location.toUpperCase(),
                style: text.bodySmall?.copyWith(
                  fontSize: 8,
                  color: TileColors.muted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Turns a quick sideways swipe anywhere over [child] into [onSwipe] (1 for
/// a swipe left, which goes forward; -1 for a swipe right), the same as the
/// chevrons. Watches raw pointers rather than joining the gesture arena, so
/// it works over a list, a scrolling grid and a pinch-to-zoom alike, and
/// ignores anything with a second finger on it (a pinch).
class _SwipeNavigator extends StatefulWidget {
  const _SwipeNavigator({required this.onSwipe, required this.child});

  final void Function(int direction) onSwipe;
  final Widget child;

  @override
  State<_SwipeNavigator> createState() => _SwipeNavigatorState();
}

class _SwipeNavigatorState extends State<_SwipeNavigator> {
  static const double _minDistance = 72;
  static const Duration _maxTime = Duration(milliseconds: 700);

  final Set<int> _down = <int>{};
  Offset? _from;
  DateTime? _at;
  bool _pinched = false;

  void _onDown(PointerDownEvent event) {
    if (_down.isEmpty) {
      _from = event.position;
      _at = DateTime.now();
      _pinched = false;
    } else {
      _pinched = true;
    }
    _down.add(event.pointer);
  }

  void _onUp(PointerUpEvent event) {
    final bool last = _down.length == 1 && _down.contains(event.pointer);
    _down.remove(event.pointer);
    final Offset? from = _from;
    final DateTime? at = _at;
    if (!last || _pinched || from == null || at == null) return;
    final Offset moved = event.position - from;
    final bool quick = DateTime.now().difference(at) <= _maxTime;
    if (quick &&
        moved.dx.abs() >= _minDistance &&
        moved.dx.abs() > moved.dy.abs() * 2) {
      widget.onSwipe(moved.dx < 0 ? 1 : -1);
    }
  }

  void _onCancel(PointerCancelEvent event) {
    _down.remove(event.pointer);
    if (_down.isEmpty) _pinched = false;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onDown,
      onPointerUp: _onUp,
      onPointerCancel: _onCancel,
      child: widget.child,
    );
  }
}

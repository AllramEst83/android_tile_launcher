import 'dart:math' as math;

import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/agenda_format.dart';
import 'package:android_tile_launcher/model/agenda_snapshot.dart';
import 'package:android_tile_launcher/model/calendar_event.dart';
import 'package:android_tile_launcher/model/settings.dart';
import 'package:android_tile_launcher/services/agenda_repository.dart';
import 'package:android_tile_launcher/ui/agenda_week_grid.dart';
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

DateTime _systemNow() => DateTime.now();

/// The sheet a tap on a ready agenda tile opens: today, or its own
/// Monday-to-Sunday week (the toggle at the top, remembered as the
/// `agendaWeekView` setting so the sheet reopens on whichever the user
/// looked at last), with chevrons either side of a heading to step a day or
/// a week at a time — the navigated offset itself is not remembered, so the
/// sheet always opens back on today's own day or week. Every event under its
/// day.
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
      return ConstrainedBox(
        constraints: BoxConstraints(
          // As tall as the screen allows, short of the status bar/camera
          // cutout at the top (plus a little breathing room below it) —
          // a week with many events should not be capped well short of
          // that just because a day view rarely needs the room.
          maxHeight: math.min(
            media.size.height * 0.92,
            media.size.height - media.padding.top - TileMetrics.margin,
          ),
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

class _AgendaSheetState extends State<_AgendaSheet> {
  bool _week = false;

  /// Whether the week tab shows as a time grid rather than the list. Only
  /// meaningful while [_week] is true.
  bool _grid = false;
  bool _initialised = false;

  /// Steps of a day (Day view) or a week (Week view) from today; navigated
  /// with the chevrons, reset to `0` whenever the view or the sheet itself
  /// reopens. Not persisted: only which tab was last chosen is.
  int _offset = 0;

  AgendaSnapshot? _snapshot;
  late DateTime _now;

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
    }
  }

  int get _span => _week ? 7 : 1;

  DateTime _startFor(DateTime now) => _week
      ? addDays(mondayOf(now), _offset * 7)
      : addDays(startOfDay(now), _offset);

  DateTime get _rangeStart => _startFor(_now);

  Future<void> _load() async {
    final DateTime now = widget.clock();
    final DateTime start = _startFor(now);
    final AgendaSnapshot snapshot = await widget.repository.between(
      start,
      addDays(start, _span),
    );
    if (!mounted) return;
    setState(() {
      _now = now;
      _snapshot = snapshot;
    });
  }

  void _show({required bool week, bool grid = false}) {
    if (week != _week || grid != _grid) {
      SettingsScope.stateOf(context)?.update(
        SettingsScope.of(context)
            .copyWith(agendaWeekView: week, agendaGridView: grid),
      );
    }
    if (week == _week && grid == _grid && _offset == 0) return;
    setState(() {
      _week = week;
      _grid = grid;
      _offset = 0;
      _snapshot = null;
    });
    _load();
  }

  void _navigate(int delta) {
    setState(() {
      _offset += delta;
      _snapshot = null;
    });
    _load();
  }

  void _goToday() {
    if (_offset == 0) return;
    setState(() {
      _offset = 0;
      _snapshot = null;
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
    final AgendaSnapshot? snapshot = _snapshot;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(TileMetrics.margin),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // So the title is not flush against the sheet's own top edge.
            const SizedBox(height: TileMetrics.gutter),
            Text(Messages.agendaTitle, style: text.bodyMedium),
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
            if (snapshot == null)
              const SizedBox.shrink()
            else if (_week && _grid)
              // The grid wants to fill whatever room is left, not just what
              // its own content needs (unlike the shrink-to-fit list below).
              Expanded(child: _body(snapshot, text))
            else
              Flexible(child: _body(snapshot, text)),
          ],
        ),
      ),
    );
  }

  Widget _body(AgendaSnapshot snapshot, TextTheme text) {
    switch (snapshot) {
      case AgendaReady(:final List<CalendarEvent> events):
        if (_week && _grid) {
          return AgendaWeekGrid(
            events: events,
            weekStart: _rangeStart,
            now: _now,
            repository: widget.repository,
            onChanged: _load,
          );
        }
        final DateTime start = _rangeStart;
        final List<AgendaDay> days = groupByDay(
          events,
          from: start,
          days: _span,
        );
        if (days.isEmpty) {
          return Text(
            !_week && _offset == 0
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
              if (_week)
                Padding(
                  padding: const EdgeInsets.only(top: TileMetrics.margin),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        formatDayHeading(day.day, _now),
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

import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/agenda_format.dart';
import 'package:android_tile_launcher/model/agenda_snapshot.dart';
import 'package:android_tile_launcher/model/calendar_event.dart';
import 'package:android_tile_launcher/services/agenda_repository.dart';
import 'package:android_tile_launcher/ui/event_detail_sheet.dart';
import 'package:android_tile_launcher/ui/pad_key.dart';
import 'package:android_tile_launcher/ui/settings_scope.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';

/// Keys so tests can find the parts.
const Key agendaDayToggleKey = ValueKey<String>('agenda-day');
const Key agendaWeekToggleKey = ValueKey<String>('agenda-week');
const Key agendaNavBackKey = ValueKey<String>('agenda-nav-back');
const Key agendaNavForwardKey = ValueKey<String>('agenda-nav-forward');
const Key agendaNavLabelKey = ValueKey<String>('agenda-nav-label');

DateTime _systemNow() => DateTime.now();

/// The sheet a tap on a ready agenda tile opens: today, or the next seven days
/// (the toggle at the top, remembered as the `agendaWeekView` setting so the
/// sheet reopens on whichever the user looked at last), with chevrons either
/// side of a heading to step a day or a week at a time — the navigated offset
/// itself is not remembered, so the sheet always opens back on today's own
/// day or week. Every event under its day.
Future<void> showAgendaSheet(
  BuildContext context, {
  required AgendaRepository repository,
  DateTime Function() clock = _systemNow,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: TileColors.canvas,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) => ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.75,
      ),
      child: _AgendaSheet(repository: repository, clock: clock),
    ),
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
      _week = SettingsScope.of(context).agendaWeekView;
      _load();
    }
  }

  int get _span => _week ? 7 : 1;

  DateTime get _rangeStart => addDays(startOfDay(_now), _offset * _span);

  Future<void> _load() async {
    final DateTime now = widget.clock();
    final DateTime start = addDays(startOfDay(now), _offset * _span);
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

  void _show({required bool week}) {
    if (week != _week) {
      SettingsScope.stateOf(context)
          ?.update(SettingsScope.of(context).copyWith(agendaWeekView: week));
    }
    if (week == _week && _offset == 0) return;
    setState(() {
      _week = week;
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
            // So the DAY/WEEK toggle is not flush against the sheet's own
            // top edge.
            const SizedBox(height: TileMetrics.gutter),
            Row(
              children: <Widget>[
                Text(Messages.agendaTitle, style: text.bodyMedium),
                const Spacer(),
                _Toggle(
                  key: agendaDayToggleKey,
                  label: Messages.agendaDay,
                  selected: !_week,
                  onTap: () => _show(week: false),
                ),
                const SizedBox(width: TileMetrics.gutter),
                _Toggle(
                  key: agendaWeekToggleKey,
                  label: Messages.agendaWeek,
                  selected: _week,
                  onTap: () => _show(week: true),
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
            const SizedBox(height: TileMetrics.margin),
            if (snapshot == null)
              const SizedBox.shrink()
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
                _EventRow(event: event, day: day.day),
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
  const _EventRow({required this.event, required this.day});

  final CalendarEvent event;
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final String? location = event.location;
    // The hours sit above the title, not beside it: a span like
    // `12:43-13:13` is too wide for a side column on a narrow phone.
    return InkWell(
      onTap: () => showEventDetailSheet(context, event: event, day: day),
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

import 'dart:math' as math;

import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/calendar_choices.dart';
import 'package:android_tile_launcher/model/calendar_event.dart';
import 'package:android_tile_launcher/services/agenda_repository.dart';
import 'package:android_tile_launcher/services/calendar_service.dart';
import 'package:android_tile_launcher/ui/pad_key.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';

/// Keys so tests can find the parts.
const Key calendarFilterCloseKey = ValueKey<String>('calendar-filter-close');
Key calendarFilterRowKey(int id) => ValueKey<String>('calendar-filter-$id');

/// Every calendar on the phone, grouped under its account, each with a
/// `[X]`/`[ ]` switch for whether the agenda (tile, day, week and grid alike)
/// shows it. A tap switches it at once; nothing to save, so whoever opened
/// it reloads once it closes, however it was closed.
Future<void> showCalendarFilterSheet(
  BuildContext context, {
  required AgendaRepository repository,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: TileColors.canvas,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext sheetContext) => ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: math.max(240, MediaQuery.sizeOf(sheetContext).height * 0.8),
      ),
      child: _CalendarFilterSheet(repository: repository),
    ),
  );
}

class _CalendarFilterSheet extends StatefulWidget {
  const _CalendarFilterSheet({required this.repository});

  final AgendaRepository repository;

  @override
  State<_CalendarFilterSheet> createState() => _CalendarFilterSheetState();
}

class _CalendarFilterSheetState extends State<_CalendarFilterSheet> {
  CalendarListResult? _list;
  CalendarChoices _choices = const CalendarChoices();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final CalendarListResult list = await widget.repository.calendars();
    final CalendarChoices choices = await widget.repository.calendarChoices();
    if (!mounted) return;
    setState(() {
      _list = list;
      _choices = choices;
    });
  }

  Future<void> _toggle(CalendarInfo calendar) async {
    final bool shown = !_choices.shows(calendar);
    setState(() {
      _choices = _choices.withShown(calendar.id, shown: shown);
    });
    await widget.repository.setCalendarShown(calendar.id, shown: shown);
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(TileMetrics.margin),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  Messages.agendaCalendarsTitle,
                  style: text.bodyMedium?.copyWith(
                    color: TileColors.textBright,
                  ),
                ),
              ),
              SizedBox(
                width: 48,
                child: PadKey(
                  key: calendarFilterCloseKey,
                  label: 'X',
                  height: 32,
                  fontSize: 12,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(height: 2, color: TileColors.bezel),
          const SizedBox(height: TileMetrics.gutter),
          Flexible(child: _body(text)),
        ],
      ),
    );
  }

  Widget _body(TextTheme text) {
    final TextStyle? message = text.bodySmall?.copyWith(
      fontSize: 11,
      color: TileColors.textBright,
    );
    switch (_list) {
      case null:
        return Text(Messages.agendaEventLoadingCalendars, style: message);
      case CalendarListDenied():
        return Text(Messages.agendaTapToAllow, style: message);
      case CalendarListUnavailable(:final String reason):
        return Text(reason.toUpperCase(), style: message);
      case CalendarList(:final List<CalendarInfo> calendars)
          when calendars.isEmpty:
        return Text(Messages.agendaCalendarsNone, style: message);
      case CalendarList(:final List<CalendarInfo> calendars):
        // Kotlin already sorts by account; grouping keeps that order.
        final Map<String, List<CalendarInfo>> byAccount =
            <String, List<CalendarInfo>>{};
        for (final CalendarInfo c in calendars) {
          (byAccount[c.account ?? ''] ??= <CalendarInfo>[]).add(c);
        }
        return ListView(
          shrinkWrap: true,
          children: <Widget>[
            for (final MapEntry<String, List<CalendarInfo>> group
                in byAccount.entries) ...<Widget>[
              if (group.key.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(
                    top: TileMetrics.gutter,
                    bottom: 2,
                  ),
                  child: Text(
                    group.key.toUpperCase(),
                    style: text.bodySmall?.copyWith(
                      fontSize: 8,
                      color: TileColors.muted,
                    ),
                  ),
                ),
              for (final CalendarInfo c in group.value) _row(c, text),
            ],
          ],
        );
    }
  }

  Widget _row(CalendarInfo calendar, TextTheme text) {
    final bool shown = _choices.shows(calendar);
    final Color colour = shown ? TileColors.textBright : TileColors.muted;
    return InkWell(
      key: calendarFilterRowKey(calendar.id),
      onTap: () => _toggle(calendar),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: <Widget>[
            Text(
              shown ? '[X]' : '[ ]',
              style: text.bodySmall?.copyWith(
                fontSize: 12,
                color: shown ? TileColors.accent : TileColors.muted,
              ),
            ),
            const SizedBox(width: TileMetrics.gutter),
            Expanded(
              child: Text(
                calendar.name.toUpperCase(),
                style: text.bodySmall?.copyWith(fontSize: 12, color: colour),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!calendar.writable)
              Text(
                Messages.agendaCalendarsReadOnly,
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

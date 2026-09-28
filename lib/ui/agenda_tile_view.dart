import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/agenda_format.dart';
import 'package:android_tile_launcher/model/agenda_snapshot.dart';
import 'package:android_tile_launcher/model/calendar_event.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';

/// Keys so tests can find the parts.
const Key agendaNextKey = ValueKey<String>('agenda-next');
Key agendaRowKey(int index) => ValueKey<String>('agenda-row-$index');

/// The agenda tile's content, fitted to whatever size the tile was given: a
/// small tile shows when the next event is and what it is; a medium one adds
/// the place and how many more follow; a wide (or larger) one lists as many
/// coming events as fit. With no events to show it says why, and a tap
/// ([onTap]) is how the user fixes it (allows the calendar), retries, or opens
/// the day and week. `null` in the grid editor, where a tap selects the tile.
class AgendaTileContentView extends StatelessWidget {
  const AgendaTileContentView({
    super.key,
    required this.snapshot,
    required this.now,
    required this.ink,
    this.onTap,
  });

  final AgendaSnapshot snapshot;
  final DateTime now;
  final Color ink;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget body = SizedBox.expand(
      child: Padding(
        padding: const EdgeInsets.all(TileMetrics.gutter / 2),
        child: LayoutBuilder(
          builder: (context, constraints) => switch (snapshot) {
            AgendaReady(:final List<CalendarEvent> events)
                when events.isNotEmpty =>
              _EventsView(
                events: events,
                now: now,
                ink: ink,
                width: constraints.maxWidth,
                height: constraints.maxHeight,
              ),
            _ => _MessageView(lines: _messageFor(snapshot), ink: ink),
          },
        ),
      ),
    );
    final VoidCallback? tap = onTap;
    if (tap == null) return body;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: tap,
      child: body,
    );
  }
}

List<String> _messageFor(AgendaSnapshot snapshot) => switch (snapshot) {
  AgendaReady() => const <String>[Messages.agendaNothingPlanned],
  AgendaNeedsPermission() => const <String>[Messages.agendaTapToAllow],
  AgendaDenied(permanent: true) => const <String>[
    Messages.agendaAllowInSettings,
  ],
  AgendaDenied() => const <String>[Messages.agendaTapToAllow],
  AgendaUnavailable(:final String reason) => <String>[
    reason.toUpperCase(),
    Messages.agendaTapToRetry,
  ],
};

TextStyle _text(Color ink, double size) =>
    TextStyle(fontFamily: kPixelFontFamily, fontSize: size, color: ink);

String _titleOf(CalendarEvent event) =>
    event.title.isEmpty ? Messages.agendaUntitled : event.title.toUpperCase();

class _MessageView extends StatelessWidget {
  const _MessageView({required this.lines, required this.ink});

  final List<String> lines;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(Messages.agendaTitle, style: _text(ink, 10)),
        const SizedBox(height: 6),
        for (final String line in lines)
          Text(line, style: _text(ink, 8), softWrap: true),
      ],
    );
  }
}

class _EventsView extends StatelessWidget {
  const _EventsView({
    required this.events,
    required this.now,
    required this.ink,
    required this.width,
    required this.height,
  });

  final List<CalendarEvent> events;
  final DateTime now;
  final Color ink;
  final double width;
  final double height;

  static const double _compact = 120;
  static const double _wide = 260;
  static const double _rowHeight = 16;
  static const double _headerHeight = 22;

  @override
  Widget build(BuildContext context) {
    if (width >= _wide) return _list();
    final CalendarEvent next = nextEvent(events)!;
    final int more = events.length - 1;
    final Widget when = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(formatWhen(next, now), style: _text(ink, 14)),
    );
    if (width < _compact) {
      return Column(
        key: agendaNextKey,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          when,
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              _titleOf(next),
              style: _text(ink, 8),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }
    return Column(
      key: agendaNextKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(Messages.agendaTitle, style: _text(ink, 8)),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(formatWhen(next, now), style: _text(ink, 20)),
        ),
        const SizedBox(height: 6),
        Flexible(
          child: Text(
            _titleOf(next),
            style: _text(ink, 10),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (next.location != null)
          Text(
            next.location!.toUpperCase(),
            style: _text(ink, 8),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        if (more > 0) ...<Widget>[
          const SizedBox(height: 6),
          Text('+$more MORE', style: _text(ink, 8)),
        ],
      ],
    );
  }

  /// As many upcoming events as the height allows, one line each, time first.
  Widget _list() {
    final int fit = ((height - _headerHeight) / _rowHeight).floor().clamp(
      1,
      events.length,
    );
    final int hidden = events.length - fit;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          height: _headerHeight,
          child: Row(
            children: <Widget>[
              Text(Messages.agendaTitle, style: _text(ink, 10)),
              const Spacer(),
              if (hidden > 0) Text('+$hidden', style: _text(ink, 8)),
            ],
          ),
        ),
        for (final (int i, CalendarEvent event) in events.take(fit).indexed)
          SizedBox(
            key: agendaRowKey(i),
            height: _rowHeight,
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 96,
                  child: Text(
                    formatWhen(event, now),
                    style: _text(ink, 8),
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                  ),
                ),
                Expanded(
                  child: Text(
                    _titleOf(event),
                    style: _text(ink, 8),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

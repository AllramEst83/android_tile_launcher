import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/agenda_format.dart';
import 'package:android_tile_launcher/model/calendar_event.dart';
import 'package:android_tile_launcher/model/clock_format.dart';
import 'package:android_tile_launcher/ui/pad_key.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';

/// Keys so tests can find the parts.
const Key eventDetailCloseKey = ValueKey<String>('event-detail-close');
const Key eventDetailWhenKey = ValueKey<String>('event-detail-when');
const Key eventDetailWhereKey = ValueKey<String>('event-detail-where');
const Key eventDetailAboutKey = ValueKey<String>('event-detail-about');

/// What a tap on an agenda event opens: everything it holds, read-only, one
/// labelled field per property — not the agenda list's one-line summary of
/// it. Laid out as boxed fields rather than plain text so a later phase can
/// turn this into an edit form (a field's box becoming a `TextField`'s own
/// border) without a rewrite; create, update and delete are not built yet,
/// only this read.
Future<void> showEventDetailSheet(
  BuildContext context, {
  required CalendarEvent event,
  required DateTime day,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: TileColors.canvas,
    isScrollControlled: true,
    // Laid out below the status bar, like the sheet it opens from.
    useSafeArea: true,
    builder: (BuildContext sheetContext) =>
        _EventDetailSheet(event: event, day: day),
  );
}

class _EventDetailSheet extends StatelessWidget {
  const _EventDetailSheet({required this.event, required this.day});

  final CalendarEvent event;
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final String? location = event.location;
    final String? description = event.description;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(TileMetrics.margin),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      Messages.agendaEventTitle,
                      style: text.bodyMedium?.copyWith(
                        color: TileColors.textBright,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 48,
                    child: PadKey(
                      key: eventDetailCloseKey,
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
              const SizedBox(height: TileMetrics.margin),
              Text(
                event.title.isEmpty
                    ? Messages.agendaUntitled
                    : event.title.toUpperCase(),
                style: text.bodyMedium?.copyWith(
                  color: TileColors.textBright,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: TileMetrics.margin),
              _Field(
                fieldKey: eventDetailWhenKey,
                label: Messages.agendaEventWhen,
                value: '${formatClockDate(day)} ${formatSpan(event, day)}',
              ),
              if (location != null) ...<Widget>[
                const SizedBox(height: TileMetrics.gutter),
                _Field(
                  fieldKey: eventDetailWhereKey,
                  label: Messages.agendaEventWhere,
                  value: location.toUpperCase(),
                ),
              ],
              const SizedBox(height: TileMetrics.gutter),
              _Field(
                fieldKey: eventDetailAboutKey,
                label: Messages.agendaEventAbout,
                value: description == null
                    ? Messages.agendaEventNoDescription
                    : description.toUpperCase(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One read-only property of the event, a bordered box under a small muted
/// label — the same shape a `TextField` would take over in a future edit
/// mode.
class _Field extends StatelessWidget {
  const _Field({
    required this.fieldKey,
    required this.label,
    required this.value,
  });

  final Key fieldKey;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      key: fieldKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: text.bodySmall?.copyWith(fontSize: 9, color: TileColors.muted),
        ),
        const SizedBox(height: 2),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: TileColors.bezel,
              width: TileMetrics.bevel,
            ),
          ),
          child: Text(
            value,
            style: text.bodySmall?.copyWith(
              fontSize: 11,
              color: TileColors.textBright,
            ),
          ),
        ),
      ],
    );
  }
}

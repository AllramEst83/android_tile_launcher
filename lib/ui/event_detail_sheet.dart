import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/agenda_format.dart';
import 'package:android_tile_launcher/model/calendar_event.dart';
import 'package:android_tile_launcher/model/clock_format.dart';
import 'package:android_tile_launcher/model/event_form.dart';
import 'package:android_tile_launcher/services/agenda_repository.dart';
import 'package:android_tile_launcher/services/calendar_service.dart';
import 'package:android_tile_launcher/ui/pad_key.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';

/// Keys so tests can find the parts.
const Key eventDetailCloseKey = ValueKey<String>('event-detail-close');
const Key eventDetailWhenKey = ValueKey<String>('event-detail-when');
const Key eventDetailWhereKey = ValueKey<String>('event-detail-where');
const Key eventDetailAboutKey = ValueKey<String>('event-detail-about');
const Key eventDetailEditKey = ValueKey<String>('event-detail-edit');
const Key eventDetailDeleteKey = ValueKey<String>('event-detail-delete');
const Key eventDetailDeleteYesKey = ValueKey<String>('event-detail-delete-yes');
const Key eventDetailDeleteNoKey = ValueKey<String>('event-detail-delete-no');
const Key eventDetailSaveKey = ValueKey<String>('event-detail-save');
const Key eventDetailTitleFieldKey = ValueKey<String>('event-detail-title');
const Key eventDetailLocationFieldKey = ValueKey<String>(
  'event-detail-location',
);
const Key eventDetailDescriptionFieldKey = ValueKey<String>(
  'event-detail-description',
);
const Key eventDetailDateFieldKey = ValueKey<String>('event-detail-date');
const Key eventDetailStartFieldKey = ValueKey<String>('event-detail-start');
const Key eventDetailEndFieldKey = ValueKey<String>('event-detail-end');

/// What a tap on an agenda event opens (everything it holds, one labelled
/// field per property), or what `+ ADD EVENT` opens directly into edit mode.
/// EDIT turns the read fields into an edit form (title, location, about,
/// date, start and end — timed events only: an all-day event can be deleted
/// here but not edited); SAVE writes it back and DELETE asks first. Adding
/// files the event under the account's primary calendar (or the first one
/// Android will accept an insert for); editing never changes which calendar
/// an event is on. Completes with whether anything actually changed, so the
/// agenda sheet knows to reload.
Future<bool> showEventDetailSheet(
  BuildContext context, {
  required AgendaRepository repository,
  CalendarEvent? event,
  required DateTime day,
}) async {
  final bool? changed = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: TileColors.canvas,
    isScrollControlled: true,
    // Laid out below the status bar, like the sheet it opens from.
    useSafeArea: true,
    builder: (BuildContext sheetContext) =>
        _EventDetailSheet(repository: repository, event: event, day: day),
  );
  return changed ?? false;
}

class _EventDetailSheet extends StatefulWidget {
  const _EventDetailSheet({
    required this.repository,
    required this.event,
    required this.day,
  });

  final AgendaRepository repository;

  /// Null when this is `+ ADD EVENT`: there is nothing to show yet, so the
  /// sheet opens straight into the edit form.
  final CalendarEvent? event;
  final DateTime day;

  @override
  State<_EventDetailSheet> createState() => _EventDetailSheetState();
}

class _EventDetailSheetState extends State<_EventDetailSheet> {
  late bool _editing = widget.event == null;
  late final TextEditingController _title = TextEditingController(
    text: widget.event?.title ?? '',
  );
  late final TextEditingController _location = TextEditingController(
    text: widget.event?.location ?? '',
  );
  late final TextEditingController _description = TextEditingController(
    text: widget.event?.description ?? '',
  );
  late final TextEditingController _date = TextEditingController(
    text: formatEventDate(widget.event?.start ?? widget.day),
  );
  late final TextEditingController _start = TextEditingController(
    text: widget.event == null ? '' : formatEventTime(widget.event!.start),
  );
  late final TextEditingController _end = TextEditingController(
    text: widget.event == null ? '' : formatEventTime(widget.event!.end),
  );

  bool _busy = false;
  bool _confirmingDelete = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _description.dispose();
    _date.dispose();
    _start.dispose();
    _end.dispose();
    super.dispose();
  }

  void _startEditing() => setState(() {
    _editing = true;
    _error = null;
  });

  void _close() {
    final CalendarEvent? event = widget.event;
    if (event == null || !_editing) {
      Navigator.of(context).pop(false);
      return;
    }
    // Back out of editing an existing event to its read view, discarding
    // whatever was typed.
    setState(() {
      _editing = false;
      _error = null;
      _title.text = event.title;
      _location.text = event.location ?? '';
      _description.text = event.description ?? '';
      _date.text = formatEventDate(event.start);
      _start.text = formatEventTime(event.start);
      _end.text = formatEventTime(event.end);
    });
  }

  ({DateTime start, DateTime end})? _validated() {
    final String title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _error = Messages.agendaEventTitleNeeded);
      return null;
    }
    final DateTime? date = parseEventDate(_date.text);
    if (date == null) {
      setState(() => _error = Messages.agendaEventBadDate);
      return null;
    }
    final DateTime? start = parseEventTime(date, _start.text);
    if (start == null) {
      setState(() => _error = Messages.agendaEventBadStart);
      return null;
    }
    final DateTime? end = parseEventTime(date, _end.text);
    if (end == null || !end.isAfter(start)) {
      setState(() => _error = Messages.agendaEventBadEnd);
      return null;
    }
    return (start: start, end: end);
  }

  Future<void> _save() async {
    if (_busy) return;
    final ({DateTime start, DateTime end})? when = _validated();
    if (when == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    int? calendarId;
    if (widget.event == null) {
      final CalendarListResult calendars = await widget.repository
          .writableCalendars();
      if (!mounted) return;
      switch (calendars) {
        case CalendarList(:final List<CalendarInfo> calendars):
          if (calendars.isEmpty) {
            setState(() {
              _busy = false;
              _error = Messages.agendaEventNoCalendar;
            });
            return;
          }
          calendarId =
              (calendars.where((CalendarInfo c) => c.primary).firstOrNull ??
                      calendars.first)
                  .id;
        case CalendarListDenied(:final bool permanent):
          setState(() {
            _busy = false;
            _error = permanent
                ? Messages.agendaWriteAllowInSettings
                : Messages.agendaWriteNotAllowed;
          });
          return;
        case CalendarListUnavailable(:final String reason):
          setState(() {
            _busy = false;
            _error = reason.toUpperCase();
          });
          return;
      }
    }

    final NewCalendarEvent draft = NewCalendarEvent(
      calendarId: calendarId,
      title: _title.text.trim(),
      location: _location.text.trim().isEmpty ? null : _location.text.trim(),
      description: _description.text.trim().isEmpty
          ? null
          : _description.text.trim(),
      start: when.start,
      end: when.end,
    );
    final CalendarEvent? current = widget.event;
    final CalendarWriteResult result = current == null
        ? await widget.repository.createEvent(draft)
        : await widget.repository.updateEvent(current.id, draft);
    if (!mounted) return;
    switch (result) {
      case CalendarEventSaved():
        Navigator.of(context).pop(true);
      case CalendarWriteDenied(:final bool permanent):
        setState(() {
          _busy = false;
          _error = permanent
              ? Messages.agendaWriteAllowInSettings
              : Messages.agendaWriteNotAllowed;
        });
      case CalendarWriteFailed(:final String reason):
        setState(() {
          _busy = false;
          _error = reason.toUpperCase();
        });
    }
  }

  Future<void> _delete() async {
    final CalendarEvent? event = widget.event;
    if (event == null) return;
    setState(() {
      _busy = true;
      _confirmingDelete = false;
    });
    final CalendarDeleteResult result = await widget.repository.deleteEvent(
      event.id,
    );
    if (!mounted) return;
    switch (result) {
      case CalendarEventDeleted():
      case CalendarEventAlreadyGone():
        Navigator.of(context).pop(true);
      case CalendarDeleteDenied(:final bool permanent):
        setState(() {
          _busy = false;
          _error = permanent
              ? Messages.agendaWriteAllowInSettings
              : Messages.agendaWriteNotAllowed;
        });
      case CalendarDeleteFailed(:final String reason):
        setState(() {
          _busy = false;
          _error = reason.toUpperCase();
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
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
                      onTap: _busy ? null : _close,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(height: 2, color: TileColors.bezel),
              const SizedBox(height: TileMetrics.margin),
              if (_editing) _editForm(text) else _readView(text),
              if (_error != null) ...<Widget>[
                const SizedBox(height: TileMetrics.gutter),
                Text(
                  _error!,
                  style: text.bodySmall?.copyWith(
                    fontSize: 11,
                    color: TileColors.danger,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _readView(TextTheme text) {
    final CalendarEvent event = widget.event!;
    final String? location = event.location;
    final String? description = event.description;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
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
          value:
              '${formatClockDate(widget.day)} ${formatSpan(event, widget.day)}',
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
        const SizedBox(height: TileMetrics.margin),
        if (_confirmingDelete)
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  Messages.agendaEventDeleteAsk,
                  style: text.bodySmall?.copyWith(
                    fontSize: 11,
                    color: TileColors.highlight,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _Button(
                key: eventDetailDeleteYesKey,
                label: Messages.mailYes,
                onTap: _busy ? null : _delete,
              ),
              const SizedBox(width: 8),
              _Button(
                key: eventDetailDeleteNoKey,
                label: Messages.mailNo,
                onTap: () => setState(() => _confirmingDelete = false),
              ),
            ],
          )
        else
          Row(
            children: <Widget>[
              // All-day events are outside what this form can edit; deleting
              // one is still safe, since it never rewrites its times.
              if (!event.allDay) ...<Widget>[
                _Button(
                  key: eventDetailEditKey,
                  label: Messages.agendaEventEdit,
                  onTap: _busy ? null : _startEditing,
                ),
                const SizedBox(width: TileMetrics.margin * 2),
              ],
              _Button(
                key: eventDetailDeleteKey,
                label: _busy
                    ? Messages.agendaEventDeleting
                    : Messages.agendaEventDelete,
                onTap: _busy
                    ? null
                    : () => setState(() => _confirmingDelete = true),
              ),
            ],
          ),
      ],
    );
  }

  Widget _editForm(TextTheme text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _EditField(
          fieldKey: eventDetailTitleFieldKey,
          label: Messages.agendaEventTitleLabel,
          controller: _title,
        ),
        _EditField(
          fieldKey: eventDetailLocationFieldKey,
          label: Messages.agendaEventWhere,
          controller: _location,
        ),
        _EditField(
          fieldKey: eventDetailDescriptionFieldKey,
          label: Messages.agendaEventAbout,
          controller: _description,
          maxLines: 3,
        ),
        _EditField(
          fieldKey: eventDetailDateFieldKey,
          label: Messages.agendaEventDateLabel,
          controller: _date,
          keyboardType: TextInputType.datetime,
        ),
        Row(
          children: <Widget>[
            Expanded(
              child: _EditField(
                fieldKey: eventDetailStartFieldKey,
                label: Messages.agendaEventStartLabel,
                controller: _start,
                keyboardType: TextInputType.datetime,
              ),
            ),
            const SizedBox(width: TileMetrics.gutter),
            Expanded(
              child: _EditField(
                fieldKey: eventDetailEndFieldKey,
                label: Messages.agendaEventEndLabel,
                controller: _end,
                keyboardType: TextInputType.datetime,
              ),
            ),
          ],
        ),
        const SizedBox(height: TileMetrics.gutter),
        _Button(
          key: eventDetailSaveKey,
          label: _busy ? Messages.agendaEventSaving : Messages.agendaEventSave,
          onTap: _busy ? null : _save,
        ),
      ],
    );
  }
}

/// One read-only property of the event, a bordered box under a small muted
/// label.
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

/// One editable property of the event: a small muted label over a `TextField`
/// with an underline border, the same shape [_Field]'s own box takes over.
class _EditField extends StatelessWidget {
  const _EditField({
    required this.fieldKey,
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.keyboardType,
  });

  final Key fieldKey;
  final String label;
  final TextEditingController controller;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: TileMetrics.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: text.bodySmall?.copyWith(
              fontSize: 8,
              color: TileColors.muted,
            ),
          ),
          TextField(
            key: fieldKey,
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: text.bodySmall?.copyWith(
              fontSize: 12,
              color: TileColors.textBright,
            ),
            cursorColor: TileColors.textBright,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: TileColors.bezel),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: TileColors.textBright),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A small bordered text button in the launcher's own look; a `null` [onTap]
/// greys it.
class _Button extends StatelessWidget {
  const _Button({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color colour = onTap == null
        ? TileColors.textDim
        : TileColors.textBright;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: colour, width: TileMetrics.bevel),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(fontSize: 11, color: colour),
        ),
      ),
    );
  }
}

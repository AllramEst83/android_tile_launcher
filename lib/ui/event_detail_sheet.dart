import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/agenda_format.dart';
import 'package:android_tile_launcher/model/calendar_event.dart';
import 'package:android_tile_launcher/model/clock_format.dart';
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
const Key eventDetailCalendarFieldKey = ValueKey<String>(
  'event-detail-calendar',
);
const Key eventDetailStartDateFieldKey = ValueKey<String>(
  'event-detail-start-date',
);
const Key eventDetailStartTimeFieldKey = ValueKey<String>(
  'event-detail-start-time',
);
const Key eventDetailEndDateFieldKey = ValueKey<String>(
  'event-detail-end-date',
);
const Key eventDetailEndDateClearKey = ValueKey<String>(
  'event-detail-end-date-clear',
);
const Key eventDetailEndTimeFieldKey = ValueKey<String>(
  'event-detail-end-time',
);

/// What a tap on an agenda event opens (everything it holds, one labelled
/// field per property), or what `+ ADD EVENT` opens directly into edit mode.
/// EDIT turns the read fields into an edit form (title, location, about,
/// calendar, start and end — timed events only: an all-day event can be
/// deleted here but not edited); SAVE writes it back and DELETE asks first.
/// The calendar field lists every calendar Android will accept an insert for,
/// defaulting to the event's own (or the account's primary) — changing it
/// moves the event. An end date is only shown once set; left alone, the event
/// ends the same day it starts. Completes with whether anything actually
/// changed, so the agenda sheet knows to reload.
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
    builder: (BuildContext sheetContext) => Padding(
      // Keeps the fields above the keyboard.
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: _EventDetailSheet(repository: repository, event: event, day: day),
    ),
  );
  return changed ?? false;
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

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

  late DateTime _startDate = _dateOnly(widget.event?.start ?? widget.day);

  /// Null means "the same day as [_startDate]": a field only shows up once
  /// it is actually set to something else.
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  List<CalendarInfo>? _calendars;
  int? _calendarId;
  bool _loadingCalendars = false;
  String? _calendarsError;

  bool _busy = false;
  bool _confirmingDelete = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final CalendarEvent? event = widget.event;
    if (event != null) {
      _startTime = TimeOfDay.fromDateTime(event.start);
      _endTime = TimeOfDay.fromDateTime(event.end);
      final DateTime endDay = _dateOnly(event.end);
      if (endDay != _startDate) _endDate = endDay;
    }
    if (_editing) _loadCalendars();
  }

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _loadCalendars() async {
    setState(() {
      _loadingCalendars = true;
      _calendarsError = null;
    });
    final CalendarListResult result = await widget.repository
        .writableCalendars();
    if (!mounted) return;
    switch (result) {
      case CalendarList(:final List<CalendarInfo> calendars):
        setState(() {
          _loadingCalendars = false;
          _calendars = calendars;
          _calendarId = _defaultCalendarId(calendars);
        });
      case CalendarListDenied(:final bool permanent):
        setState(() {
          _loadingCalendars = false;
          _calendarsError = permanent
              ? Messages.agendaWriteAllowInSettings
              : Messages.agendaWriteNotAllowed;
        });
      case CalendarListUnavailable(:final String reason):
        setState(() {
          _loadingCalendars = false;
          _calendarsError = reason.toUpperCase();
        });
    }
  }

  /// The event's own calendar, if it is still one Android will accept an
  /// insert for; otherwise (and always when adding) the account's primary
  /// calendar, or just the first one on offer.
  int? _defaultCalendarId(List<CalendarInfo> calendars) {
    if (calendars.isEmpty) return null;
    final int? current = widget.event?.calendarId;
    if (current != null && calendars.any((CalendarInfo c) => c.id == current)) {
      return current;
    }
    return (calendars.where((CalendarInfo c) => c.primary).firstOrNull ??
            calendars.first)
        .id;
  }

  void _startEditing() {
    setState(() {
      _editing = true;
      _error = null;
    });
    if (_calendars == null && !_loadingCalendars) _loadCalendars();
  }

  void _close() {
    final CalendarEvent? event = widget.event;
    if (event == null || !_editing) {
      Navigator.of(context).pop(false);
      return;
    }
    // Back out of editing an existing event to its read view, discarding
    // whatever was chosen.
    setState(() {
      _editing = false;
      _error = null;
      _title.text = event.title;
      _location.text = event.location ?? '';
      _description.text = event.description ?? '';
      _startDate = _dateOnly(event.start);
      final DateTime endDay = _dateOnly(event.end);
      _endDate = endDay == _startDate ? null : endDay;
      _startTime = TimeOfDay.fromDateTime(event.start);
      _endTime = TimeOfDay.fromDateTime(event.end);
    });
  }

  Future<void> _pickStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _startDate = _dateOnly(picked);
      // An explicit end date can never sit before the start it follows.
      if (_endDate != null && _endDate!.isBefore(_startDate)) {
        _endDate = _startDate;
      }
    });
  }

  Future<void> _pickEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate,
      firstDate: _startDate,
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    final DateTime day = _dateOnly(picked);
    setState(() => _endDate = day == _startDate ? null : day);
  }

  void _clearEndDate() => setState(() => _endDate = null);

  Future<void> _pickStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked == null || !mounted) return;
    setState(() => _startTime = picked);
  }

  Future<void> _pickEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime:
          _endTime ?? _startTime ?? const TimeOfDay(hour: 10, minute: 0),
    );
    if (picked == null || !mounted) return;
    setState(() => _endTime = picked);
  }

  ({DateTime start, DateTime end})? _validated() {
    final String title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _error = Messages.agendaEventTitleNeeded);
      return null;
    }
    final TimeOfDay? startTime = _startTime;
    if (startTime == null) {
      setState(() => _error = Messages.agendaEventStartTimeNeeded);
      return null;
    }
    final TimeOfDay? endTime = _endTime;
    if (endTime == null) {
      setState(() => _error = Messages.agendaEventEndTimeNeeded);
      return null;
    }
    final DateTime endDate = _endDate ?? _startDate;
    final DateTime start = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      startTime.hour,
      startTime.minute,
    );
    final DateTime end = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
      endTime.hour,
      endTime.minute,
    );
    if (!end.isAfter(start)) {
      setState(() => _error = Messages.agendaEventEndNotAfterStart);
      return null;
    }
    return (start: start, end: end);
  }

  Future<void> _save() async {
    if (_busy || _loadingCalendars) return;
    final ({DateTime start, DateTime end})? when = _validated();
    if (when == null) return;
    final int? calendarId = _calendarId;
    if (calendarId == null) {
      setState(
        () => _error = _calendarsError ?? Messages.agendaEventNoCalendar,
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
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
    final bool disabled = _busy || _loadingCalendars;
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
        _calendarField(text),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: _PickerField(
                fieldKey: eventDetailStartDateFieldKey,
                label: Messages.agendaEventStartDateLabel,
                value: formatClockDate(_startDate),
                onTap: disabled ? null : _pickStartDate,
              ),
            ),
            const SizedBox(width: TileMetrics.gutter),
            Expanded(
              child: _PickerField(
                fieldKey: eventDetailStartTimeFieldKey,
                label: Messages.agendaEventStartTimeLabel,
                value:
                    _startTime?.format(context) ?? Messages.agendaEventTapToSet,
                muted: _startTime == null,
                onTap: disabled ? null : _pickStartTime,
              ),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: _PickerField(
                fieldKey: eventDetailEndDateFieldKey,
                label: Messages.agendaEventEndDateLabel,
                value: _endDate == null
                    ? Messages.agendaEventSameDay
                    : formatClockDate(_endDate!),
                muted: _endDate == null,
                onTap: disabled ? null : _pickEndDate,
                trailing: _endDate == null
                    ? null
                    : _TextButton(
                        key: eventDetailEndDateClearKey,
                        label: Messages.agendaEventClear,
                        onTap: disabled ? null : _clearEndDate,
                      ),
              ),
            ),
            const SizedBox(width: TileMetrics.gutter),
            Expanded(
              child: _PickerField(
                fieldKey: eventDetailEndTimeFieldKey,
                label: Messages.agendaEventEndTimeLabel,
                value:
                    _endTime?.format(context) ?? Messages.agendaEventTapToSet,
                muted: _endTime == null,
                onTap: disabled ? null : _pickEndTime,
              ),
            ),
          ],
        ),
        const SizedBox(height: TileMetrics.gutter),
        _Button(
          key: eventDetailSaveKey,
          label: _busy ? Messages.agendaEventSaving : Messages.agendaEventSave,
          onTap: disabled ? null : _save,
        ),
      ],
    );
  }

  Widget _calendarField(TextTheme text) {
    final Widget content;
    if (_loadingCalendars) {
      content = Text(
        Messages.agendaEventLoadingCalendars,
        style: text.bodySmall?.copyWith(fontSize: 11, color: TileColors.muted),
      );
    } else {
      final List<CalendarInfo>? calendars = _calendars;
      if (calendars == null || calendars.isEmpty) {
        content = Text(
          _calendarsError ?? Messages.agendaEventNoCalendar,
          style: text.bodySmall?.copyWith(
            fontSize: 11,
            color: TileColors.danger,
          ),
        );
      } else {
        content = DropdownButtonFormField<int>(
          key: eventDetailCalendarFieldKey,
          initialValue: _calendarId,
          isExpanded: true,
          dropdownColor: TileColors.canvas,
          iconEnabledColor: TileColors.textBright,
          style: text.bodySmall?.copyWith(
            fontSize: 12,
            color: TileColors.textBright,
          ),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: TileColors.bezel),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: TileColors.textBright),
            ),
          ),
          items: <DropdownMenuItem<int>>[
            for (final CalendarInfo c in calendars)
              DropdownMenuItem<int>(
                value: c.id,
                child: Text(
                  c.name.toUpperCase(),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (int? value) => setState(() => _calendarId = value),
        );
      }
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: TileMetrics.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            Messages.agendaEventCalendarLabel,
            style: text.bodySmall?.copyWith(
              fontSize: 8,
              color: TileColors.muted,
            ),
          ),
          content,
        ],
      ),
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
  });

  final Key fieldKey;
  final String label;
  final TextEditingController controller;
  final int maxLines;

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

/// One property picked from a dialog rather than typed: a small muted label
/// over a tappable, underline-bordered box showing the current value (or a
/// placeholder, muted, before anything is picked), with room for a
/// [trailing] widget such as a CLEAR button.
class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.fieldKey,
    required this.label,
    required this.value,
    required this.onTap,
    this.muted = false,
    this.trailing,
  });

  final Key fieldKey;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool muted;
  final Widget? trailing;

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: InkWell(
                  key: fieldKey,
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: TileColors.bezel),
                      ),
                    ),
                    child: Text(
                      value,
                      style: text.bodySmall?.copyWith(
                        fontSize: 12,
                        color: muted ? TileColors.muted : TileColors.textBright,
                      ),
                    ),
                  ),
                ),
              ),
              ?trailing,
            ],
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

/// A plain text tap target, no border: for a small aside like CLEAR beside a
/// [_PickerField], where a boxed [_Button] would be too heavy.
class _TextButton extends StatelessWidget {
  const _TextButton({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color colour = onTap == null ? TileColors.textDim : TileColors.accent;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(left: 8, top: 10, bottom: 10),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(fontSize: 10, color: colour),
        ),
      ),
    );
  }
}

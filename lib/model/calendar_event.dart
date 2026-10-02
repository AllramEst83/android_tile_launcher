/// One occurrence of a calendar event (a repeating event gives one of these
/// per repeat). All times are local.
class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    this.allDay = false,
    this.location,
    this.description,
    this.calendarId,
    this.calendarVisible = true,
    this.repeating = false,
    this.splitOff = false,
    this.occurrenceMillis,
  });

  /// The event's id in Android's calendar provider; shared by all repeats.
  final int id;
  final String title;

  /// For an all-day event, local midnight of its first day.
  final DateTime start;

  /// When it ends. For an all-day event, local midnight of the day *after* its
  /// last day, so every event is a half-open range whatever its kind.
  final DateTime end;
  final bool allDay;
  final String? location;

  /// The event's own notes, if it has any — not shown on a tile or the
  /// agenda list, only in the event's own detail view.
  final String? description;

  /// The calendar it is filed under, so editing can default to the calendar
  /// it is already on instead of guessing. Null if it was never read (a
  /// freshly-built test value, say).
  final int? calendarId;

  /// Whether the phone's own calendar app has [calendarId] switched on: what
  /// decides if it shows here until the user picks for themselves (see
  /// `CalendarChoices`).
  final bool calendarVisible;

  /// One occurrence of a repeating series. Editing or deleting it must touch
  /// only this occurrence, never [id]'s whole series.
  final bool repeating;

  /// An occurrence already split off from its series (edited on its own
  /// before): its own event, but deleting it must cancel it rather than
  /// remove it, or the series' original occurrence comes back in its place.
  final bool splitOff;

  /// When this occurrence originally began, as Android stores it (epoch
  /// milliseconds; a UTC midnight for an all-day event): how Android names a
  /// single occurrence of a series. Null if never read.
  final int? occurrenceMillis;

  /// Whether a change to this event must be made to this occurrence only.
  bool get isOccurrence => repeating && !splitOff && occurrenceMillis != null;

  @override
  bool operator ==(Object other) =>
      other is CalendarEvent &&
      other.id == id &&
      other.title == title &&
      other.start == start &&
      other.end == end &&
      other.allDay == allDay &&
      other.location == location &&
      other.description == description &&
      other.calendarId == calendarId &&
      other.calendarVisible == calendarVisible &&
      other.repeating == repeating &&
      other.splitOff == splitOff &&
      other.occurrenceMillis == occurrenceMillis;

  @override
  int get hashCode => Object.hash(
    id,
    title,
    start,
    end,
    allDay,
    location,
    description,
    calendarId,
    calendarVisible,
    repeating,
    splitOff,
    occurrenceMillis,
  );

  @override
  String toString() => 'CalendarEvent($id, $title, $start..$end)';
}

/// A timed event to create or replace (no all-day events from this form).
/// [calendarId] is Android's id for the calendar to file it under: required
/// when adding (there is no calendar yet), left null when editing so the
/// event stays on whichever calendar it was already on.
class NewCalendarEvent {
  const NewCalendarEvent({
    this.calendarId,
    required this.title,
    this.location,
    this.description,
    required this.start,
    required this.end,
  });

  final int? calendarId;
  final String title;
  final String? location;
  final String? description;
  final DateTime start;
  final DateTime end;

  /// The same fields without a calendar, so an update leaves the event on
  /// whichever calendar it is already on.
  NewCalendarEvent onSameCalendar() => NewCalendarEvent(
    title: title,
    location: location,
    description: description,
    start: start,
    end: end,
  );
}

/// One of the phone's calendars: something events are shown from, and (if
/// [writable]) written to.
class CalendarInfo {
  const CalendarInfo({
    required this.id,
    required this.name,
    this.primary = false,
    this.account,
    this.visible = true,
    this.writable = true,
  });

  /// Android's id for the calendar; what an event is filed under.
  final int id;

  /// The calendar's own display name, or its account's address when it has
  /// none.
  final String name;

  /// Whether this is the account's own default calendar, for picking one
  /// automatically when there is more than one.
  final bool primary;

  /// The account it syncs with (an address, usually), for grouping; null if
  /// Android did not say.
  final String? account;

  /// Whether the phone's own calendar app has it switched on: the default for
  /// whether it shows here.
  final bool visible;

  /// Whether Android will accept an insert into it (`CALENDAR_ACCESS_LEVEL` at
  /// least contributor) — a calendar someone only shared read-only is not.
  final bool writable;

  @override
  bool operator ==(Object other) =>
      other is CalendarInfo &&
      other.id == id &&
      other.name == name &&
      other.primary == primary &&
      other.account == account &&
      other.visible == visible &&
      other.writable == writable;

  @override
  int get hashCode =>
      Object.hash(id, name, primary, account, visible, writable);

  @override
  String toString() => 'CalendarInfo($id, $name)';
}

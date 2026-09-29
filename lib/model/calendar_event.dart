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
      other.calendarId == calendarId;

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
}

/// A calendar an event can be written to: one Android will actually accept an
/// insert for (`CALENDAR_ACCESS_LEVEL` at least contributor), which is why a
/// calendar someone only shared read-only with the user never appears here.
class CalendarInfo {
  const CalendarInfo({
    required this.id,
    required this.name,
    this.primary = false,
  });

  /// Android's id for the calendar; what an event is filed under.
  final int id;

  /// The calendar's own display name, or its account's address when it has
  /// none.
  final String name;

  /// Whether this is the account's own default calendar, for picking one
  /// automatically when there is more than one.
  final bool primary;
}

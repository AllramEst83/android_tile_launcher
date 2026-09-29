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

  @override
  bool operator ==(Object other) =>
      other is CalendarEvent &&
      other.id == id &&
      other.title == title &&
      other.start == start &&
      other.end == end &&
      other.allDay == allDay &&
      other.location == location &&
      other.description == description;

  @override
  int get hashCode =>
      Object.hash(id, title, start, end, allDay, location, description);

  @override
  String toString() => 'CalendarEvent($id, $title, $start..$end)';
}

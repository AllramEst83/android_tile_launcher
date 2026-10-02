import 'package:android_tile_launcher/model/calendar_event.dart';

/// Which of the phone's calendars the agenda shows. Only the calendars the
/// user has actually switched are remembered; every other one follows the
/// phone's own calendar app (its `visible` switch), so a calendar added later
/// turns up the way that app shows it.
class CalendarChoices {
  const CalendarChoices([this.picked = const <int, bool>{}]);

  /// Calendar id -> shown, for the calendars switched here.
  final Map<int, bool> picked;

  /// Whether [calendar] shows.
  bool shows(CalendarInfo calendar) => picked[calendar.id] ?? calendar.visible;

  /// Whether [event] shows: its calendar's choice, else the phone's own
  /// switch for that calendar. An event that never said which calendar it is
  /// on always shows — nothing hides it by accident.
  bool showsEvent(CalendarEvent event) {
    final int? id = event.calendarId;
    if (id == null) return true;
    return picked[id] ?? event.calendarVisible;
  }

  /// [events] less those on a hidden calendar, in the same order.
  List<CalendarEvent> filter(List<CalendarEvent> events) => <CalendarEvent>[
    for (final CalendarEvent e in events)
      if (showsEvent(e)) e,
  ];

  /// These choices with [id] switched to [shown].
  CalendarChoices withShown(int id, {required bool shown}) =>
      CalendarChoices(<int, bool>{...picked, id: shown});

  /// How many of [calendars] are hidden.
  int hiddenAmong(List<CalendarInfo> calendars) =>
      calendars.where((CalendarInfo c) => !shows(c)).length;

  /// JSON keys must be strings, so the ids are written as text.
  Map<String, Object?> toJson() => <String, Object?>{
    for (final MapEntry<int, bool> e in picked.entries) '${e.key}': e.value,
  };

  /// Tolerant: anything that is not an id-to-bool entry is skipped, and
  /// anything that is not a map at all is no choices.
  factory CalendarChoices.fromJson(Object? json) {
    if (json is! Map) return const CalendarChoices();
    return CalendarChoices(<int, bool>{
      for (final MapEntry<Object?, Object?> e in json.entries)
        if (e.key is String && int.tryParse(e.key! as String) != null)
          if (e.value case final bool shown) int.parse(e.key! as String): shown,
    });
  }

  @override
  bool operator ==(Object other) =>
      other is CalendarChoices &&
      other.picked.length == picked.length &&
      picked.entries.every(
        (MapEntry<int, bool> e) => other.picked[e.key] == e.value,
      );

  @override
  int get hashCode => Object.hashAllUnordered(
    picked.entries.map((MapEntry<int, bool> e) => Object.hash(e.key, e.value)),
  );

  @override
  String toString() => 'CalendarChoices($picked)';
}

import 'package:android_tile_launcher/model/calendar_event.dart';

/// What the agenda tile can show right now: the events, or the reason there
/// are none to show. The tile words each case and offers the fix as a tap.
sealed class AgendaSnapshot {
  const AgendaSnapshot();
}

/// [events] overlap the range asked for: all-day events first, then by start.
/// Empty is a real answer: nothing planned.
class AgendaReady extends AgendaSnapshot {
  const AgendaReady(this.events);

  final List<CalendarEvent> events;

  @override
  bool operator ==(Object other) =>
      other is AgendaReady && _sameEvents(other.events, events);

  @override
  int get hashCode => Object.hashAll(events);

  @override
  String toString() => 'AgendaReady(${events.length} events)';
}

/// Calendar access has not been asked for yet. The tile never asks on its own:
/// a permission dialog appearing over the home screen would be hostile.
class AgendaNeedsPermission extends AgendaSnapshot {
  const AgendaNeedsPermission();

  @override
  bool operator ==(Object other) => other is AgendaNeedsPermission;

  @override
  int get hashCode => (AgendaNeedsPermission).hashCode;
}

/// The user said no. [permanent] means Android will no longer ask, so the tile
/// says where the setting is instead of offering a tap that does nothing.
class AgendaDenied extends AgendaSnapshot {
  const AgendaDenied({required this.permanent});

  final bool permanent;

  @override
  bool operator ==(Object other) =>
      other is AgendaDenied && other.permanent == permanent;

  @override
  int get hashCode => Object.hash(AgendaDenied, permanent);
}

/// Access is fine but the calendar could not be read; [reason] is short.
class AgendaUnavailable extends AgendaSnapshot {
  const AgendaUnavailable(this.reason);

  final String reason;

  @override
  bool operator ==(Object other) =>
      other is AgendaUnavailable && other.reason == reason;

  @override
  int get hashCode => Object.hash(AgendaUnavailable, reason);
}

bool _sameEvents(List<CalendarEvent> a, List<CalendarEvent> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

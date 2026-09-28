import 'package:android_tile_launcher/model/agenda_snapshot.dart';
import 'package:android_tile_launcher/model/calendar_event.dart';
import 'package:android_tile_launcher/services/agenda_repository.dart';
import 'package:android_tile_launcher/services/calendar_service.dart';
import 'package:android_tile_launcher/services/permission_service.dart';

/// [AgendaRepository] on a [CalendarService] (the events) and a
/// [PermissionService] (asked only from [allow]).
class LiveAgendaRepository implements AgendaRepository {
  LiveAgendaRepository({required this.calendar, required this.permissions});

  final CalendarService calendar;
  final PermissionService permissions;

  // Why the last request for access failed. Kept because Android reports "no
  // access" the same way whether it was never asked or was refused, and the
  // tile re-reads right after a tap: without this it would say "tap to allow"
  // again as if nothing had happened. Cleared as soon as a read succeeds, so
  // allowing it from Android's settings heals the tile at the next poll.
  AgendaDenied? _denied;

  // One request at a time: a second tap while the dialog is up joins it.
  Future<void>? _asking;

  @override
  Future<AgendaSnapshot> between(DateTime from, DateTime to) async {
    final CalendarResult result = await calendar.events(from: from, to: to);
    switch (result) {
      case CalendarEvents(:final List<CalendarEvent> events):
        _denied = null;
        return AgendaReady(events);
      case CalendarNoAccess():
        return _denied ?? const AgendaNeedsPermission();
      case CalendarUnavailable(:final String reason):
        return AgendaUnavailable(reason);
    }
  }

  @override
  Future<void> allow() =>
      _asking ??= _allow().whenComplete(() => _asking = null);

  Future<void> _allow() async {
    final PermissionStatus status = await permissions.request(
      AppPermission.calendar,
    );
    _denied = switch (status) {
      PermissionStatus.granted => null,
      PermissionStatus.denied => const AgendaDenied(permanent: false),
      PermissionStatus.permanentlyDenied => const AgendaDenied(permanent: true),
    };
  }
}

import 'package:android_tile_launcher/model/agenda_snapshot.dart';
import 'package:android_tile_launcher/model/calendar_event.dart';
import 'package:android_tile_launcher/services/calendar_service.dart';
import 'package:android_tile_launcher/services/live_agenda_repository.dart';
import 'package:android_tile_launcher/services/permission_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_calendar_service.dart';
import '../fakes/fake_permission_service.dart';

final DateTime _from = DateTime(2026, 9, 28);
final DateTime _to = DateTime(2026, 9, 29);

final CalendarEvent _event = CalendarEvent(
  id: 1,
  title: 'Dentist',
  start: DateTime(2026, 9, 28, 9),
  end: DateTime(2026, 9, 28, 10),
);

void main() {
  late FakeCalendarService calendar;
  late FakePermissionService permissions;
  late LiveAgendaRepository repository;
  setUp(() {
    calendar = FakeCalendarService();
    permissions = FakePermissionService();
    repository = LiveAgendaRepository(
      calendar: calendar,
      permissions: permissions,
    );
  });

  test('passes the range on and returns the events', () async {
    calendar.result = CalendarEvents(<CalendarEvent>[_event]);

    final AgendaSnapshot snapshot = await repository.between(_from, _to);

    expect(snapshot, AgendaReady(<CalendarEvent>[_event]));
    expect(calendar.lastFrom, _from);
    expect(calendar.lastTo, _to);
  });

  test('nothing planned is still ready', () async {
    calendar.result = const CalendarEvents(<CalendarEvent>[]);

    expect(
      await repository.between(_from, _to),
      const AgendaReady(<CalendarEvent>[]),
    );
  });

  test('reading never asks for permission', () async {
    await repository.between(_from, _to);

    expect(permissions.requested, isEmpty);
  });

  test('before it was asked, no access means needs permission', () async {
    expect(await repository.between(_from, _to), const AgendaNeedsPermission());
  });

  test('allow asks for calendar access', () async {
    await repository.allow();

    expect(permissions.requested, <AppPermission>[AppPermission.calendar]);
  });

  test('a refusal is remembered, so the tile can say so', () async {
    permissions.answer = PermissionStatus.denied;

    await repository.allow();

    expect(
      await repository.between(_from, _to),
      const AgendaDenied(permanent: false),
    );
  });

  test('a permanent refusal is remembered as permanent', () async {
    permissions.answer = PermissionStatus.permanentlyDenied;

    await repository.allow();

    expect(
      await repository.between(_from, _to),
      const AgendaDenied(permanent: true),
    );
  });

  test('granting afterwards clears the refusal and reads events', () async {
    permissions.answer = PermissionStatus.denied;
    await repository.allow();
    permissions.answer = PermissionStatus.granted;
    await repository.allow();
    calendar.result = CalendarEvents(<CalendarEvent>[_event]);

    expect(await repository.between(_from, _to), isA<AgendaReady>());
  });

  test('allowing it in Android settings heals a remembered refusal', () async {
    permissions.answer = PermissionStatus.permanentlyDenied;
    await repository.allow();

    calendar.result = CalendarEvents(<CalendarEvent>[_event]);
    expect(await repository.between(_from, _to), isA<AgendaReady>());

    // ...and a later loss of access is back to "not asked", not "refused".
    calendar.result = const CalendarNoAccess();
    expect(await repository.between(_from, _to), const AgendaNeedsPermission());
  });

  test('a calendar that cannot be read says why', () async {
    calendar.result = const CalendarUnavailable('the calendar did not answer');

    expect(
      await repository.between(_from, _to),
      const AgendaUnavailable('the calendar did not answer'),
    );
  });

  test('two taps while the dialog is up ask once', () async {
    final Future<void> first = repository.allow();
    final Future<void> second = repository.allow();
    await Future.wait(<Future<void>>[first, second]);

    expect(permissions.requested, hasLength(1));
  });
}

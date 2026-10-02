import 'package:android_tile_launcher/model/agenda_snapshot.dart';
import 'package:android_tile_launcher/model/calendar_choices.dart';
import 'package:android_tile_launcher/model/calendar_event.dart';
import 'package:android_tile_launcher/services/calendar_service.dart';
import 'package:android_tile_launcher/services/live_agenda_repository.dart';
import 'package:android_tile_launcher/services/permission_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_calendar_service.dart';
import '../fakes/fake_permission_service.dart';
import '../fakes/in_memory_local_store.dart';

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

  group('writes', () {
    final NewCalendarEvent draft = NewCalendarEvent(
      calendarId: 4,
      title: 'Lunch',
      start: DateTime(2026, 9, 28, 12),
      end: DateTime(2026, 9, 28, 13),
    );

    test('writableCalendars passes straight through', () async {
      calendar.listResult = const CalendarList(<CalendarInfo>[
        CalendarInfo(id: 4, name: 'Family'),
      ]);

      expect(
        (await repository.writableCalendars() as CalendarList).calendars,
        const <CalendarInfo>[CalendarInfo(id: 4, name: 'Family')],
      );
    });

    test('writableCalendars leaves out the hidden ones', () async {
      calendar.listResult = const CalendarList(<CalendarInfo>[
        CalendarInfo(id: 4, name: 'Family'),
        CalendarInfo(id: 5, name: 'Work'),
      ]);
      await repository.setCalendarShown(4, shown: false);

      expect(
        (await repository.writableCalendars() as CalendarList).calendars.map(
          (c) => c.id,
        ),
        <int>[5],
      );
    });

    test('...unless that would leave none to write to', () async {
      calendar.listResult = const CalendarList(<CalendarInfo>[
        CalendarInfo(id: 4, name: 'Family'),
      ]);
      await repository.setCalendarShown(4, shown: false);

      expect(
        (await repository.writableCalendars() as CalendarList).calendars.map(
          (c) => c.id,
        ),
        <int>[4],
      );
    });

    test('createEvent passes the draft through and back', () async {
      calendar.writeResult = const CalendarEventSaved(9);

      final result = await repository.createEvent(draft);

      expect(calendar.created, <NewCalendarEvent>[draft]);
      expect(result, const CalendarEventSaved(9));
    });

    CalendarEvent stored({int? calendarId = 4, bool repeating = false}) =>
        CalendarEvent(
          id: 9,
          title: 'Lunch',
          start: DateTime(2026, 9, 28, 12),
          end: DateTime(2026, 9, 28, 13),
          calendarId: calendarId,
          repeating: repeating,
          occurrenceMillis: repeating ? 1 : null,
        );

    test('updateEvent on the same calendar edits it in place', () async {
      calendar.writeResult = const CalendarEventSaved(9);

      final result = await repository.updateEvent(stored(), draft);

      expect(calendar.updated.single.$1, 9);
      // The calendar is never rewritten on an existing event.
      expect(calendar.updated.single.$2.calendarId, isNull);
      expect(calendar.updated.single.$2.title, 'Lunch');
      expect(calendar.created, isEmpty);
      expect(result, const CalendarEventSaved(9));
    });

    test('updateEvent to another calendar adds there, then removes', () async {
      calendar.writeResult = const CalendarEventSaved(20);

      final result = await repository.updateEvent(stored(calendarId: 7), draft);

      expect(calendar.created, <NewCalendarEvent>[draft]);
      expect(calendar.deleted, <int>[9]);
      expect(calendar.updated, isEmpty);
      expect(result, const CalendarEventSaved(20));
    });

    test('a failed add to another calendar removes nothing', () async {
      calendar.writeResult = const CalendarWriteFailed('nope');

      final result = await repository.updateEvent(stored(calendarId: 7), draft);

      expect(calendar.deleted, isEmpty);
      expect(result, isA<CalendarWriteFailed>());
    });

    test('an occurrence of a series never moves calendar', () async {
      await repository.updateEvent(
        stored(calendarId: 7, repeating: true),
        draft,
      );

      expect(calendar.created, isEmpty);
      expect(calendar.deleted, isEmpty);
      expect(calendar.updated.single.$1, 9);
    });

    test('deleteEvent passes the event through and back', () async {
      calendar.deleteResult = const CalendarEventAlreadyGone();

      final result = await repository.deleteEvent(stored());

      expect(calendar.deleted, <int>[9]);
      expect(result, const CalendarEventAlreadyGone());
    });
  });

  group('calendar choices', () {
    CalendarEvent on(int id, int calendarId, {bool visible = true}) =>
        CalendarEvent(
          id: id,
          title: 'E$id',
          start: DateTime(2026, 9, 28, 9),
          end: DateTime(2026, 9, 28, 10),
          calendarId: calendarId,
          calendarVisible: visible,
        );

    test('the phone calendar app decides until the user picks', () async {
      calendar.result = CalendarEvents(<CalendarEvent>[
        on(1, 1),
        on(2, 2, visible: false),
      ]);

      final snapshot = await repository.between(_from, _to);

      expect((snapshot as AgendaReady).events.map((e) => e.id), <int>[1]);
    });

    test('a hidden calendar drops out; a shown one comes in', () async {
      calendar.result = CalendarEvents(<CalendarEvent>[
        on(1, 1),
        on(2, 2, visible: false),
      ]);
      await repository.setCalendarShown(1, shown: false);
      await repository.setCalendarShown(2, shown: true);

      final snapshot = await repository.between(_from, _to);

      expect((snapshot as AgendaReady).events.map((e) => e.id), <int>[2]);
    });

    test('choices are saved and read back by a later run', () async {
      final InMemoryLocalStore store = InMemoryLocalStore();
      await LiveAgendaRepository(
        calendar: calendar,
        permissions: permissions,
        store: store,
      ).setCalendarShown(3, shown: false);

      final LiveAgendaRepository later = LiveAgendaRepository(
        calendar: calendar,
        permissions: permissions,
        store: store,
      );

      expect(
        await later.calendarChoices(),
        const CalendarChoices(<int, bool>{3: false}),
      );
    });

    test('an unreadable store is no choices, not a failure', () async {
      final LiveAgendaRepository broken = LiveAgendaRepository(
        calendar: calendar,
        permissions: permissions,
        store: InMemoryLocalStore(failure: Exception('disk')),
      );
      calendar.result = CalendarEvents(<CalendarEvent>[on(1, 1)]);

      expect(await broken.calendarChoices(), const CalendarChoices());
      await broken.setCalendarShown(1, shown: false);
      // Still honoured for this run.
      expect((await broken.between(_from, _to) as AgendaReady).events, isEmpty);
    });

    test('calendars passes the full list straight through', () async {
      calendar.allResult = const CalendarList(<CalendarInfo>[
        CalendarInfo(id: 1, name: 'Shared', writable: false),
      ]);

      expect(await repository.calendars(), same(calendar.allResult));
      expect(permissions.requested, isEmpty);
    });
  });
}

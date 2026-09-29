import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/calendar_event.dart';
import 'package:android_tile_launcher/services/calendar_service.dart';
import 'package:android_tile_launcher/ui/event_detail_sheet.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_agenda_repository.dart';

/// Holds what `showEventDetailSheet` eventually completes with — a plain
/// nullable field, not a `Future`, so a test can open the sheet, interact
/// with it over several more pumps, and only then read the result, without
/// an `async` helper awaiting (and so needing) that completion before it can
/// even return.
class _Opened {
  bool? changed;
}

Future<_Opened> _open(
  WidgetTester tester,
  FakeAgendaRepository repository, {
  CalendarEvent? event,
  DateTime? day,
}) async {
  final _Opened opened = _Opened();
  await tester.pumpWidget(
    MaterialApp(
      theme: tileLauncherTheme(),
      home: Builder(
        builder: (BuildContext context) => TextButton(
          onPressed: () async {
            opened.changed = await showEventDetailSheet(
              context,
              repository: repository,
              event: event,
              day:
                  day ??
                  (event == null
                      ? DateTime(2026, 9, 28)
                      : DateTime(
                          event.start.year,
                          event.start.month,
                          event.start.day,
                        )),
            );
          },
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return opened;
}

CalendarEvent _dentist({bool allDay = false}) => CalendarEvent(
  id: 1,
  title: 'Dentist',
  start: DateTime(2026, 9, 28, 14, 30),
  end: DateTime(2026, 9, 28, 15),
  location: 'Storgatan 1',
  description: 'Bring the insurance card',
  allDay: allDay,
);

void main() {
  testWidgets('shows the title, when, where and about', (
    WidgetTester tester,
  ) async {
    await _open(tester, FakeAgendaRepository(), event: _dentist());

    expect(find.text(Messages.agendaEventTitle), findsOneWidget);
    expect(find.text('DENTIST'), findsOneWidget);
    expect(find.textContaining('14:30-15:00'), findsOneWidget);
    expect(find.text('STORGATAN 1'), findsOneWidget);
    expect(find.text('BRING THE INSURANCE CARD'), findsOneWidget);
  });

  testWidgets('a title-less event still shows something', (
    WidgetTester tester,
  ) async {
    await _open(
      tester,
      FakeAgendaRepository(),
      event: CalendarEvent(
        id: 1,
        title: '',
        start: DateTime(2026, 9, 28, 9),
        end: DateTime(2026, 9, 28, 10),
      ),
    );

    expect(find.text(Messages.agendaUntitled), findsOneWidget);
  });

  testWidgets('no location: the WHERE field is left out entirely', (
    WidgetTester tester,
  ) async {
    await _open(
      tester,
      FakeAgendaRepository(),
      event: CalendarEvent(
        id: 1,
        title: 'Solo run',
        start: DateTime(2026, 9, 28, 9),
        end: DateTime(2026, 9, 28, 10),
      ),
    );

    expect(find.byKey(eventDetailWhereKey), findsNothing);
  });

  testWidgets('no description: ABOUT says so instead of being blank', (
    WidgetTester tester,
  ) async {
    await _open(
      tester,
      FakeAgendaRepository(),
      event: CalendarEvent(
        id: 1,
        title: 'Solo run',
        start: DateTime(2026, 9, 28, 9),
        end: DateTime(2026, 9, 28, 10),
      ),
    );

    expect(find.text(Messages.agendaEventNoDescription), findsOneWidget);
  });

  testWidgets('an all-day event says so, not a bare time range', (
    WidgetTester tester,
  ) async {
    await _open(
      tester,
      FakeAgendaRepository(),
      event: CalendarEvent(
        id: 1,
        title: 'Holiday',
        start: DateTime(2026, 9, 28),
        end: DateTime(2026, 9, 29),
        allDay: true,
      ),
    );

    expect(find.textContaining('ALL DAY'), findsOneWidget);
  });

  testWidgets('an all-day event has no EDIT, only DELETE', (
    WidgetTester tester,
  ) async {
    await _open(tester, FakeAgendaRepository(), event: _dentist(allDay: true));

    expect(find.byKey(eventDetailEditKey), findsNothing);
    expect(find.byKey(eventDetailDeleteKey), findsOneWidget);
  });

  testWidgets('X closes the sheet without saying anything changed', (
    WidgetTester tester,
  ) async {
    final _Opened result = await _open(
      tester,
      FakeAgendaRepository(),
      event: _dentist(),
    );
    expect(find.text(Messages.agendaEventTitle), findsOneWidget);

    await tester.tap(find.byKey(eventDetailCloseKey));
    await tester.pumpAndSettle();

    expect(find.text(Messages.agendaEventTitle), findsNothing);
    expect(result.changed, isFalse);
  });

  group('edit', () {
    testWidgets('EDIT shows the fields pre-filled, X backs out unsaved', (
      WidgetTester tester,
    ) async {
      await _open(tester, FakeAgendaRepository(), event: _dentist());

      await tester.tap(find.byKey(eventDetailEditKey));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<TextField>(find.byKey(eventDetailTitleFieldKey))
            .controller
            ?.text,
        'Dentist',
      );
      expect(
        tester
            .widget<TextField>(find.byKey(eventDetailDateFieldKey))
            .controller
            ?.text,
        '2026-09-28',
      );
      expect(
        tester
            .widget<TextField>(find.byKey(eventDetailStartFieldKey))
            .controller
            ?.text,
        '14:30',
      );

      await tester.tap(find.byKey(eventDetailCloseKey));
      await tester.pumpAndSettle();

      // Back to the read view, not closed.
      expect(find.text('DENTIST'), findsOneWidget);
      expect(find.byKey(eventDetailTitleFieldKey), findsNothing);
    });

    testWidgets('an empty title refuses to save', (WidgetTester tester) async {
      await _open(tester, FakeAgendaRepository(), event: _dentist());
      await tester.tap(find.byKey(eventDetailEditKey));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(eventDetailTitleFieldKey), '');
      await tester.tap(find.byKey(eventDetailSaveKey));
      await tester.pumpAndSettle();

      expect(find.text(Messages.agendaEventTitleNeeded), findsOneWidget);
    });

    testWidgets('a bad start time refuses to save', (
      WidgetTester tester,
    ) async {
      await _open(tester, FakeAgendaRepository(), event: _dentist());
      await tester.tap(find.byKey(eventDetailEditKey));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(eventDetailStartFieldKey), 'noon');
      await tester.tap(find.byKey(eventDetailSaveKey));
      await tester.pumpAndSettle();

      expect(find.text(Messages.agendaEventBadStart), findsOneWidget);
    });

    testWidgets('an end not after the start refuses to save', (
      WidgetTester tester,
    ) async {
      await _open(tester, FakeAgendaRepository(), event: _dentist());
      await tester.tap(find.byKey(eventDetailEditKey));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(eventDetailEndFieldKey), '14:00');
      await tester.tap(find.byKey(eventDetailSaveKey));
      await tester.pumpAndSettle();

      expect(find.text(Messages.agendaEventBadEnd), findsOneWidget);
    });

    testWidgets('saving updates the event and never sends a calendar id', (
      WidgetTester tester,
    ) async {
      final FakeAgendaRepository repository = FakeAgendaRepository();
      final _Opened result = await _open(tester, repository, event: _dentist());
      await tester.tap(find.byKey(eventDetailEditKey));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(eventDetailTitleFieldKey), 'Doctor');
      await tester.tap(find.byKey(eventDetailSaveKey));
      await tester.pumpAndSettle();

      expect(repository.updated, hasLength(1));
      expect(repository.updated.single.$1, 1);
      expect(repository.updated.single.$2.title, 'Doctor');
      expect(repository.updated.single.$2.calendarId, isNull);
      expect(result.changed, isTrue);
    });

    testWidgets('write refused (permanently) says where to allow it', (
      WidgetTester tester,
    ) async {
      final FakeAgendaRepository repository = FakeAgendaRepository()
        ..writeResult = const CalendarWriteDenied(permanent: true);
      await _open(tester, repository, event: _dentist());
      await tester.tap(find.byKey(eventDetailEditKey));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(eventDetailSaveKey));
      await tester.pumpAndSettle();

      expect(find.text(Messages.agendaWriteAllowInSettings), findsOneWidget);
    });
  });

  group('delete', () {
    testWidgets('DELETE asks first', (WidgetTester tester) async {
      await _open(tester, FakeAgendaRepository(), event: _dentist());

      await tester.tap(find.byKey(eventDetailDeleteKey));
      await tester.pumpAndSettle();

      expect(find.text(Messages.agendaEventDeleteAsk), findsOneWidget);
    });

    testWidgets('NO cancels, nothing is deleted', (WidgetTester tester) async {
      final FakeAgendaRepository repository = FakeAgendaRepository();
      await _open(tester, repository, event: _dentist());

      await tester.tap(find.byKey(eventDetailDeleteKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(eventDetailDeleteNoKey));
      await tester.pumpAndSettle();

      expect(repository.deleted, isEmpty);
      expect(find.text(Messages.agendaEventDeleteAsk), findsNothing);
    });

    testWidgets('YES deletes and closes, reporting a change', (
      WidgetTester tester,
    ) async {
      final FakeAgendaRepository repository = FakeAgendaRepository();
      final _Opened result = await _open(tester, repository, event: _dentist());

      await tester.tap(find.byKey(eventDetailDeleteKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(eventDetailDeleteYesKey));
      await tester.pumpAndSettle();

      expect(repository.deleted, <int>[1]);
      expect(find.text(Messages.agendaEventTitle), findsNothing);
      expect(result.changed, isTrue);
    });
  });

  group('add', () {
    testWidgets('opens straight into the edit form, no EDIT/DELETE', (
      WidgetTester tester,
    ) async {
      await _open(tester, FakeAgendaRepository(), day: DateTime(2026, 9, 28));

      expect(find.byKey(eventDetailTitleFieldKey), findsOneWidget);
      expect(find.byKey(eventDetailEditKey), findsNothing);
      expect(find.byKey(eventDetailDeleteKey), findsNothing);
      expect(
        tester
            .widget<TextField>(find.byKey(eventDetailDateFieldKey))
            .controller
            ?.text,
        '2026-09-28',
      );
    });

    testWidgets(
      'X closes the sheet entirely: there is no read view to fall back to',
      (WidgetTester tester) async {
        final _Opened result = await _open(
          tester,
          FakeAgendaRepository(),
          day: DateTime(2026, 9, 28),
        );

        await tester.tap(find.byKey(eventDetailCloseKey));
        await tester.pumpAndSettle();

        expect(find.text(Messages.agendaEventTitle), findsNothing);
        expect(result.changed, isFalse);
      },
    );

    testWidgets('saves to the primary writable calendar', (
      WidgetTester tester,
    ) async {
      final FakeAgendaRepository repository = FakeAgendaRepository()
        ..listResult = const CalendarList(<CalendarInfo>[
          CalendarInfo(id: 1, name: 'Work'),
          CalendarInfo(id: 2, name: 'Home', primary: true),
        ]);
      final _Opened result = await _open(
        tester,
        repository,
        day: DateTime(2026, 9, 28),
      );

      await tester.enterText(find.byKey(eventDetailTitleFieldKey), 'Gym');
      await tester.enterText(find.byKey(eventDetailStartFieldKey), '18:00');
      await tester.enterText(find.byKey(eventDetailEndFieldKey), '19:00');
      await tester.tap(find.byKey(eventDetailSaveKey));
      await tester.pumpAndSettle();

      expect(repository.created, hasLength(1));
      final NewCalendarEvent saved = repository.created.single;
      expect(saved.title, 'Gym');
      expect(saved.calendarId, 2);
      expect(saved.start, DateTime(2026, 9, 28, 18));
      expect(saved.end, DateTime(2026, 9, 28, 19));
      expect(result.changed, isTrue);
    });

    testWidgets('no writable calendar says so and saves nothing', (
      WidgetTester tester,
    ) async {
      final FakeAgendaRepository repository = FakeAgendaRepository()
        ..listResult = const CalendarList(<CalendarInfo>[]);
      await _open(tester, repository, day: DateTime(2026, 9, 28));

      await tester.enterText(find.byKey(eventDetailTitleFieldKey), 'Gym');
      await tester.enterText(find.byKey(eventDetailStartFieldKey), '18:00');
      await tester.enterText(find.byKey(eventDetailEndFieldKey), '19:00');
      await tester.tap(find.byKey(eventDetailSaveKey));
      await tester.pumpAndSettle();

      expect(find.text(Messages.agendaEventNoCalendar), findsOneWidget);
      expect(repository.created, isEmpty);
    });
  });
}

import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/calendar_event.dart';
import 'package:android_tile_launcher/model/settings.dart';
import 'package:android_tile_launcher/services/calendar_service.dart';
import 'package:android_tile_launcher/services/settings_state.dart';
import 'package:android_tile_launcher/ui/event_detail_sheet.dart';
import 'package:android_tile_launcher/ui/settings_scope.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_agenda_repository.dart';
import '../fakes/in_memory_local_store.dart';

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
  DateTime? startAt,
  SettingsState? settings,
}) async {
  final _Opened opened = _Opened();
  final Widget app = MaterialApp(
    theme: tileLauncherTheme(),
    // Forces a plain hour/minute entry in the time picker (no AM/PM
    // segment), so tests can drive it without locale surprises.
    builder: (BuildContext context, Widget? child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
      child: child!,
    ),
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
            startAt: startAt,
          );
        },
        child: const Text('open'),
      ),
    ),
  );
  await tester.pumpWidget(
    settings == null ? app : SettingsScope(state: settings, child: app),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return opened;
}

/// A [SettingsState] already holding [lastUsedCalendarId], for a test that
/// wants `+ ADD EVENT` to default to it.
SettingsState _settingsWithLastUsedCalendar(int lastUsedCalendarId) {
  final SettingsState settings = SettingsState(store: InMemoryLocalStore());
  settings.update(LauncherSettings(lastUsedCalendarId: lastUsedCalendarId));
  return settings;
}

CalendarEvent _dentist({bool allDay = false}) => CalendarEvent(
  id: 1,
  title: 'Dentist',
  start: DateTime(2026, 9, 28, 14, 30),
  end: DateTime(2026, 9, 28, 15),
  location: 'Storgatan 1',
  description: 'Bring the insurance card',
  allDay: allDay,
  calendarId: 2,
);

FakeAgendaRepository _withOneCalendar() => FakeAgendaRepository()
  ..listResult = const CalendarList(<CalendarInfo>[
    CalendarInfo(id: 2, name: 'Home', primary: true),
  ]);

/// Picks [day] of the month already on screen and confirms it.
Future<void> _pickDate(WidgetTester tester, int day) async {
  await tester.pumpAndSettle();
  await tester.tap(find.text('$day').first);
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

/// Switches the time picker to text entry and types `hour:minute` (the test
/// app forces 24-hour format, so there is no AM/PM segment to contend with).
Future<void> _pickTime(WidgetTester tester, int hour, int minute) async {
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.keyboard_outlined));
  await tester.pumpAndSettle();
  final Finder fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), '$hour');
  await tester.enterText(fields.at(1), '$minute');
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

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
    testWidgets(
      'EDIT shows the fields pre-filled, calendar included, X backs out unsaved',
      (WidgetTester tester) async {
        await _open(tester, _withOneCalendar(), event: _dentist());

        await tester.tap(find.byKey(eventDetailEditKey));
        await tester.pumpAndSettle();

        expect(
          tester
              .widget<TextField>(find.byKey(eventDetailTitleFieldKey))
              .controller
              ?.text,
          'Dentist',
        );
        expect(find.text('MON 28 SEP'), findsOneWidget);
        expect(find.text('14:30'), findsOneWidget);
        expect(find.text(Messages.agendaEventSameDay), findsOneWidget);
        expect(find.text('15:00'), findsOneWidget);
        expect(find.text('HOME'), findsOneWidget);

        await tester.tap(find.byKey(eventDetailCloseKey));
        await tester.pumpAndSettle();

        // Back to the read view, not closed.
        expect(find.text('DENTIST'), findsOneWidget);
        expect(find.byKey(eventDetailTitleFieldKey), findsNothing);
      },
    );

    testWidgets('an empty title refuses to save', (WidgetTester tester) async {
      await _open(tester, _withOneCalendar(), event: _dentist());
      await tester.tap(find.byKey(eventDetailEditKey));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(eventDetailTitleFieldKey), '');
      await tester.tap(find.byKey(eventDetailSaveKey));
      await tester.pumpAndSettle();

      expect(find.text(Messages.agendaEventTitleNeeded), findsOneWidget);
    });

    testWidgets(
      'saving with nothing else touched keeps the times and calendar',
      (WidgetTester tester) async {
        final FakeAgendaRepository repository = _withOneCalendar();
        final _Opened result = await _open(
          tester,
          repository,
          event: _dentist(),
        );
        await tester.tap(find.byKey(eventDetailEditKey));
        await tester.pumpAndSettle();

        await tester.enterText(find.byKey(eventDetailTitleFieldKey), 'Doctor');
        await tester.tap(find.byKey(eventDetailSaveKey));
        await tester.pumpAndSettle();

        expect(repository.updated, hasLength(1));
        expect(repository.updated.single.$1, 1);
        final NewCalendarEvent saved = repository.updated.single.$2;
        expect(saved.title, 'Doctor');
        expect(saved.calendarId, 2);
        expect(saved.start, DateTime(2026, 9, 28, 14, 30));
        expect(saved.end, DateTime(2026, 9, 28, 15));
        expect(result.changed, isTrue);
      },
    );

    testWidgets('picking a new start date moves the whole event', (
      WidgetTester tester,
    ) async {
      final FakeAgendaRepository repository = _withOneCalendar();
      await _open(tester, repository, event: _dentist());
      await tester.tap(find.byKey(eventDetailEditKey));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(eventDetailStartDateFieldKey));
      await _pickDate(tester, 30);
      await tester.tap(find.byKey(eventDetailSaveKey));
      await tester.pumpAndSettle();

      final NewCalendarEvent saved = repository.updated.single.$2;
      expect(saved.start, DateTime(2026, 9, 30, 14, 30));
      // The end date was never set explicitly, so it follows the start.
      expect(saved.end, DateTime(2026, 9, 30, 15));
    });

    testWidgets('picking a new start time changes only that', (
      WidgetTester tester,
    ) async {
      final FakeAgendaRepository repository = _withOneCalendar();
      await _open(tester, repository, event: _dentist());
      await tester.tap(find.byKey(eventDetailEditKey));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(eventDetailStartTimeFieldKey));
      await _pickTime(tester, 8, 15);
      await tester.tap(find.byKey(eventDetailSaveKey));
      await tester.pumpAndSettle();

      final NewCalendarEvent saved = repository.updated.single.$2;
      expect(saved.start, DateTime(2026, 9, 28, 8, 15));
      expect(saved.end, DateTime(2026, 9, 28, 15));
    });

    testWidgets('setting an end date makes the event span days', (
      WidgetTester tester,
    ) async {
      final FakeAgendaRepository repository = _withOneCalendar();
      await _open(tester, repository, event: _dentist());
      await tester.tap(find.byKey(eventDetailEditKey));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(eventDetailEndDateFieldKey));
      await _pickDate(tester, 29);
      await tester.tap(find.byKey(eventDetailSaveKey));
      await tester.pumpAndSettle();

      final NewCalendarEvent saved = repository.updated.single.$2;
      expect(saved.start, DateTime(2026, 9, 28, 14, 30));
      expect(saved.end, DateTime(2026, 9, 29, 15));
    });

    testWidgets('CLEAR resets the end date back to the same day', (
      WidgetTester tester,
    ) async {
      await _open(tester, _withOneCalendar(), event: _dentist());
      await tester.tap(find.byKey(eventDetailEditKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(eventDetailEndDateFieldKey));
      await _pickDate(tester, 29);
      expect(find.byKey(eventDetailEndDateClearKey), findsOneWidget);

      await tester.tap(find.byKey(eventDetailEndDateClearKey));
      await tester.pumpAndSettle();

      expect(find.text(Messages.agendaEventSameDay), findsOneWidget);
      expect(find.byKey(eventDetailEndDateClearKey), findsNothing);
    });

    testWidgets('changing the calendar moves the event there', (
      WidgetTester tester,
    ) async {
      final FakeAgendaRepository repository = FakeAgendaRepository()
        ..listResult = const CalendarList(<CalendarInfo>[
          CalendarInfo(id: 2, name: 'Home', primary: true),
          CalendarInfo(id: 3, name: 'Work'),
        ]);
      await _open(tester, repository, event: _dentist());
      await tester.tap(find.byKey(eventDetailEditKey));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(eventDetailCalendarFieldKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('WORK').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(eventDetailSaveKey));
      await tester.pumpAndSettle();

      expect(repository.updated.single.$2.calendarId, 3);
    });

    testWidgets('no calendar can be written to: the field says so', (
      WidgetTester tester,
    ) async {
      final FakeAgendaRepository repository = FakeAgendaRepository()
        ..listResult = const CalendarList(<CalendarInfo>[]);
      await _open(tester, repository, event: _dentist());
      await tester.tap(find.byKey(eventDetailEditKey));
      await tester.pumpAndSettle();

      expect(find.text(Messages.agendaEventNoCalendar), findsOneWidget);
    });

    testWidgets('write refused (permanently) says where to allow it', (
      WidgetTester tester,
    ) async {
      final FakeAgendaRepository repository = _withOneCalendar()
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
      await _open(tester, _withOneCalendar(), day: DateTime(2026, 9, 28));

      expect(find.byKey(eventDetailTitleFieldKey), findsOneWidget);
      expect(find.byKey(eventDetailEditKey), findsNothing);
      expect(find.byKey(eventDetailDeleteKey), findsNothing);
      expect(find.text('MON 28 SEP'), findsOneWidget);
      expect(find.text(Messages.agendaEventTapToSet), findsNWidgets(2));
      expect(find.text('HOME'), findsOneWidget);
    });

    testWidgets(
      'X closes the sheet entirely: there is no read view to fall back to',
      (WidgetTester tester) async {
        final _Opened result = await _open(
          tester,
          _withOneCalendar(),
          day: DateTime(2026, 9, 28),
        );

        await tester.tap(find.byKey(eventDetailCloseKey));
        await tester.pumpAndSettle();

        expect(find.text(Messages.agendaEventTitle), findsNothing);
        expect(result.changed, isFalse);
      },
    );

    testWidgets('defaults to the calendar last saved to, if still on offer', (
      WidgetTester tester,
    ) async {
      final FakeAgendaRepository repository = FakeAgendaRepository()
        ..listResult = const CalendarList(<CalendarInfo>[
          CalendarInfo(id: 2, name: 'Home', primary: true),
          CalendarInfo(id: 3, name: 'Work'),
        ]);

      await _open(
        tester,
        repository,
        day: DateTime(2026, 9, 28),
        settings: _settingsWithLastUsedCalendar(3),
      );

      expect(find.text('WORK'), findsOneWidget);
      expect(find.text('HOME'), findsNothing);
    });

    testWidgets(
      'falls back to the primary calendar once the last-used one is gone',
      (WidgetTester tester) async {
        final FakeAgendaRepository repository = _withOneCalendar();

        await _open(
          tester,
          repository,
          day: DateTime(2026, 9, 28),
          settings: _settingsWithLastUsedCalendar(99),
        );

        expect(find.text('HOME'), findsOneWidget);
      },
    );

    testWidgets('saving remembers the calendar chosen, for next time', (
      WidgetTester tester,
    ) async {
      final FakeAgendaRepository repository = FakeAgendaRepository()
        ..listResult = const CalendarList(<CalendarInfo>[
          CalendarInfo(id: 2, name: 'Home', primary: true),
          CalendarInfo(id: 3, name: 'Work'),
        ]);
      final SettingsState settings = SettingsState(store: InMemoryLocalStore());

      await _open(
        tester,
        repository,
        day: DateTime(2026, 9, 28),
        settings: settings,
      );
      await tester.enterText(find.byKey(eventDetailTitleFieldKey), 'Gym');
      await tester.tap(find.byKey(eventDetailCalendarFieldKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('WORK').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(eventDetailStartTimeFieldKey));
      await _pickTime(tester, 9, 0);
      await tester.tap(find.byKey(eventDetailEndTimeFieldKey));
      await _pickTime(tester, 10, 0);
      await tester.tap(find.byKey(eventDetailSaveKey));
      await tester.pumpAndSettle();

      expect(settings.settings.lastUsedCalendarId, 3);
    });

    testWidgets('a start time is required to save', (
      WidgetTester tester,
    ) async {
      await _open(tester, _withOneCalendar(), day: DateTime(2026, 9, 28));

      await tester.enterText(find.byKey(eventDetailTitleFieldKey), 'Gym');
      await tester.tap(find.byKey(eventDetailSaveKey));
      await tester.pumpAndSettle();

      expect(find.text(Messages.agendaEventStartTimeNeeded), findsOneWidget);
    });

    testWidgets('an end time is required to save', (WidgetTester tester) async {
      await _open(tester, _withOneCalendar(), day: DateTime(2026, 9, 28));

      await tester.enterText(find.byKey(eventDetailTitleFieldKey), 'Gym');
      await tester.tap(find.byKey(eventDetailStartTimeFieldKey));
      await _pickTime(tester, 18, 0);
      await tester.tap(find.byKey(eventDetailSaveKey));
      await tester.pumpAndSettle();

      expect(find.text(Messages.agendaEventEndTimeNeeded), findsOneWidget);
    });

    testWidgets('an end not after the start refuses to save', (
      WidgetTester tester,
    ) async {
      await _open(tester, _withOneCalendar(), day: DateTime(2026, 9, 28));

      await tester.enterText(find.byKey(eventDetailTitleFieldKey), 'Gym');
      await tester.tap(find.byKey(eventDetailStartTimeFieldKey));
      await _pickTime(tester, 18, 0);
      await tester.tap(find.byKey(eventDetailEndTimeFieldKey));
      await _pickTime(tester, 17, 0);
      await tester.tap(find.byKey(eventDetailSaveKey));
      await tester.pumpAndSettle();

      expect(find.text(Messages.agendaEventEndNotAfterStart), findsOneWidget);
    });

    testWidgets('saves to the selected calendar with the picked times', (
      WidgetTester tester,
    ) async {
      final FakeAgendaRepository repository = _withOneCalendar();
      final _Opened result = await _open(
        tester,
        repository,
        day: DateTime(2026, 9, 28),
      );

      await tester.enterText(find.byKey(eventDetailTitleFieldKey), 'Gym');
      await tester.tap(find.byKey(eventDetailStartTimeFieldKey));
      await _pickTime(tester, 18, 0);
      await tester.tap(find.byKey(eventDetailEndTimeFieldKey));
      await _pickTime(tester, 19, 0);
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

      expect(find.text(Messages.agendaEventNoCalendar), findsOneWidget);

      await tester.enterText(find.byKey(eventDetailTitleFieldKey), 'Gym');
      await tester.tap(find.byKey(eventDetailStartTimeFieldKey));
      await _pickTime(tester, 18, 0);
      await tester.tap(find.byKey(eventDetailEndTimeFieldKey));
      await _pickTime(tester, 19, 0);
      await tester.tap(find.byKey(eventDetailSaveKey));
      await tester.pumpAndSettle();

      expect(repository.created, isEmpty);
    });
  });
  group('repeating events', () {
    CalendarEvent standup() => CalendarEvent(
      id: 7,
      title: 'Standup',
      start: DateTime(2026, 9, 28, 9),
      end: DateTime(2026, 9, 28, 9, 15),
      calendarId: 2,
      repeating: true,
      occurrenceMillis: DateTime(2026, 9, 28, 9).millisecondsSinceEpoch,
    );

    testWidgets('say that a change touches this occurrence only', (
      WidgetTester tester,
    ) async {
      await _open(tester, _withOneCalendar(), event: standup());

      expect(find.text(Messages.agendaEventRepeats), findsOneWidget);

      await tester.tap(find.byKey(eventDetailEditKey));
      await tester.pumpAndSettle();

      expect(find.text(Messages.agendaEventRepeats), findsOneWidget);
    });

    testWidgets('DELETE asks about the occurrence, and deletes only it', (
      WidgetTester tester,
    ) async {
      final FakeAgendaRepository repository = FakeAgendaRepository();
      await _open(tester, repository, event: standup());

      await tester.tap(find.byKey(eventDetailDeleteKey));
      await tester.pumpAndSettle();
      expect(
        find.text(Messages.agendaEventDeleteOccurrenceAsk),
        findsOneWidget,
      );
      await tester.tap(find.byKey(eventDetailDeleteYesKey));
      await tester.pumpAndSettle();

      // The whole event goes to the repository, so it can name the one
      // occurrence rather than the series' id alone.
      expect(repository.deletedEvents.single.isOccurrence, isTrue);
    });

    testWidgets('a one-off event says nothing about occurrences', (
      WidgetTester tester,
    ) async {
      await _open(tester, FakeAgendaRepository(), event: _dentist());

      expect(find.text(Messages.agendaEventRepeats), findsNothing);
    });
  });

  testWidgets('a multi-day event shows its own start and end', (
    WidgetTester tester,
  ) async {
    await _open(
      tester,
      FakeAgendaRepository(),
      event: CalendarEvent(
        id: 3,
        title: 'Ferry',
        start: DateTime(2026, 9, 26, 18),
        end: DateTime(2026, 9, 27, 14),
      ),
      // Opened from its second day, which used to read "UNTIL 14:00" alone.
      day: DateTime(2026, 9, 27),
    );

    expect(find.text('SAT 26 SEP 18:00 - SUN 27 SEP 14:00'), findsOneWidget);
  });

  testWidgets('a week-grid slot presets the start, and an end an hour on', (
    WidgetTester tester,
  ) async {
    await _open(
      tester,
      _withOneCalendar(),
      day: DateTime(2026, 9, 28, 14, 30),
      startAt: DateTime(2026, 9, 28, 14, 30),
    );

    expect(find.text('14:30'), findsOneWidget);
    expect(find.text('15:30'), findsOneWidget);
    expect(find.text(Messages.agendaEventTapToSet), findsNothing);
  });

  testWidgets('a slot in the last hour ends on the next day', (
    WidgetTester tester,
  ) async {
    final FakeAgendaRepository repository = _withOneCalendar();
    await _open(
      tester,
      repository,
      day: DateTime(2026, 9, 28, 23, 30),
      startAt: DateTime(2026, 9, 28, 23, 30),
    );
    await tester.enterText(find.byKey(eventDetailTitleFieldKey), 'Late');
    await tester.ensureVisible(find.byKey(eventDetailSaveKey));
    await tester.tap(find.byKey(eventDetailSaveKey));
    await tester.pumpAndSettle();

    final NewCalendarEvent saved = repository.created.single;
    expect(saved.start, DateTime(2026, 9, 28, 23, 30));
    expect(saved.end, DateTime(2026, 9, 29, 0, 30));
  });
}

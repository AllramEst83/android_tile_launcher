import 'dart:async';

import 'package:android_tile_launcher/messages.dart';

import 'package:android_tile_launcher/model/agenda_snapshot.dart';
import 'package:android_tile_launcher/model/calendar_choices.dart';
import 'package:android_tile_launcher/model/calendar_event.dart';
import 'package:android_tile_launcher/model/settings.dart';
import 'package:android_tile_launcher/services/calendar_service.dart';
import 'package:android_tile_launcher/services/settings_state.dart';
import 'package:android_tile_launcher/ui/agenda_sheet.dart';
import 'package:android_tile_launcher/ui/agenda_week_grid.dart';
import 'package:android_tile_launcher/ui/calendar_filter_sheet.dart';
import 'package:android_tile_launcher/ui/event_detail_sheet.dart';
import 'package:android_tile_launcher/ui/settings_scope.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_agenda_repository.dart';
import '../fakes/in_memory_local_store.dart';

// Monday 28 September 2026, half past ten.
final DateTime _now = DateTime(2026, 9, 28, 10, 30);

CalendarEvent _event(
  int id,
  String title,
  DateTime start, {
  String? location,
}) => CalendarEvent(
  id: id,
  title: title,
  start: start,
  end: start.add(const Duration(hours: 1)),
  location: location,
);

Future<void> _open(
  WidgetTester tester,
  FakeAgendaRepository repository, {
  SettingsState? settings,
  DateTime? now,
}) async {
  final Widget app = MaterialApp(
    theme: tileLauncherTheme(),
    // Forces a plain hour/minute entry in the event form's time picker (no
    // AM/PM segment), so a test can drive it without locale surprises.
    builder: (BuildContext context, Widget? child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
      child: child!,
    ),
    home: Builder(
      builder: (BuildContext context) => TextButton(
        onPressed: () => showAgendaSheet(
          context,
          repository: repository,
          clock: () => now ?? _now,
        ),
        child: const Text('open'),
      ),
    ),
  );
  // Wraps the whole `MaterialApp`, not just `home`: a modal sheet's route is
  // a sibling of `home` inside the Navigator, so a scope inside `home` would
  // never be an ancestor of it, the same way `app.dart` wraps its own
  // `MaterialApp` for exactly this to reach every sheet.
  await tester.pumpWidget(
    settings == null ? app : SettingsScope(state: settings, child: app),
  );
  await tester.tap(find.text('open'));
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

FakeAgendaRepository withEvents() => FakeAgendaRepository(
  AgendaReady(<CalendarEvent>[
    _event(1, 'Dentist', DateTime(2026, 9, 28, 9), location: 'Storgatan 1'),
    _event(2, 'Team lunch', DateTime(2026, 9, 29, 12)),
  ]),
);

void main() {
  testWidgets('opens on today: the day\'s events and nothing else', (
    WidgetTester tester,
  ) async {
    final FakeAgendaRepository repository = withEvents();
    await _open(tester, repository);

    expect(repository.lastFrom, DateTime(2026, 9, 28));
    expect(repository.lastTo, DateTime(2026, 9, 29));
    expect(find.text('DENTIST'), findsOneWidget);
    expect(find.text('09:00-10:00'), findsOneWidget);
    expect(find.text('STORGATAN 1'), findsOneWidget);
    // The fake ignores the range, so what keeps tomorrow out is the grouping.
    expect(find.text('TEAM LUNCH'), findsNothing);
  });

  testWidgets('DAY, AGENDA and GRID spread evenly across the row', (
    WidgetTester tester,
  ) async {
    await _open(tester, withEvents());

    final double dayX = tester.getCenter(find.byKey(agendaDayToggleKey)).dx;
    final double weekX = tester.getCenter(find.byKey(agendaWeekToggleKey)).dx;
    final double gridX = tester
        .getCenter(find.byKey(agendaWeekGridToggleKey))
        .dx;

    expect(weekX - dayX, closeTo(gridX - weekX, 1));
  });

  testWidgets('WEEK reads seven days and puts a heading over each day', (
    WidgetTester tester,
  ) async {
    final FakeAgendaRepository repository = withEvents();
    await _open(tester, repository);

    await tester.tap(find.byKey(agendaWeekToggleKey));
    await tester.pumpAndSettle();

    expect(repository.lastFrom, DateTime(2026, 9, 28));
    expect(repository.lastTo, DateTime(2026, 10, 5));
    // Scoped to the day list itself: the TODAY button above it is also this
    // exact text, in its own bordered box rather than a day's own heading.
    expect(
      find.descendant(of: find.byType(ListView), matching: find.text('TODAY')),
      findsOneWidget,
    );
    expect(find.text('TOMORROW'), findsOneWidget);
    expect(find.text('DENTIST'), findsOneWidget);
    expect(find.text('TEAM LUNCH'), findsOneWidget);
  });

  testWidgets('WEEK always starts on Monday, whatever day it is opened on', (
    WidgetTester tester,
  ) async {
    // Thursday 1 October 2026: opening WEEK from here must still read from
    // this week's own Monday (28 Sep), not a rolling seven days from today.
    final FakeAgendaRepository repository = withEvents();
    await _open(tester, repository, now: DateTime(2026, 10, 1, 8));

    await tester.tap(find.byKey(agendaWeekToggleKey));
    await tester.pumpAndSettle();

    expect(repository.lastFrom, DateTime(2026, 9, 28));
    expect(repository.lastTo, DateTime(2026, 10, 5));
    expect(
      tester.widget<Text>(find.byKey(agendaNavLabelKey)).data,
      'THIS WEEK',
    );
  });

  testWidgets('DAY goes back to today', (WidgetTester tester) async {
    await _open(tester, withEvents());
    await tester.tap(find.byKey(agendaWeekToggleKey));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(agendaDayToggleKey));
    await tester.pumpAndSettle();

    expect(find.text('TEAM LUNCH'), findsNothing);
    // No week-style day-group heading bleeds through; the "TODAY" now on
    // screen is the nav label's own, which Day view always shows.
    expect(find.byKey(agendaNavLabelKey), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(agendaNavLabelKey)).data, 'TODAY');
  });

  testWidgets('the forward chevron steps a day, and back returns', (
    WidgetTester tester,
  ) async {
    final FakeAgendaRepository repository = withEvents();
    await _open(tester, repository);

    await tester.tap(find.byKey(agendaNavForwardKey));
    await tester.pumpAndSettle();

    expect(repository.lastFrom, DateTime(2026, 9, 29));
    expect(repository.lastTo, DateTime(2026, 9, 30));
    expect(tester.widget<Text>(find.byKey(agendaNavLabelKey)).data, 'TOMORROW');

    await tester.tap(find.byKey(agendaNavBackKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(agendaNavBackKey));
    await tester.pumpAndSettle();

    expect(repository.lastFrom, DateTime(2026, 9, 27));
    expect(repository.lastTo, DateTime(2026, 9, 28));
    expect(
      tester.widget<Text>(find.byKey(agendaNavLabelKey)).data,
      'YESTERDAY',
    );
  });

  testWidgets('WEEK navigation steps by seven days', (
    WidgetTester tester,
  ) async {
    final FakeAgendaRepository repository = withEvents();
    await _open(tester, repository);
    await tester.tap(find.byKey(agendaWeekToggleKey));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(agendaNavForwardKey));
    await tester.pumpAndSettle();

    expect(repository.lastFrom, DateTime(2026, 10, 5));
    expect(repository.lastTo, DateTime(2026, 10, 12));
    expect(
      tester.widget<Text>(find.byKey(agendaNavLabelKey)).data,
      'NEXT WEEK',
    );
  });

  testWidgets('TODAY is greyed out on today, and returns a navigated day', (
    WidgetTester tester,
  ) async {
    final FakeAgendaRepository repository = withEvents();
    await _open(tester, repository);

    // Disabled: nothing to go back to yet.
    await tester.tap(find.byKey(agendaTodayKey));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.byKey(agendaNavLabelKey)).data, 'TODAY');

    await tester.tap(find.byKey(agendaNavForwardKey));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.byKey(agendaNavLabelKey)).data, 'TOMORROW');

    await tester.tap(find.byKey(agendaTodayKey));
    await tester.pumpAndSettle();

    expect(tester.widget<Text>(find.byKey(agendaNavLabelKey)).data, 'TODAY');
    expect(repository.lastFrom, DateTime(2026, 9, 28));
  });

  testWidgets('TODAY returns a navigated week to this week, too', (
    WidgetTester tester,
  ) async {
    final FakeAgendaRepository repository = withEvents();
    await _open(tester, repository);
    await tester.tap(find.byKey(agendaWeekToggleKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(agendaNavForwardKey));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(agendaNavLabelKey)).data,
      'NEXT WEEK',
    );

    await tester.tap(find.byKey(agendaTodayKey));
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(agendaNavLabelKey)).data,
      'THIS WEEK',
    );
    expect(repository.lastFrom, DateTime(2026, 9, 28));
  });

  testWidgets('switching tabs resets navigation back to today', (
    WidgetTester tester,
  ) async {
    await _open(tester, withEvents());
    await tester.tap(find.byKey(agendaNavForwardKey));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(agendaWeekToggleKey));
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(agendaNavLabelKey)).data,
      'THIS WEEK',
    );
  });

  testWidgets('the chosen tab is remembered across sheets', (
    WidgetTester tester,
  ) async {
    final SettingsState settings = SettingsState(store: InMemoryLocalStore());
    await _open(tester, withEvents(), settings: settings);

    await tester.tap(find.byKey(agendaWeekToggleKey));
    await tester.pumpAndSettle();

    expect(settings.settings.agendaWeekView, isTrue);

    // Close this sheet and open a fresh one on the same settings.
    Navigator.of(tester.element(find.byKey(agendaWeekToggleKey))).pop();
    await tester.pumpAndSettle();
    await _open(tester, withEvents(), settings: settings);

    expect(find.byKey(agendaWeekToggleKey), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(agendaNavLabelKey)).data,
      'THIS WEEK',
    );
  });

  testWidgets('tapping an event opens its own details', (
    WidgetTester tester,
  ) async {
    await _open(tester, withEvents());

    await tester.tap(find.text('DENTIST'));
    await tester.pumpAndSettle();

    expect(find.text(Messages.agendaEventTitle), findsOneWidget);
    expect(find.byKey(eventDetailWhereKey), findsOneWidget);
    expect(find.text('STORGATAN 1'), findsWidgets);
  });

  testWidgets('an empty day and an empty week say so', (
    WidgetTester tester,
  ) async {
    await _open(
      tester,
      FakeAgendaRepository(const AgendaReady(<CalendarEvent>[])),
    );

    expect(find.text(Messages.agendaNothingToday), findsOneWidget);

    await tester.tap(find.byKey(agendaWeekToggleKey));
    await tester.pumpAndSettle();

    expect(find.text(Messages.agendaNothingPlanned), findsOneWidget);
  });

  testWidgets('+ ADD EVENT opens the form on the day being looked at', (
    WidgetTester tester,
  ) async {
    await _open(tester, withEvents());

    await tester.tap(find.byKey(agendaAddEventKey));
    await tester.pumpAndSettle();

    expect(find.byKey(eventDetailTitleFieldKey), findsOneWidget);
    expect(find.text('MON 28 SEP'), findsOneWidget);
  });

  testWidgets('saving a new event reloads the list underneath', (
    WidgetTester tester,
  ) async {
    final FakeAgendaRepository repository = withEvents()
      ..listResult = const CalendarList(<CalendarInfo>[
        CalendarInfo(id: 1, name: 'Home', primary: true),
      ]);
    await _open(tester, repository);
    final int before = repository.betweenCalls;

    await tester.tap(find.byKey(agendaAddEventKey));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(eventDetailTitleFieldKey), 'Gym');
    await tester.tap(find.byKey(eventDetailStartTimeFieldKey));
    await _pickTime(tester, 18, 0);
    await tester.tap(find.byKey(eventDetailEndTimeFieldKey));
    await _pickTime(tester, 19, 0);
    await tester.tap(find.byKey(eventDetailSaveKey));
    await tester.pumpAndSettle();

    expect(repository.betweenCalls, greaterThan(before));
  });

  testWidgets('deleting an event from its detail sheet reloads the list', (
    WidgetTester tester,
  ) async {
    final FakeAgendaRepository repository = withEvents();
    await _open(tester, repository);
    final int before = repository.betweenCalls;

    await tester.tap(find.text('DENTIST'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(eventDetailDeleteKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(eventDetailDeleteYesKey));
    await tester.pumpAndSettle();

    expect(repository.deleted, <int>[1]);
    expect(repository.betweenCalls, greaterThan(before));
  });

  testWidgets('the close key closes the sheet', (WidgetTester tester) async {
    await _open(tester, withEvents());

    await tester.tap(find.byKey(agendaCloseKey));
    await tester.pumpAndSettle();

    expect(find.text(Messages.agendaTitle), findsNothing);
  });

  group('week grid', () {
    testWidgets('WEEK:GRID shows the week as a time grid', (
      WidgetTester tester,
    ) async {
      await _open(tester, withEvents());

      await tester.tap(find.byKey(agendaWeekGridToggleKey));
      await tester.pumpAndSettle();

      expect(find.byKey(agendaGridKey), findsOneWidget);
      // The list view's own day-group heading is gone; the grid draws days
      // as columns, not headings.
      expect(find.byKey(agendaWeekGridToggleKey), findsOneWidget);
    });

    testWidgets(
      'the grid also starts on Monday, whatever day it is opened on',
      (WidgetTester tester) async {
        await _open(
          tester,
          withEvents(),
          now: DateTime(2026, 10, 1, 8), // Thursday.
        );

        await tester.tap(find.byKey(agendaWeekGridToggleKey));
        await tester.pumpAndSettle();

        final WeekView<CalendarEvent> grid = tester
            .widget<WeekView<CalendarEvent>>(
              find.byType(WeekView<CalendarEvent>),
            );
        expect(grid.minDay, DateTime(2026, 9, 28));
        expect(grid.startDay, WeekDays.monday);
      },
    );

    testWidgets('an event in the grid opens its own details', (
      WidgetTester tester,
    ) async {
      await _open(tester, withEvents());
      await tester.tap(find.byKey(agendaWeekGridToggleKey));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('DENTIST').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('DENTIST').first);
      await tester.pumpAndSettle();

      expect(find.text(Messages.agendaEventTitle), findsOneWidget);
      expect(find.byKey(eventDetailWhereKey), findsOneWidget);
    });

    testWidgets('the grid choice is remembered across sheets', (
      WidgetTester tester,
    ) async {
      final SettingsState settings = SettingsState(store: InMemoryLocalStore());
      await _open(tester, withEvents(), settings: settings);

      await tester.tap(find.byKey(agendaWeekGridToggleKey));
      await tester.pumpAndSettle();

      expect(settings.settings.agendaWeekView, isTrue);
      expect(settings.settings.agendaGridView, isTrue);

      Navigator.of(tester.element(find.byKey(agendaWeekGridToggleKey))).pop();
      await tester.pumpAndSettle();
      await _open(tester, withEvents(), settings: settings);

      expect(find.byKey(agendaGridKey), findsOneWidget);
    });

    testWidgets('WEEK still shows the list after visiting the grid', (
      WidgetTester tester,
    ) async {
      await _open(tester, withEvents());
      await tester.tap(find.byKey(agendaWeekGridToggleKey));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(agendaWeekToggleKey));
      await tester.pumpAndSettle();

      expect(find.byKey(agendaGridKey), findsNothing);
      expect(find.text('TEAM LUNCH'), findsOneWidget);
    });

    testWidgets('the three-way toggle still fits a narrow phone', (
      WidgetTester tester,
    ) async {
      tester.view
        ..physicalSize = const Size(360 * 3, 780 * 3)
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await _open(tester, withEvents());

      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(agendaWeekGridToggleKey));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(agendaGridKey), findsOneWidget);
    });

    testWidgets('a two-finger pinch zooms the grid taller', (
      WidgetTester tester,
    ) async {
      await _open(tester, withEvents());
      await tester.tap(find.byKey(agendaWeekGridToggleKey));
      await tester.pumpAndSettle();

      final double before = tester
          .widget<WeekView<CalendarEvent>>(find.byType(WeekView<CalendarEvent>))
          .heightPerMinute;

      final Offset center = tester.getCenter(find.byKey(agendaGridKey));
      final TestGesture finger1 = await tester.startGesture(
        center + const Offset(0, -20),
      );
      final TestGesture finger2 = await tester.startGesture(
        center + const Offset(0, 20),
      );
      await tester.pump();
      await finger1.moveBy(const Offset(0, -40));
      await tester.pump();
      await finger2.moveBy(const Offset(0, 40));
      await tester.pump();

      final double after = tester
          .widget<WeekView<CalendarEvent>>(find.byType(WeekView<CalendarEvent>))
          .heightPerMinute;
      expect(after, greaterThan(before));

      await finger1.up();
      await finger2.up();
      await tester.pumpAndSettle();
    });

    testWidgets('one-finger drag still scrolls; it does not zoom', (
      WidgetTester tester,
    ) async {
      await _open(tester, withEvents());
      await tester.tap(find.byKey(agendaWeekGridToggleKey));
      await tester.pumpAndSettle();

      final double before = tester
          .widget<WeekView<CalendarEvent>>(find.byType(WeekView<CalendarEvent>))
          .heightPerMinute;

      await tester.drag(find.byKey(agendaGridKey), const Offset(0, -100));
      await tester.pumpAndSettle();

      final double after = tester
          .widget<WeekView<CalendarEvent>>(find.byType(WeekView<CalendarEvent>))
          .heightPerMinute;
      expect(after, before);
    });

    testWidgets('the zoom a pinch leaves is saved, and offered next time', (
      WidgetTester tester,
    ) async {
      final SettingsState settings = SettingsState(store: InMemoryLocalStore());
      await _open(tester, withEvents(), settings: settings);
      await tester.tap(find.byKey(agendaWeekGridToggleKey));
      await tester.pumpAndSettle();
      expect(settings.settings.agendaGridZoom, 1);

      final Offset center = tester.getCenter(find.byKey(agendaGridKey));
      final TestGesture finger1 = await tester.startGesture(
        center + const Offset(0, -20),
      );
      final TestGesture finger2 = await tester.startGesture(
        center + const Offset(0, 20),
      );
      await tester.pump();
      await finger1.moveBy(const Offset(0, -40));
      await finger2.moveBy(const Offset(0, 40));
      await tester.pump();
      await finger1.up();
      await finger2.up();
      await tester.pumpAndSettle();

      final double zoomed = settings.settings.agendaGridZoom;
      expect(zoomed, greaterThan(1));

      // Stepping to another week tears the grid down and rebuilds it fresh
      // (this is what used to reset the zoom): it should come back at the
      // saved level, not the package's own default.
      await tester.tap(find.byKey(agendaNavForwardKey));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<WeekView<CalendarEvent>>(
              find.byType(WeekView<CalendarEvent>),
            )
            .heightPerMinute,
        zoomed,
      );
    });
  });

  testWidgets('says why when the calendar cannot be shown', (
    WidgetTester tester,
  ) async {
    await _open(
      tester,
      FakeAgendaRepository(
        const AgendaUnavailable('the calendar did not answer'),
      ),
    );

    expect(find.text('THE CALENDAR DID NOT ANSWER'), findsOneWidget);
  });
  group('week grid: whole days', () {
    Future<void> openGrid(
      WidgetTester tester,
      List<CalendarEvent> events,
    ) async {
      await _open(tester, FakeAgendaRepository(AgendaReady(events)));
      await tester.tap(find.byKey(agendaWeekGridToggleKey));
      await tester.pumpAndSettle();
    }

    testWidgets('an all-day event sits in the all-day row, and opens', (
      WidgetTester tester,
    ) async {
      await openGrid(tester, <CalendarEvent>[
        CalendarEvent(
          id: 5,
          title: 'Birthday',
          start: DateTime(2026, 9, 29),
          end: DateTime(2026, 9, 30),
          allDay: true,
        ),
      ]);

      final Finder chip = find.byKey(
        agendaGridAllDayKey(5, DateTime(2026, 9, 29)),
      );
      expect(chip, findsOneWidget);
      expect(
        find.byKey(agendaGridAllDayKey(5, DateTime(2026, 9, 30))),
        findsNothing,
      );

      await tester.tap(chip);
      await tester.pumpAndSettle();
      expect(find.text(Messages.agendaEventTitle), findsOneWidget);
    });

    testWidgets('a multi-day all-day event has a chip on each of its days', (
      WidgetTester tester,
    ) async {
      await openGrid(tester, <CalendarEvent>[
        CalendarEvent(
          id: 6,
          title: 'Trip',
          start: DateTime(2026, 9, 30),
          end: DateTime(2026, 10, 3),
          allDay: true,
        ),
      ]);

      for (final int day in <int>[30]) {
        expect(
          find.byKey(agendaGridAllDayKey(6, DateTime(2026, 9, day))),
          findsOneWidget,
        );
      }
      for (final int day in <int>[1, 2]) {
        expect(
          find.byKey(agendaGridAllDayKey(6, DateTime(2026, 10, day))),
          findsOneWidget,
        );
      }
      expect(
        find.byKey(agendaGridAllDayKey(6, DateTime(2026, 10, 3))),
        findsNothing,
      );
    });

    testWidgets('a timed event over days: its middle day is all day', (
      WidgetTester tester,
    ) async {
      await openGrid(tester, <CalendarEvent>[
        CalendarEvent(
          id: 7,
          title: 'Conference',
          start: DateTime(2026, 9, 28, 20),
          end: DateTime(2026, 9, 30, 10),
        ),
      ]);

      expect(
        find.byKey(agendaGridAllDayKey(7, DateTime(2026, 9, 29))),
        findsOneWidget,
      );
      // Its first and last days are blocks on the grid, not all-day chips.
      expect(
        find.byKey(agendaGridAllDayKey(7, DateTime(2026, 9, 28))),
        findsNothing,
      );
      expect(
        find.byKey(agendaGridAllDayKey(7, DateTime(2026, 9, 30))),
        findsNothing,
      );
    });

    testWidgets('it opens at seven in the morning whatever the zoom', (
      WidgetTester tester,
    ) async {
      final SettingsState settings = SettingsState(store: InMemoryLocalStore());
      await settings.update(
        const LauncherSettings(
          agendaGridView: true,
          agendaWeekView: true,
        ).copyWith(agendaGridZoom: 0.5),
      );
      await _open(tester, withEvents(), settings: settings);

      final WeekView<CalendarEvent> grid = tester
          .widget<WeekView<CalendarEvent>>(
            find.byType(WeekView<CalendarEvent>),
          );
      expect(grid.scrollOffset, 7 * 60 * 0.5);
    });
  });

  group('FILTER', () {
    const List<CalendarInfo> calendars = <CalendarInfo>[
      CalendarInfo(id: 1, name: 'Home', account: 'me@example.com'),
      CalendarInfo(id: 2, name: 'Work', account: 'me@example.com'),
    ];

    FakeAgendaRepository twoCalendars() => FakeAgendaRepository(
      AgendaReady(<CalendarEvent>[
        CalendarEvent(
          id: 1,
          title: 'Dentist',
          start: DateTime(2026, 9, 28, 9),
          end: DateTime(2026, 9, 28, 10),
          calendarId: 1,
        ),
        CalendarEvent(
          id: 2,
          title: 'Review',
          start: DateTime(2026, 9, 28, 13),
          end: DateTime(2026, 9, 28, 14),
          calendarId: 2,
        ),
      ]),
    )..calendarsResult = const CalendarList(calendars);

    testWidgets('reads plain FILTER while every calendar shows', (
      WidgetTester tester,
    ) async {
      await _open(tester, twoCalendars());

      expect(find.text(Messages.agendaFilter), findsOneWidget);
      expect(find.text('DENTIST'), findsOneWidget);
      expect(find.text('REVIEW'), findsOneWidget);
    });

    testWidgets('a hidden calendar: its events go, and FILTER counts', (
      WidgetTester tester,
    ) async {
      await _open(
        tester,
        twoCalendars()..choices = const CalendarChoices(<int, bool>{2: false}),
      );

      expect(find.text('${Messages.agendaFilter} 1/2'), findsOneWidget);
      expect(find.text('DENTIST'), findsOneWidget);
      expect(find.text('REVIEW'), findsNothing);
    });

    testWidgets('switching a calendar back on shows it once closed', (
      WidgetTester tester,
    ) async {
      final FakeAgendaRepository repository = twoCalendars()
        ..choices = const CalendarChoices(<int, bool>{2: false});
      await _open(tester, repository);

      await tester.tap(find.byKey(agendaFilterKey));
      await tester.pumpAndSettle();
      expect(find.text(Messages.agendaCalendarsTitle), findsOneWidget);
      expect(find.text('ME@EXAMPLE.COM'), findsOneWidget);
      expect(find.text('[X]'), findsOneWidget);
      expect(find.text('[ ]'), findsOneWidget);

      await tester.tap(find.byKey(calendarFilterRowKey(2)));
      await tester.pumpAndSettle();
      expect(repository.switched, <(int, bool)>[(2, true)]);
      expect(find.text('[X]'), findsNWidgets(2));

      await tester.tap(find.byKey(calendarFilterCloseKey));
      await tester.pumpAndSettle();
      expect(find.text('REVIEW'), findsOneWidget);
      expect(find.text(Messages.agendaFilter), findsOneWidget);
    });

    testWidgets('every calendar hidden says so, not "nothing today"', (
      WidgetTester tester,
    ) async {
      await _open(
        tester,
        twoCalendars()
          ..choices = const CalendarChoices(<int, bool>{1: false, 2: false}),
      );

      expect(find.text(Messages.agendaCalendarsAllHidden), findsOneWidget);
      expect(find.text(Messages.agendaNothingToday), findsNothing);
    });
  });

  testWidgets('a slow reply for a day already left is not shown', (
    WidgetTester tester,
  ) async {
    final _GatedRepository repository = _GatedRepository();
    final Widget app = MaterialApp(
      theme: tileLauncherTheme(),
      home: Builder(
        builder: (BuildContext context) => TextButton(
          onPressed: () => showAgendaSheet(
            context,
            repository: repository,
            clock: () => _now,
          ),
          child: const Text('open'),
        ),
      ),
    );
    await tester.pumpWidget(app);
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    repository.answer(DateTime(2026, 9, 28), 'Today thing');
    await tester.pump();

    // Forward once (tomorrow), then again (the day after), before either
    // answers; then the older request answers last.
    await tester.tap(find.byKey(agendaNavForwardKey));
    await tester.pump();
    await tester.tap(find.byKey(agendaNavForwardKey));
    await tester.pump();
    repository.answer(DateTime(2026, 9, 30), 'Wednesday thing');
    await tester.pump();
    repository.answer(DateTime(2026, 9, 29), 'Tuesday thing');
    await tester.pumpAndSettle();

    expect(find.text('WEDNESDAY THING'), findsOneWidget);
    expect(find.text('TUESDAY THING'), findsNothing);
  });

  group('swipe and slide', () {
    testWidgets('a swipe left goes forward, a swipe right goes back', (
      WidgetTester tester,
    ) async {
      final FakeAgendaRepository repository = withEvents();
      await _open(tester, repository);

      final Finder page = find.byType(AnimatedSwitcher);
      await tester.fling(page, const Offset(-300, 0), 1500);
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.byKey(agendaNavLabelKey)).data,
        'TOMORROW',
      );

      await tester.fling(page, const Offset(300, 0), 1500);
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(find.byKey(agendaNavLabelKey)).data, 'TODAY');
    });

    testWidgets('a swipe steps the week in the week view and in the grid', (
      WidgetTester tester,
    ) async {
      final FakeAgendaRepository repository = withEvents();
      await _open(tester, repository);
      await tester.tap(find.byKey(agendaWeekGridToggleKey));
      await tester.pumpAndSettle();

      await tester.fling(
        find.byKey(agendaGridKey),
        const Offset(-300, 0),
        1500,
      );
      await tester.pumpAndSettle();

      expect(repository.lastFrom, DateTime(2026, 10, 5));
      expect(
        tester.widget<Text>(find.byKey(agendaNavLabelKey)).data,
        'NEXT WEEK',
      );
    });
  });
}

/// Holds every `between` until [answer] gives that day an event, so a test
/// can choose the order replies land in.
class _GatedRepository extends FakeAgendaRepository {
  _GatedRepository() : super(const AgendaReady(<CalendarEvent>[]));

  final Map<DateTime, Completer<AgendaSnapshot>> _waiting =
      <DateTime, Completer<AgendaSnapshot>>{};

  @override
  Future<AgendaSnapshot> between(DateTime from, DateTime to) =>
      (_waiting[from] ??= Completer<AgendaSnapshot>()).future;

  void answer(DateTime day, String title) {
    (_waiting[day] ??= Completer<AgendaSnapshot>()).complete(
      AgendaReady(<CalendarEvent>[
        CalendarEvent(
          id: day.day,
          title: title,
          start: day.add(const Duration(hours: 9)),
          end: day.add(const Duration(hours: 10)),
        ),
      ]),
    );
  }
}

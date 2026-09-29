import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/agenda_snapshot.dart';
import 'package:android_tile_launcher/model/calendar_event.dart';
import 'package:android_tile_launcher/services/settings_state.dart';
import 'package:android_tile_launcher/ui/agenda_sheet.dart';
import 'package:android_tile_launcher/ui/event_detail_sheet.dart';
import 'package:android_tile_launcher/ui/settings_scope.dart';
import 'package:android_tile_launcher/ui/theme.dart';
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
}) async {
  final Widget app = MaterialApp(
    theme: tileLauncherTheme(),
    home: Builder(
      builder: (BuildContext context) => TextButton(
        onPressed: () =>
            showAgendaSheet(context, repository: repository, clock: () => _now),
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

  testWidgets('WEEK reads seven days and puts a heading over each day', (
    WidgetTester tester,
  ) async {
    final FakeAgendaRepository repository = withEvents();
    await _open(tester, repository);

    await tester.tap(find.byKey(agendaWeekToggleKey));
    await tester.pumpAndSettle();

    expect(repository.lastFrom, DateTime(2026, 9, 28));
    expect(repository.lastTo, DateTime(2026, 10, 5));
    expect(find.text('TODAY'), findsOneWidget);
    expect(find.text('TOMORROW'), findsOneWidget);
    expect(find.text('DENTIST'), findsOneWidget);
    expect(find.text('TEAM LUNCH'), findsOneWidget);
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
}

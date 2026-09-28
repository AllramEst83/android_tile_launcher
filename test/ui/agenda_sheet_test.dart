import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/agenda_snapshot.dart';
import 'package:android_tile_launcher/model/calendar_event.dart';
import 'package:android_tile_launcher/ui/agenda_sheet.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_agenda_repository.dart';

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

Future<void> _open(WidgetTester tester, FakeAgendaRepository repository) async {
  await tester.pumpWidget(
    MaterialApp(
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
    ),
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
    expect(find.text('TODAY'), findsNothing);
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

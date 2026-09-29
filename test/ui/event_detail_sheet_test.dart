import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/calendar_event.dart';
import 'package:android_tile_launcher/ui/event_detail_sheet.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _open(
  WidgetTester tester,
  CalendarEvent event, {
  DateTime? day,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: tileLauncherTheme(),
      home: Builder(
        builder: (BuildContext context) => TextButton(
          onPressed: () => showEventDetailSheet(
            context,
            event: event,
            day:
                day ??
                DateTime(event.start.year, event.start.month, event.start.day),
          ),
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the title, when, where and about', (
    WidgetTester tester,
  ) async {
    await _open(
      tester,
      CalendarEvent(
        id: 1,
        title: 'Dentist',
        start: DateTime(2026, 9, 28, 14, 30),
        end: DateTime(2026, 9, 28, 15),
        location: 'Storgatan 1',
        description: 'Bring the insurance card',
      ),
    );

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
      CalendarEvent(
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
      CalendarEvent(
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
      CalendarEvent(
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
      CalendarEvent(
        id: 1,
        title: 'Holiday',
        start: DateTime(2026, 9, 28),
        end: DateTime(2026, 9, 29),
        allDay: true,
      ),
    );

    expect(find.textContaining('ALL DAY'), findsOneWidget);
  });

  testWidgets('X closes the sheet', (WidgetTester tester) async {
    await _open(
      tester,
      CalendarEvent(
        id: 1,
        title: 'Dentist',
        start: DateTime(2026, 9, 28, 9),
        end: DateTime(2026, 9, 28, 10),
      ),
    );
    expect(find.text(Messages.agendaEventTitle), findsOneWidget);

    await tester.tap(find.byKey(eventDetailCloseKey));
    await tester.pumpAndSettle();

    expect(find.text(Messages.agendaEventTitle), findsNothing);
  });
}

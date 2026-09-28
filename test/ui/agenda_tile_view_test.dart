import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/agenda_snapshot.dart';
import 'package:android_tile_launcher/model/calendar_event.dart';
import 'package:android_tile_launcher/ui/agenda_tile_view.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Monday 28 September 2026, half past ten.
final DateTime _now = DateTime(2026, 9, 28, 10, 30);

CalendarEvent _event(
  int id,
  String title,
  DateTime start, {
  String? location,
  bool allDay = false,
}) => CalendarEvent(
  id: id,
  title: title,
  start: start,
  end: allDay
      ? DateTime(start.year, start.month, start.day + 1)
      : start.add(const Duration(hours: 1)),
  allDay: allDay,
  location: location,
);

final List<CalendarEvent> _events = <CalendarEvent>[
  _event(1, 'Dentist', DateTime(2026, 9, 28, 14, 30), location: 'Storgatan 1'),
  _event(2, 'Team lunch', DateTime(2026, 9, 29, 12)),
  _event(3, 'Gym', DateTime(2026, 9, 30, 18)),
];

Future<void> _pump(
  WidgetTester tester,
  AgendaSnapshot snapshot, {
  Size size = const Size(185, 185),
  VoidCallback? onTap,
}) => tester.pumpWidget(
  MaterialApp(
    theme: tileLauncherTheme(),
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: AgendaTileContentView(
            snapshot: snapshot,
            now: _now,
            ink: Colors.white,
            onTap: onTap,
          ),
        ),
      ),
    ),
  ),
);

void main() {
  group('with events', () {
    testWidgets('medium: when, what, where, and how many more', (
      WidgetTester tester,
    ) async {
      await _pump(tester, AgendaReady(_events));

      expect(find.byKey(agendaNextKey), findsOneWidget);
      expect(find.text('14:30'), findsOneWidget);
      expect(find.text('DENTIST'), findsOneWidget);
      expect(find.text('STORGATAN 1'), findsOneWidget);
      expect(find.text('+2 MORE'), findsOneWidget);
    });

    testWidgets('small: just when and what', (WidgetTester tester) async {
      await _pump(tester, AgendaReady(_events), size: const Size(90, 90));

      expect(find.text('14:30'), findsOneWidget);
      expect(find.text('DENTIST'), findsOneWidget);
      expect(find.text('STORGATAN 1'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('wide: a line for each coming event, the day when not today', (
      WidgetTester tester,
    ) async {
      await _pump(tester, AgendaReady(_events), size: const Size(380, 185));

      expect(find.byKey(agendaRowKey(0)), findsOneWidget);
      expect(find.byKey(agendaRowKey(2)), findsOneWidget);
      expect(find.text('14:30'), findsOneWidget);
      expect(find.text('TUE 12:00'), findsOneWidget);
      expect(find.text('TEAM LUNCH'), findsOneWidget);
      expect(find.text('WED 18:00'), findsOneWidget);
    });

    testWidgets('wide: only as many lines as the height holds', (
      WidgetTester tester,
    ) async {
      final List<CalendarEvent> many = <CalendarEvent>[
        for (int i = 0; i < 20; i++)
          _event(
            i,
            'Event $i',
            DateTime(2026, 9, 28, 11).add(Duration(hours: i)),
          ),
      ];

      await _pump(tester, AgendaReady(many), size: const Size(380, 100));

      expect(find.byKey(agendaRowKey(0)), findsOneWidget);
      expect(find.byKey(agendaRowKey(19)), findsNothing);
      expect(find.textContaining('+'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an event under way says NOW', (WidgetTester tester) async {
      await _pump(
        tester,
        AgendaReady(<CalendarEvent>[
          _event(1, 'Standup', DateTime(2026, 9, 28, 10)),
        ]),
      );

      expect(find.text('NOW'), findsOneWidget);
    });

    testWidgets('leads with a meeting rather than an all-day event', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        AgendaReady(<CalendarEvent>[
          _event(1, 'Birthday', DateTime(2026, 9, 28), allDay: true),
          ..._events,
        ]),
      );

      expect(find.text('DENTIST'), findsOneWidget);
      expect(find.text('BIRTHDAY'), findsNothing);
    });

    testWidgets('an event with no title still shows something', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        AgendaReady(<CalendarEvent>[_event(1, '', DateTime(2026, 9, 28, 14))]),
      );

      expect(find.text(Messages.agendaUntitled), findsOneWidget);
    });
  });

  group('without events', () {
    testWidgets('an empty week says so', (WidgetTester tester) async {
      await _pump(tester, const AgendaReady(<CalendarEvent>[]));

      expect(find.text(Messages.agendaNothingPlanned), findsOneWidget);
    });

    testWidgets('no access yet: offers to allow the calendar', (
      WidgetTester tester,
    ) async {
      await _pump(tester, const AgendaNeedsPermission());

      expect(find.text(Messages.agendaTapToAllow), findsOneWidget);
    });

    testWidgets('refused but askable: offers to allow it', (
      WidgetTester tester,
    ) async {
      await _pump(tester, const AgendaDenied(permanent: false));

      expect(find.text(Messages.agendaTapToAllow), findsOneWidget);
    });

    testWidgets('refused for good: says where the setting is', (
      WidgetTester tester,
    ) async {
      await _pump(tester, const AgendaDenied(permanent: true));

      expect(find.text(Messages.agendaAllowInSettings), findsOneWidget);
    });

    testWidgets('unreadable: says why and offers a retry', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        const AgendaUnavailable('the calendar did not answer'),
      );

      expect(find.text('THE CALENDAR DID NOT ANSWER'), findsOneWidget);
      expect(find.text(Messages.agendaTapToRetry), findsOneWidget);
    });
  });

  group('taps', () {
    testWidgets('anywhere on the tile calls onTap', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      await _pump(tester, const AgendaNeedsPermission(), onTap: () => taps++);

      final Rect tile = tester.getRect(find.byType(AgendaTileContentView));
      await tester.tapAt(tile.centerRight - const Offset(5, 0));
      await tester.tapAt(tile.bottomLeft + const Offset(5, -5));

      expect(taps, 2);
    });

    testWidgets('without onTap there is nothing to tap', (
      WidgetTester tester,
    ) async {
      await _pump(tester, const AgendaNeedsPermission());

      expect(find.byType(GestureDetector), findsNothing);
    });
  });
}

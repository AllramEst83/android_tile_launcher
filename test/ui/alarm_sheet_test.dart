import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/services/alarm_service.dart';
import 'package:android_tile_launcher/ui/alarm_pad.dart';
import 'package:android_tile_launcher/ui/alarm_sheet.dart';
import 'package:android_tile_launcher/ui/alarm_tile_view.dart';
import 'package:android_tile_launcher/ui/digit_pad.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:android_tile_launcher/ui/timer_pad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_alarm_service.dart';

// Monday 28 September 2026, half past ten.
final DateTime _now = DateTime(2026, 9, 28, 10, 30);

Future<void> _open(
  WidgetTester tester,
  FakeAlarmService alarm, {
  bool alarmTab = false,
}) async {
  tester.view
    ..physicalSize = const Size(400, 1000)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: tileLauncherTheme(),
      home: Builder(
        builder: (BuildContext context) => TextButton(
          onPressed: () => showAlarmSheet(
            context,
            alarm: alarm,
            alarmTab: alarmTab,
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

Future<void> _digits(WidgetTester tester, String prefix, String digits) async {
  for (final int d in digits.codeUnits.map((int c) => c - 48)) {
    await tester.tap(find.byKey(DigitPad.digitKey(prefix, d)));
    await tester.pump();
  }
}

/// Taps a chip, scrolling its row to it first as a thumb would.
Future<void> _chip(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.pump();
  await tester.tap(find.byKey(key));
  await tester.pump();
}

String _text(WidgetTester tester, Key key) =>
    tester.widget<Text>(find.byKey(key)).data!;

void main() {
  group('the sheet', () {
    testWidgets('opens on the timer, with tabs and a close key', (
      WidgetTester tester,
    ) async {
      await _open(tester, FakeAlarmService());

      expect(find.byKey(alarmTabTimerKey), findsOneWidget);
      expect(find.byKey(alarmTabAlarmKey), findsOneWidget);
      expect(find.byKey(alarmCloseKey), findsOneWidget);
      expect(find.byKey(timerDisplayKey), findsOneWidget);
    });

    testWidgets('can open on the alarm', (WidgetTester tester) async {
      await _open(tester, FakeAlarmService(), alarmTab: true);

      expect(find.byKey(alarmDisplayKey).hitTestable(), findsOneWidget);
    });

    testWidgets('the close key closes it', (WidgetTester tester) async {
      await _open(tester, FakeAlarmService());

      await tester.tap(find.byKey(alarmCloseKey));
      await tester.pumpAndSettle();

      expect(find.byKey(alarmCloseKey), findsNothing);
    });

    testWidgets('switching tabs keeps what was keyed on each', (
      WidgetTester tester,
    ) async {
      await _open(tester, FakeAlarmService());
      await _digits(tester, timerPadPrefix, '1000');

      await tester.tap(find.byKey(alarmTabAlarmKey));
      await tester.pump();
      await _digits(tester, alarmPadPrefix, '07');
      await tester.tap(find.byKey(alarmTabTimerKey));
      await tester.pump();

      expect(_text(tester, timerDisplayKey), '00:10:00');

      await tester.tap(find.byKey(alarmTabAlarmKey));
      await tester.pump();
      expect(_text(tester, alarmDisplayKey), '07:--');
    });
  });

  group('the timer', () {
    testWidgets('digits shift in like a microwave', (
      WidgetTester tester,
    ) async {
      await _open(tester, FakeAlarmService());
      expect(_text(tester, timerDisplayKey), '00:00:00');

      await _digits(tester, timerPadPrefix, '130');

      expect(_text(tester, timerDisplayKey), '00:01:30');
    });

    testWidgets('START waits for a length, then starts it and says so', (
      WidgetTester tester,
    ) async {
      final FakeAlarmService alarm = FakeAlarmService();
      await _open(tester, alarm);

      await tester.tap(find.byKey(timerStartKey));
      await tester.pump();
      expect(alarm.timers, isEmpty);

      await _digits(tester, timerPadPrefix, '1000');
      await tester.tap(find.byKey(timerStartKey));
      await tester.pumpAndSettle();

      expect(alarm.timers, <Duration>[const Duration(minutes: 10)]);
      expect(_text(tester, timerStatusKey), 'TIMER STARTED: 10 MIN');
    });

    testWidgets('a preset fills in its length; nothing starts until START', (
      WidgetTester tester,
    ) async {
      final FakeAlarmService alarm = FakeAlarmService();
      await _open(tester, alarm);

      await _chip(tester, timerPresetKey(5));

      expect(_text(tester, timerDisplayKey), '00:05:00');
      expect(alarm.timers, isEmpty);

      await tester.tap(find.byKey(timerStartKey));
      await tester.pumpAndSettle();
      expect(alarm.timers, <Duration>[const Duration(minutes: 5)]);
    });

    testWidgets('the hour preset', (WidgetTester tester) async {
      await _open(tester, FakeAlarmService());

      await _chip(tester, timerPresetKey(60));

      expect(_text(tester, timerDisplayKey), '01:00:00');
    });

    testWidgets('a preset can be added to', (WidgetTester tester) async {
      await _open(tester, FakeAlarmService());
      await _chip(tester, timerPresetKey(5));

      await _digits(tester, timerPadPrefix, '0');

      expect(_text(tester, timerDisplayKey), '00:50:00');
    });

    testWidgets('more than 24 hours says so and cannot be started', (
      WidgetTester tester,
    ) async {
      final FakeAlarmService alarm = FakeAlarmService();
      await _open(tester, alarm);
      await _digits(tester, timerPadPrefix, '250000');

      expect(find.text(Messages.alarmTooLong), findsOneWidget);
      await tester.tap(find.byKey(timerStartKey));
      await tester.pump();
      expect(alarm.timers, isEmpty);
    });

    testWidgets('DEL and C edit the length', (WidgetTester tester) async {
      await _open(tester, FakeAlarmService());
      await _digits(tester, timerPadPrefix, '123');

      await tester.tap(find.byKey(DigitPad.deleteKey(timerPadPrefix)));
      await tester.pump();
      expect(_text(tester, timerDisplayKey), '00:00:12');

      await tester.tap(find.byKey(DigitPad.clearKey(timerPadPrefix)));
      await tester.pump();
      expect(_text(tester, timerDisplayKey), '00:00:00');
    });

    testWidgets('a clock app that cannot be reached says why', (
      WidgetTester tester,
    ) async {
      final FakeAlarmService alarm = FakeAlarmService()
        ..result = const AlarmUnavailable('no clock app found');
      await _open(tester, alarm);
      await _digits(tester, timerPadPrefix, '500');

      await tester.tap(find.byKey(timerStartKey));
      await tester.pumpAndSettle();

      expect(_text(tester, timerStatusKey), 'FAILED: NO CLOCK APP FOUND');
    });

    testWidgets('SEE TIMERS opens the clock app\'s list', (
      WidgetTester tester,
    ) async {
      final FakeAlarmService alarm = FakeAlarmService();
      await _open(tester, alarm);

      await tester.tap(find.byKey(timerSeeKey));
      await tester.pumpAndSettle();

      expect(alarm.timerLists, 1);
    });
  });

  group('the alarm', () {
    Future<void> alarmTab(WidgetTester tester, FakeAlarmService alarm) =>
        _open(tester, alarm, alarmTab: true);

    testWidgets('a time is keyed left to right, with dashes for the rest', (
      WidgetTester tester,
    ) async {
      await alarmTab(tester, FakeAlarmService());
      expect(_text(tester, alarmDisplayKey), '--:--');

      await _digits(tester, alarmPadPrefix, '073');

      expect(_text(tester, alarmDisplayKey), '07:3-');
      expect(find.byKey(alarmNextKey), findsNothing);
    });

    testWidgets('a digit that makes no time is ignored', (
      WidgetTester tester,
    ) async {
      await alarmTab(tester, FakeAlarmService());

      await _digits(tester, alarmPadPrefix, '9');
      expect(_text(tester, alarmDisplayKey), '--:--');
      await _digits(tester, alarmPadPrefix, '25');
      expect(_text(tester, alarmDisplayKey), '2-:--');
    });

    testWidgets('says when a once-only alarm will ring', (
      WidgetTester tester,
    ) async {
      await alarmTab(tester, FakeAlarmService());

      await _digits(tester, alarmPadPrefix, '0730');
      expect(_text(tester, alarmNextKey), 'NEXT: TOMORROW 07:30');

      await tester.tap(find.byKey(DigitPad.clearKey(alarmPadPrefix)));
      await tester.pump();
      await _digits(tester, alarmPadPrefix, '1800');
      expect(_text(tester, alarmNextKey), 'NEXT: TODAY 18:00');
    });

    testWidgets('SET ALARM waits for all four digits, then sets it', (
      WidgetTester tester,
    ) async {
      final FakeAlarmService alarm = FakeAlarmService();
      await alarmTab(tester, alarm);
      await _digits(tester, alarmPadPrefix, '073');

      await tester.tap(find.byKey(alarmSetKey));
      await tester.pump();
      expect(alarm.alarms, isEmpty);

      await _digits(tester, alarmPadPrefix, '0');
      await tester.tap(find.byKey(alarmSetKey));
      await tester.pumpAndSettle();

      expect(alarm.alarms, hasLength(1));
      expect(alarm.alarms.single.$1, 7);
      expect(alarm.alarms.single.$2, 30);
      expect(alarm.alarms.single.$3, isEmpty);
      expect(_text(tester, alarmStatusKey), 'ALARM SET: TOMORROW 07:30');
    });

    testWidgets('days chosen make it repeat, in order', (
      WidgetTester tester,
    ) async {
      final FakeAlarmService alarm = FakeAlarmService();
      await alarmTab(tester, alarm);
      await _digits(tester, alarmPadPrefix, '0645');

      await _chip(tester, alarmDayKey(5));
      await _chip(tester, alarmDayKey(1));
      await _chip(tester, alarmDayKey(3));
      expect(_text(tester, alarmNextKey), 'NEXT: MON WED FRI 06:45');

      await tester.tap(find.byKey(alarmSetKey));
      await tester.pumpAndSettle();

      expect(alarm.alarms.single.$1, 6);
      expect(alarm.alarms.single.$2, 45);
      expect(alarm.alarms.single.$3, <int>[1, 3, 5]);
    });

    testWidgets('tapping a chosen day again takes it off', (
      WidgetTester tester,
    ) async {
      await alarmTab(tester, FakeAlarmService());
      await _digits(tester, alarmPadPrefix, '0645');
      await _chip(tester, alarmDayKey(2));
      await _chip(tester, alarmDayKey(2));

      expect(_text(tester, alarmNextKey), startsWith('NEXT: TOMORROW'));
    });

    testWidgets('the shortcuts choose several days, and ONCE none', (
      WidgetTester tester,
    ) async {
      final FakeAlarmService alarm = FakeAlarmService();
      await alarmTab(tester, alarm);
      await _digits(tester, alarmPadPrefix, '0700');

      await _chip(tester, alarmRepeatKey(Messages.alarmWeekdays));
      expect(_text(tester, alarmNextKey), 'NEXT: MON-FRI 07:00');

      await _chip(tester, alarmRepeatKey(Messages.alarmWeekend));
      expect(_text(tester, alarmNextKey), 'NEXT: SAT SUN 07:00');

      await _chip(tester, alarmRepeatKey(Messages.alarmDaily));
      expect(_text(tester, alarmNextKey), 'NEXT: DAILY 07:00');

      await _chip(tester, alarmRepeatKey(Messages.alarmOnce));
      expect(_text(tester, alarmNextKey), startsWith('NEXT: TOMORROW'));
    });

    testWidgets('a clock app that cannot be reached says why', (
      WidgetTester tester,
    ) async {
      final FakeAlarmService alarm = FakeAlarmService()
        ..result = const AlarmUnavailable(
          'not allowed to set alarms (check app permissions)',
        );
      await alarmTab(tester, alarm);
      await _digits(tester, alarmPadPrefix, '0730');

      await tester.tap(find.byKey(alarmSetKey));
      await tester.pumpAndSettle();

      expect(
        _text(tester, alarmStatusKey),
        'FAILED: NOT ALLOWED TO SET ALARMS (CHECK APP PERMISSIONS)',
      );
    });

    testWidgets('SEE ALARMS opens the clock app\'s list', (
      WidgetTester tester,
    ) async {
      final FakeAlarmService alarm = FakeAlarmService();
      await alarmTab(tester, alarm);

      await tester.tap(find.byKey(alarmSeeKey));
      await tester.pumpAndSettle();

      expect(alarm.alarmLists, 1);
    });
  });

  group('the tile', () {
    testWidgets('names itself and calls onTap', (WidgetTester tester) async {
      int taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: tileLauncherTheme(),
          home: Scaffold(
            body: SizedBox(
              width: 380,
              height: 185,
              child: AlarmTileContentView(
                ink: Colors.white,
                onTap: () => taps++,
              ),
            ),
          ),
        ),
      );

      expect(find.text(Messages.alarmTitle), findsOneWidget);
      await tester.tap(find.byType(AlarmTileContentView));
      expect(taps, 1);
    });

    testWidgets('small: still fits', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: tileLauncherTheme(),
          home: const Scaffold(
            body: SizedBox(
              width: 90,
              height: 90,
              child: AlarmTileContentView(ink: Colors.white),
            ),
          ),
        ),
      );

      expect(find.text(Messages.alarmTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('without onTap there is nothing to tap', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: tileLauncherTheme(),
          home: const Scaffold(
            body: SizedBox(
              width: 380,
              height: 185,
              child: AlarmTileContentView(ink: Colors.white),
            ),
          ),
        ),
      );

      expect(find.byType(GestureDetector), findsNothing);
    });
  });
}

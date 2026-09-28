import 'package:android_tile_launcher/model/settings.dart';
import 'package:android_tile_launcher/services/settings_state.dart';
import 'package:android_tile_launcher/ui/grouped_list.dart';
import 'package:android_tile_launcher/ui/settings_scope.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/in_memory_local_store.dart';

const Key _strip = Key('strip');

final List<String> _alphabet = <String>[
  for (int c = 'A'.codeUnitAt(0); c <= 'Z'.codeUnitAt(0); c++)
    String.fromCharCode(c),
];

List<String> _buzzes = <String>[];

void _recordHaptics(WidgetTester tester) {
  _buzzes = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (MethodCall call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        _buzzes.add(call.arguments as String? ?? 'default');
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
}

Future<List<int>> _pump(
  WidgetTester tester, {
  List<String>? initials,
  double height = 780,
  bool haptics = true,
}) async {
  tester.view
    ..physicalSize = const Size(400, 1000)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final List<int> jumps = <int>[];
  final SettingsState settings = SettingsState(store: InMemoryLocalStore());
  await settings.update(LauncherSettings(haptics: haptics));
  await tester.pumpWidget(
    SettingsScope(
      state: settings,
      child: MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topRight,
            child: SizedBox(
              height: height,
              child: JumpIndex(
                key: _strip,
                initials: initials ?? _alphabet,
                onTap: jumps.add,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  return jumps;
}

/// A finger has to rest a moment before a touch counts as a tap on a letter,
/// then the wave takes a moment to grow.
Future<void> _settleWave(WidgetTester tester) async {
  await tester.pump(kPressTimeout + const Duration(milliseconds: 10));
  await tester.pump(const Duration(milliseconds: 200));
}

double _y(WidgetTester tester, String letter) =>
    tester.getCenter(find.text(letter)).dy;

double _x(WidgetTester tester, String letter) =>
    tester.getCenter(find.text(letter)).dx;

/// How much bigger than at rest the letter is drawn (layout size does not
/// change with a scale, so read the scale itself).
double _width(WidgetTester tester, String letter) => tester
    .widgetList<Transform>(
      find.ancestor(of: find.text(letter), matching: find.byType(Transform)),
    )
    .map((Transform t) => t.transform.storage[0])
    .reduce((double a, double b) => a > b ? a : b);

void main() {
  group('spread', () {
    testWidgets('the letters share the whole height, evenly', (
      WidgetTester tester,
    ) async {
      await _pump(tester, height: 780);

      // 26 letters in 780: 30 a letter.
      expect(_y(tester, 'B') - _y(tester, 'A'), closeTo(30, 0.5));
      expect(_y(tester, 'Z') - _y(tester, 'A'), closeTo(30 * 25, 1));
      expect(_y(tester, 'A'), closeTo(15, 1));
    });

    testWidgets('never more than the largest row, and then centred', (
      WidgetTester tester,
    ) async {
      await _pump(tester, initials: <String>['A', 'B', 'C'], height: 800);

      expect(
        _y(tester, 'B') - _y(tester, 'A'),
        closeTo(JumpIndex.maxRowHeight, 0.5),
      );
      // Three rows in the middle of 800: the middle one on the middle line.
      expect(_y(tester, 'B'), closeTo(400, 1));
    });

    testWidgets('a short strip squeezes them so every letter fits', (
      WidgetTester tester,
    ) async {
      await _pump(tester, height: 260);

      expect(_y(tester, 'B') - _y(tester, 'A'), closeTo(10, 0.5));
      expect(_y(tester, 'Z'), lessThan(260));
    });

    testWidgets('a tap lands on the letter drawn there', (
      WidgetTester tester,
    ) async {
      final List<int> jumps = await _pump(tester, height: 780);

      final Offset top = tester.getTopLeft(find.byKey(_strip));
      for (final int letter in <int>[0, 7, 13, 25]) {
        await tester.tapAt(Offset(top.dx + 12, top.dy + 30 * letter + 15));
        await tester.pump();
      }

      expect(jumps, <int>[0, 7, 13, 25]);
    });

    testWidgets('a tap above or below the letters takes the nearest one', (
      WidgetTester tester,
    ) async {
      final List<int> jumps = await _pump(
        tester,
        initials: <String>['A', 'B', 'C'],
        height: 800,
      );

      final Offset top = tester.getTopLeft(find.byKey(_strip));
      await tester.tapAt(Offset(top.dx + 12, top.dy + 2));
      await tester.pump();
      await tester.tapAt(Offset(top.dx + 12, top.dy + 798));
      await tester.pump();

      expect(jumps, <int>[0, 2]);
    });
  });

  group('scrubbing', () {
    testWidgets('each letter passed over jumps once, in order', (
      WidgetTester tester,
    ) async {
      final List<int> jumps = await _pump(tester, height: 780);
      final Offset top = tester.getTopLeft(find.byKey(_strip));

      final TestGesture finger = await tester.startGesture(
        Offset(top.dx + 12, top.dy + 5),
      );
      for (double y = 10; y < 130; y += 6) {
        await finger.moveTo(Offset(top.dx + 12, top.dy + y));
        await tester.pump();
      }
      await finger.up();
      await tester.pumpAndSettle();

      expect(jumps, <int>[0, 1, 2, 3, 4]);
    });

    testWidgets('a tick for each new letter, and none for staying on one', (
      WidgetTester tester,
    ) async {
      _recordHaptics(tester);
      await _pump(tester, height: 780);
      final Offset top = tester.getTopLeft(find.byKey(_strip));

      final TestGesture finger = await tester.startGesture(
        Offset(top.dx + 12, top.dy + 5),
      );
      // Held long enough to count as a touch on the first letter.
      await tester.pump(kPressTimeout + const Duration(milliseconds: 10));
      await finger.moveTo(Offset(top.dx + 12, top.dy + 10));
      await finger.moveTo(Offset(top.dx + 12, top.dy + 40));
      await finger.moveTo(Offset(top.dx + 12, top.dy + 44));
      await finger.up();
      await tester.pumpAndSettle();

      expect(_buzzes, <String>[
        'HapticFeedbackType.selectionClick',
        'HapticFeedbackType.selectionClick',
      ]);
    });

    testWidgets('no ticks with haptics switched off', (
      WidgetTester tester,
    ) async {
      _recordHaptics(tester);
      await _pump(tester, height: 780, haptics: false);
      final Offset top = tester.getTopLeft(find.byKey(_strip));

      final TestGesture finger = await tester.startGesture(
        Offset(top.dx + 12, top.dy + 5),
      );
      await finger.moveTo(Offset(top.dx + 12, top.dy + 100));
      await finger.up();
      await tester.pumpAndSettle();

      expect(_buzzes, isEmpty);
    });
  });

  group('the wave', () {
    testWidgets('the letter under the finger swings out and grows', (
      WidgetTester tester,
    ) async {
      await _pump(tester, height: 780);
      final double restX = _x(tester, 'M');
      final double restWidth = _width(tester, 'M');
      final Offset top = tester.getTopLeft(find.byKey(_strip));

      final TestGesture finger = await tester.startGesture(
        Offset(top.dx + 12, top.dy + 30 * 12 + 15),
      );
      await _settleWave(tester);

      expect(_x(tester, 'M'), lessThan(restX - JumpIndex.waveSwing * 0.9));
      expect(_width(tester, 'M'), greaterThan(restWidth * 1.5));
      await finger.up();
      await tester.pumpAndSettle();
    });

    testWidgets('it fades with distance, and far letters stay put', (
      WidgetTester tester,
    ) async {
      await _pump(tester, height: 780);
      final double restNear = _x(tester, 'O');
      final double restFar = _x(tester, 'A');
      final Offset top = tester.getTopLeft(find.byKey(_strip));

      final TestGesture finger = await tester.startGesture(
        Offset(top.dx + 12, top.dy + 30 * 12 + 15),
      );
      await _settleWave(tester);

      // Two letters away swings, but less than the one under the finger.
      final double near = restNear - _x(tester, 'O');
      final double under = _x(tester, 'N') - _x(tester, 'N');
      expect(near, greaterThan(0));
      expect(near, lessThan(JumpIndex.waveSwing));
      expect(under, 0);
      // A dozen letters away does not move at all.
      expect(_x(tester, 'A'), restFar);
      await finger.up();
      await tester.pumpAndSettle();
    });

    testWidgets('it settles back when the finger lifts', (
      WidgetTester tester,
    ) async {
      await _pump(tester, height: 780);
      final double restX = _x(tester, 'M');
      final double restWidth = _width(tester, 'M');
      final Offset top = tester.getTopLeft(find.byKey(_strip));

      final TestGesture finger = await tester.startGesture(
        Offset(top.dx + 12, top.dy + 30 * 12 + 15),
      );
      await _settleWave(tester);
      await finger.up();
      await tester.pumpAndSettle();

      expect(_x(tester, 'M'), closeTo(restX, 0.01));
      expect(_width(tester, 'M'), closeTo(restWidth, 0.01));
    });

    testWidgets('the wave follows the finger along the strip', (
      WidgetTester tester,
    ) async {
      await _pump(tester, height: 780);
      final double restD = _x(tester, 'D');
      final double restT = _x(tester, 'T');
      final Offset top = tester.getTopLeft(find.byKey(_strip));

      final TestGesture finger = await tester.startGesture(
        Offset(top.dx + 12, top.dy + 30 * 3 + 15),
      );
      await _settleWave(tester);
      expect(_x(tester, 'D'), lessThan(restD - 10));
      expect(_x(tester, 'T'), restT);

      await finger.moveTo(Offset(top.dx + 12, top.dy + 30 * 19 + 15));
      await _settleWave(tester);
      expect(_x(tester, 'D'), restD);
      expect(_x(tester, 'T'), lessThan(restT - 10));
      await finger.up();
      await tester.pumpAndSettle();
    });
  });

  testWidgets('a strip with no letters is empty and safe to touch', (
    WidgetTester tester,
  ) async {
    final List<int> jumps = await _pump(tester, initials: <String>[]);

    await tester.tapAt(tester.getCenter(find.byKey(_strip)));
    await tester.pump();

    expect(jumps, isEmpty);
  });
}

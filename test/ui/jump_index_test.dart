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

/// The 26 letters in a 780 px strip: 70% of the height, so 546 px, 21 a letter,
/// with 117 px (15%) clear above and below.
const double _height = 780;
const double _row = 21;
const double _top = 117;

/// Where, down the strip, the middle of letter [k] is.
double _at(int k) => _top + _row * k + _row / 2;

Future<List<int>> _pump(
  WidgetTester tester, {
  List<String>? initials,
  double height = _height,
  bool haptics = true,
  int? activeIndex,
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
                activeIndex: activeIndex,
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
  await tester.pump(const Duration(milliseconds: 300));
}

double _y(WidgetTester tester, String letter) =>
    tester.getCenter(find.text(letter)).dy;

double _x(WidgetTester tester, String letter) =>
    tester.getCenter(find.text(letter)).dx;

/// How much bigger than at rest the letter is drawn (layout size does not
/// change with a scale, so read the scale itself).
double _scale(WidgetTester tester, String letter) => tester
    .widgetList<Transform>(
      find.ancestor(of: find.text(letter), matching: find.byType(Transform)),
    )
    .map((Transform t) => t.transform.storage[0])
    .reduce((double a, double b) => a > b ? a : b);

void main() {
  group('spread', () {
    testWidgets('the letters fill the middle 70%, evenly', (
      WidgetTester tester,
    ) async {
      await _pump(tester);

      expect(_y(tester, 'B') - _y(tester, 'A'), closeTo(_row, 0.5));
      expect(_y(tester, 'Z') - _y(tester, 'A'), closeTo(_row * 25, 1));
      expect(_y(tester, 'A'), closeTo(_at(0), 1));
    });

    testWidgets('15% is clear above the first letter and below the last', (
      WidgetTester tester,
    ) async {
      await _pump(tester);

      expect(_y(tester, 'A'), greaterThan(_height * 0.15));
      expect(_y(tester, 'Z'), lessThan(_height * 0.85));
    });

    testWidgets('never more than the largest row, and then centred', (
      WidgetTester tester,
    ) async {
      await _pump(tester, initials: <String>['A', 'B', 'C'], height: 800);

      expect(
        _y(tester, 'B') - _y(tester, 'A'),
        closeTo(JumpIndex.maxRowHeight, 0.5),
      );
      expect(_y(tester, 'B'), closeTo(400, 1));
    });

    testWidgets('a short strip uses all its height, so every letter fits', (
      WidgetTester tester,
    ) async {
      await _pump(tester, height: 260);

      // 70% would be 7 a letter; it takes 10 (all 260) instead.
      expect(_y(tester, 'B') - _y(tester, 'A'), closeTo(10, 0.5));
      expect(_y(tester, 'Z'), lessThan(260));
    });

    testWidgets('a medium strip stops sparing its ends at the smallest row', (
      WidgetTester tester,
    ) async {
      // 26 letters in 500: 70% is 13.4 a letter, under the 14 minimum; there is
      // room for 19, so the minimum is used.
      await _pump(tester, height: 500);

      expect(
        _y(tester, 'B') - _y(tester, 'A'),
        closeTo(JumpIndex.minRowHeight, 0.5),
      );
    });

    testWidgets('a tap lands on the letter drawn there', (
      WidgetTester tester,
    ) async {
      final List<int> jumps = await _pump(tester);

      final Offset top = tester.getTopLeft(find.byKey(_strip));
      for (final int letter in <int>[0, 7, 13, 25]) {
        await tester.tapAt(Offset(top.dx + 12, top.dy + _at(letter)));
        await tester.pump();
      }

      expect(jumps, <int>[0, 7, 13, 25]);
    });

    testWidgets('a fresh touch on the same letter jumps again', (
      WidgetTester tester,
    ) async {
      final List<int> jumps = await _pump(tester);

      final Offset top = tester.getTopLeft(find.byKey(_strip));
      for (int i = 0; i < 3; i++) {
        await tester.tapAt(Offset(top.dx + 12, top.dy + _at(4)));
        await tester.pump();
      }

      expect(jumps, <int>[4, 4, 4]);
    });

    testWidgets('a tap in the clear space takes the nearest letter', (
      WidgetTester tester,
    ) async {
      final List<int> jumps = await _pump(tester);

      final Offset top = tester.getTopLeft(find.byKey(_strip));
      await tester.tapAt(Offset(top.dx + 12, top.dy + 20));
      await tester.pump();
      await tester.tapAt(Offset(top.dx + 12, top.dy + _height - 20));
      await tester.pump();

      expect(jumps, <int>[0, 25]);
    });
  });

  group('scrubbing', () {
    testWidgets('each letter passed over jumps once, in order', (
      WidgetTester tester,
    ) async {
      final List<int> jumps = await _pump(tester);
      final Offset top = tester.getTopLeft(find.byKey(_strip));

      final TestGesture finger = await tester.startGesture(
        Offset(top.dx + 12, top.dy + _at(0)),
      );
      for (double y = _at(0); y < _at(4) + 5; y += 5) {
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
      await _pump(tester);
      final Offset top = tester.getTopLeft(find.byKey(_strip));

      final TestGesture finger = await tester.startGesture(
        Offset(top.dx + 12, top.dy + _at(0)),
      );
      // Held long enough to count as a touch on the first letter.
      await tester.pump(kPressTimeout + const Duration(milliseconds: 10));
      await finger.moveTo(Offset(top.dx + 12, top.dy + _at(0) + 3));
      await finger.moveTo(Offset(top.dx + 12, top.dy + _at(1)));
      await finger.moveTo(Offset(top.dx + 12, top.dy + _at(1) + 3));
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
      await _pump(tester, haptics: false);
      final Offset top = tester.getTopLeft(find.byKey(_strip));

      final TestGesture finger = await tester.startGesture(
        Offset(top.dx + 12, top.dy + _at(0)),
      );
      await finger.moveTo(Offset(top.dx + 12, top.dy + _at(6)));
      await finger.up();
      await tester.pumpAndSettle();

      expect(_buzzes, isEmpty);
    });
  });

  group('room to breathe', () {
    testWidgets('the letters rest clear of the edge of the screen', (
      WidgetTester tester,
    ) async {
      await _pump(tester);

      // The strip is at the right edge of a 400 px screen; the column of
      // letters keeps the margin, and the letter is in the middle of it.
      final double fromEdge = 400 - _x(tester, 'A');
      expect(
        fromEdge,
        closeTo(JumpIndex.edgeMargin + JumpIndex.width / 2, 0.5),
      );
      expect(JumpIndex.edgeMargin, greaterThanOrEqualTo(8));
    });

    testWidgets('the touch area still reaches the edge of the screen', (
      WidgetTester tester,
    ) async {
      final List<int> jumps = await _pump(tester);
      final Offset top = tester.getTopLeft(find.byKey(_strip));

      await tester.tapAt(Offset(399, top.dy + _at(9)));
      await tester.pump();

      expect(jumps, <int>[9]);
      expect(
        tester.getSize(find.byKey(_strip)).width,
        JumpIndex.width + JumpIndex.edgeMargin,
      );
    });
  });

  group('pushed out while touched', () {
    testWidgets('the whole strip slides out from under the finger', (
      WidgetTester tester,
    ) async {
      await _pump(tester);
      final double restA = _x(tester, 'A');
      final double restZ = _x(tester, 'Z');
      final Offset top = tester.getTopLeft(find.byKey(_strip));

      final TestGesture finger = await tester.startGesture(
        Offset(top.dx + 12, top.dy + _at(12)),
      );
      await _settleWave(tester);

      // Far from the finger, so no wave: only the slide.
      expect(restA - _x(tester, 'A'), closeTo(JumpIndex.pushOut, 0.5));
      expect(restZ - _x(tester, 'Z'), closeTo(JumpIndex.pushOut, 0.5));
      await finger.up();
      await tester.pumpAndSettle();
    });

    testWidgets('and back to rest when it lifts', (WidgetTester tester) async {
      await _pump(tester);
      final double restA = _x(tester, 'A');
      final double restM = _x(tester, 'M');
      final Offset top = tester.getTopLeft(find.byKey(_strip));

      final TestGesture finger = await tester.startGesture(
        Offset(top.dx + 12, top.dy + _at(12)),
      );
      await _settleWave(tester);
      await finger.up();
      await tester.pumpAndSettle();

      expect(_x(tester, 'A'), closeTo(restA, 0.01));
      expect(_x(tester, 'M'), closeTo(restM, 0.01));
    });

    testWidgets('a touch in the clear space pushes it out too', (
      WidgetTester tester,
    ) async {
      await _pump(tester);
      final double restA = _x(tester, 'A');
      final Offset top = tester.getTopLeft(find.byKey(_strip));

      final TestGesture finger = await tester.startGesture(
        Offset(top.dx + 12, top.dy + 10),
      );
      await _settleWave(tester);

      expect(restA - _x(tester, 'A'), greaterThan(JumpIndex.pushOut - 1));
      await finger.up();
      await tester.pumpAndSettle();
    });
  });

  group('the wave', () {
    testWidgets('the letter under the finger swings out further and grows', (
      WidgetTester tester,
    ) async {
      await _pump(tester);
      final double restM = _x(tester, 'M');
      final double restA = _x(tester, 'A');
      final Offset top = tester.getTopLeft(find.byKey(_strip));

      final TestGesture finger = await tester.startGesture(
        Offset(top.dx + 12, top.dy + _at(12)),
      );
      await _settleWave(tester);

      final double slide = restA - _x(tester, 'A');
      expect(restM - _x(tester, 'M'), closeTo(slide + JumpIndex.waveSwing, 1));
      expect(_scale(tester, 'M'), greaterThan(1 + JumpIndex.waveGrowth * 0.9));
      expect(_scale(tester, 'A'), 1);
      await finger.up();
      await tester.pumpAndSettle();
    });

    testWidgets('it fades with distance', (WidgetTester tester) async {
      await _pump(tester);
      final double restM = _x(tester, 'M');
      final double restO = _x(tester, 'O');
      final double restA = _x(tester, 'A');
      final Offset top = tester.getTopLeft(find.byKey(_strip));

      final TestGesture finger = await tester.startGesture(
        Offset(top.dx + 12, top.dy + _at(12)),
      );
      await _settleWave(tester);

      final double slide = restA - _x(tester, 'A');
      final double under = restM - _x(tester, 'M') - slide;
      final double two = restO - _x(tester, 'O') - slide;
      expect(two, greaterThan(0));
      expect(two, lessThan(under));
      await finger.up();
      await tester.pumpAndSettle();
    });

    testWidgets('letters either side are pushed apart, away from the finger', (
      WidgetTester tester,
    ) async {
      await _pump(tester);
      final double restK = _y(tester, 'K');
      final double restL = _y(tester, 'L');
      final double restN = _y(tester, 'N');
      final double restO = _y(tester, 'O');
      final double restZ = _y(tester, 'Z');
      final Offset top = tester.getTopLeft(find.byKey(_strip));

      final TestGesture finger = await tester.startGesture(
        Offset(top.dx + 12, top.dy + _at(12)),
      );
      await _settleWave(tester);

      // M is under the finger; K and L above it move up, N and O below move
      // down; a letter beyond the reach stays put.
      expect(_y(tester, 'L'), lessThan(restL));
      expect(_y(tester, 'K'), lessThan(restK));
      expect(_y(tester, 'N'), greaterThan(restN));
      expect(_y(tester, 'O'), greaterThan(restO));
      expect(_y(tester, 'Z'), restZ);
      expect(
        (_y(tester, 'L') - restL).abs(),
        lessThanOrEqualTo(JumpIndex.waveSpread + 0.01),
      );
      await finger.up();
      await tester.pumpAndSettle();
    });

    testWidgets('the letter under the finger takes the accent colour', (
      WidgetTester tester,
    ) async {
      await _pump(tester);
      Color colourOf(String letter) =>
          tester.widget<Text>(find.text(letter)).style!.color!;
      final Color rest = colourOf('M');
      final Offset top = tester.getTopLeft(find.byKey(_strip));

      final TestGesture finger = await tester.startGesture(
        Offset(top.dx + 12, top.dy + _at(12)),
      );
      await _settleWave(tester);

      expect(colourOf('M'), isNot(rest));
      expect(colourOf('Z'), rest);
      await finger.up();
      await tester.pumpAndSettle();
      expect(colourOf('M'), rest);
    });

    testWidgets('the wave is a good deal more than a nudge', (
      WidgetTester tester,
    ) async {
      expect(JumpIndex.waveSwing, greaterThanOrEqualTo(20));
      expect(JumpIndex.waveGrowth, greaterThanOrEqualTo(1));
      expect(JumpIndex.waveReach, greaterThanOrEqualTo(5));
      expect(JumpIndex.pushOut, greaterThanOrEqualTo(40));
    });

    testWidgets('it follows the finger along the strip', (
      WidgetTester tester,
    ) async {
      await _pump(tester);
      final double restD = _x(tester, 'D');
      final double restT = _x(tester, 'T');
      final Offset top = tester.getTopLeft(find.byKey(_strip));

      final TestGesture finger = await tester.startGesture(
        Offset(top.dx + 12, top.dy + _at(3)),
      );
      await _settleWave(tester);
      expect(restD - _x(tester, 'D'), greaterThan(JumpIndex.pushOut + 5));
      expect(restT - _x(tester, 'T'), closeTo(JumpIndex.pushOut, 1));

      await finger.moveTo(Offset(top.dx + 12, top.dy + _at(19)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(restD - _x(tester, 'D'), closeTo(JumpIndex.pushOut, 1));
      expect(restT - _x(tester, 'T'), greaterThan(JumpIndex.pushOut + 5));
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

  group('the persistent marker', () {
    testWidgets('is not drawn when there is no active index', (
      WidgetTester tester,
    ) async {
      await _pump(tester);

      expect(find.byKey(jumpIndexActiveMarkerKey), findsNothing);
    });

    testWidgets('sits around the letter at the active index', (
      WidgetTester tester,
    ) async {
      await _pump(tester, activeIndex: 7);

      final Rect marker = tester.getRect(find.byKey(jumpIndexActiveMarkerKey));
      final Rect letter = tester.getRect(find.text('H'));
      expect(marker.top, closeTo(letter.top, _row / 2 + 1));
      expect(marker.height, closeTo(_row, 0.5));
    });

    testWidgets('moves when the active index changes', (
      WidgetTester tester,
    ) async {
      await _pump(tester, activeIndex: 0);
      final double first = tester
          .getRect(find.byKey(jumpIndexActiveMarkerKey))
          .top;

      await _pump(tester, activeIndex: 10);
      final double later = tester
          .getRect(find.byKey(jumpIndexActiveMarkerKey))
          .top;

      expect(later, greaterThan(first));
    });

    testWidgets('does not appear for an out-of-range active index', (
      WidgetTester tester,
    ) async {
      await _pump(tester, initials: <String>['A', 'B'], activeIndex: 5);

      expect(find.byKey(jumpIndexActiveMarkerKey), findsNothing);
    });

    testWidgets('still slides with the strip while a finger is down', (
      WidgetTester tester,
    ) async {
      await _pump(tester, activeIndex: 0);
      final double restLeft = tester
          .getRect(find.byKey(jumpIndexActiveMarkerKey))
          .left;
      final Offset top = tester.getTopLeft(find.byKey(_strip));

      final TestGesture finger = await tester.startGesture(
        Offset(top.dx + 12, top.dy + _at(12)),
      );
      await _settleWave(tester);

      final double touchedLeft = tester
          .getRect(find.byKey(jumpIndexActiveMarkerKey))
          .left;
      expect(touchedLeft, lessThan(restLeft));
      await finger.up();
      await tester.pumpAndSettle();
    });
  });
}

import 'package:android_tile_launcher/model/c64_colour.dart';
import 'package:android_tile_launcher/model/settings.dart';
import 'package:android_tile_launcher/services/settings_state.dart';
import 'package:android_tile_launcher/ui/settings_scope.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:android_tile_launcher/ui/tile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/in_memory_local_store.dart';

const Key _content = Key('content');
const Key _tile = Key('tile');

List<String> _buzzes = <String>[];

void _record(WidgetTester tester) {
  _buzzes = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (MethodCall call) async {
      // A bare `vibrate()` (Material's own feedback) has no argument; the
      // launcher always names a strength.
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

Future<void> _pumpTile(
  WidgetTester tester,
  Widget tile, {
  bool haptics = true,
}) async {
  final SettingsState settings = SettingsState(store: InMemoryLocalStore());
  await settings.update(LauncherSettings(haptics: haptics));
  await tester.pumpWidget(
    SettingsScope(
      state: settings,
      child: MaterialApp(
        home: Scaffold(
          body: Center(child: SizedBox(width: 120, height: 120, child: tile)),
        ),
      ),
    ),
  );
}

Future<void> _pump(
  WidgetTester tester, {
  VoidCallback? onTap,
  VoidCallback? onLongPress,
  bool haptics = true,
  bool selected = false,
}) => _pumpTile(
  tester,
  TileView(
    key: _tile,
    colour: C64Colour.blue,
    content: const SizedBox(key: _content, width: 10, height: 10),
    onTap: onTap,
    onLongPress: onLongPress,
    selected: selected,
  ),
  haptics: haptics,
);

BoxDecoration _decoration(WidgetTester tester) =>
    tester
            .widget<AnimatedContainer>(
              find.descendant(
                of: find.byKey(_tile),
                matching: find.byType(AnimatedContainer),
              ),
            )
            .decoration!
        as BoxDecoration;

Color _topLeft(WidgetTester tester) =>
    (_decoration(tester).border! as Border).top.color;

Color _bottomRight(WidgetTester tester) =>
    (_decoration(tester).border! as Border).bottom.color;

/// The bevel animates: one frame to start it, then time for it to finish.
Future<void> _flip(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(TileView.pressDuration * 2);
}

void main() {
  final Color fill = C64Colour.blue.fill;
  final Color light = Color.lerp(fill, C64.white, 0.35)!;
  final Color dark = Color.lerp(fill, C64.black, 0.35)!;

  testWidgets('at rest the light edge is top-left, the dark one bottom-right', (
    WidgetTester tester,
  ) async {
    await _pump(tester, onTap: () {});

    expect(_topLeft(tester), light);
    expect(_bottomRight(tester), dark);
  });

  testWidgets(
    'a finger on the tile flips the bevel, and lifting flips it back',
    (WidgetTester tester) async {
      await _pump(tester, onTap: () {});

      final TestGesture finger = await tester.startGesture(
        tester.getCenter(find.byKey(_tile)),
      );
      await _flip(tester);
      expect(_topLeft(tester), dark);
      expect(_bottomRight(tester), light);

      await finger.up();
      await _flip(tester);
      expect(_topLeft(tester), light);
      expect(_bottomRight(tester), dark);
    },
  );

  testWidgets('the content sinks by the width of the bevel', (
    WidgetTester tester,
  ) async {
    await _pump(tester, onTap: () {});
    final Offset resting = tester.getTopLeft(find.byKey(_content));

    final TestGesture finger = await tester.startGesture(
      tester.getCenter(find.byKey(_tile)),
    );
    await _flip(tester);

    expect(
      tester.getTopLeft(find.byKey(_content)) - resting,
      const Offset(TileMetrics.bevel, TileMetrics.bevel),
    );
    await finger.up();
    await tester.pumpAndSettle();
  });

  testWidgets('a tile whose content takes the tap itself still sinks', (
    WidgetTester tester,
  ) async {
    int taps = 0;
    await _pumpTile(
      tester,
      TileView(
        key: _tile,
        colour: C64Colour.blue,
        content: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => taps++,
          child: const SizedBox.expand(),
        ),
        onTap: null,
      ),
    );

    final TestGesture finger = await tester.startGesture(
      tester.getCenter(find.byKey(_tile)),
    );
    await _flip(tester);
    expect(_topLeft(tester), dark);

    await finger.up();
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('sliding away, as when scrolling, lets the tile back up', (
    WidgetTester tester,
  ) async {
    await _pump(tester, onTap: () {});

    final TestGesture finger = await tester.startGesture(
      tester.getCenter(find.byKey(_tile)),
    );
    await finger.moveBy(const Offset(0, 60));
    await _flip(tester);

    expect(_topLeft(tester), light);
    await finger.up();
    await tester.pumpAndSettle();
  });

  testWidgets('a selected tile keeps its outline and does not sink', (
    WidgetTester tester,
  ) async {
    await _pump(tester, onTap: () {}, selected: true);

    final TestGesture finger = await tester.startGesture(
      tester.getCenter(find.byKey(_tile)),
    );
    await _flip(tester);

    expect(_decoration(tester).border, isA<Border>());
    expect(_topLeft(tester), TileColors.textBright);
    await finger.up();
    await tester.pumpAndSettle();
  });

  group('haptics', () {
    testWidgets('a tap ticks once', (WidgetTester tester) async {
      _record(tester);
      await _pump(tester, onTap: () {});

      await tester.tap(find.byKey(_tile));
      await tester.pumpAndSettle();

      expect(_buzzes, <String>['HapticFeedbackType.lightImpact']);
    });

    testWidgets('a long press thuds, and is not also a tap', (
      WidgetTester tester,
    ) async {
      _record(tester);
      bool pressed = false;
      await _pump(tester, onTap: () {}, onLongPress: () => pressed = true);

      await tester.longPress(find.byKey(_tile));
      await tester.pumpAndSettle();

      expect(pressed, isTrue);
      expect(_buzzes, <String>['HapticFeedbackType.mediumImpact']);
    });

    testWidgets('a tile that does nothing when tapped does not tick', (
      WidgetTester tester,
    ) async {
      _record(tester);
      await _pump(tester);

      await tester.tap(find.byKey(_tile));
      await tester.pumpAndSettle();

      expect(_buzzes, isEmpty);
    });

    testWidgets('switched off in settings, nothing buzzes', (
      WidgetTester tester,
    ) async {
      _record(tester);
      await _pump(tester, onTap: () {}, onLongPress: () {}, haptics: false);

      await tester.tap(find.byKey(_tile));
      await tester.longPress(find.byKey(_tile));
      await tester.pumpAndSettle();

      expect(_buzzes, isEmpty);
    });
  });
}

import 'package:android_tile_launcher/ui/bevel_key.dart';
import 'package:android_tile_launcher/ui/press_listener.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const Key _key = Key('key');

List<String> _buzzes = <String>[];

void _record(WidgetTester tester) {
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

Future<void> _pump(
  WidgetTester tester, {
  VoidCallback? onTap,
  double height = 44,
}) => tester.pumpWidget(
  MaterialApp(
    theme: tileLauncherTheme(),
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 160,
          child: BevelKey(
            key: _key,
            label: 'SETTINGS',
            onTap: onTap,
            height: height,
          ),
        ),
      ),
    ),
  ),
);

BoxDecoration _decoration(WidgetTester tester) =>
    tester
            .widget<AnimatedContainer>(
              find.descendant(
                of: find.byKey(_key),
                matching: find.byType(AnimatedContainer),
              ),
            )
            .decoration!
        as BoxDecoration;

Border _border(WidgetTester tester) => _decoration(tester).border! as Border;

void main() {
  tearDown(() => TileColors.current = TilePalette.c64);

  testWidgets(
    'shows its label, is as wide as it is given and as tall as asked',
    (WidgetTester tester) async {
      await _pump(tester, onTap: () {}, height: 44);

      expect(find.text('SETTINGS'), findsOneWidget);
      expect(tester.getSize(find.byKey(_key)), const Size(160, 44));
    },
  );

  testWidgets('a tap calls it, and ticks', (WidgetTester tester) async {
    _record(tester);
    int taps = 0;
    await _pump(tester, onTap: () => taps++);

    await tester.tap(find.byKey(_key));
    await tester.pumpAndSettle();

    expect(taps, 1);
    expect(_buzzes, <String>['HapticFeedbackType.lightImpact']);
  });

  testWidgets('a key with no action is greyed, and neither ticks nor sinks', (
    WidgetTester tester,
  ) async {
    _record(tester);
    await _pump(tester);
    final Border rest = _border(tester);

    await tester.tap(find.byKey(_key));
    await tester.pump();
    await tester.pump(BevelKey.pressDuration * 2);

    expect(_buzzes, isEmpty);
    expect(_border(tester), rest);
    final Text label = tester.widget<Text>(find.text('SETTINGS'));
    expect(label.style!.color, TileColors.textDim);
    await tester.pumpAndSettle();
  });

  group('the bevel', () {
    testWidgets('is thinner on the lit sides than on the shaded ones', (
      WidgetTester tester,
    ) async {
      await _pump(tester, onTap: () {});

      final Border border = _border(tester);
      expect(border.top.width, BevelKey.lit);
      expect(border.left.width, BevelKey.lit);
      expect(border.bottom.width, BevelKey.shaded);
      expect(border.right.width, BevelKey.shaded);
      expect(BevelKey.shaded, greaterThan(BevelKey.lit));
    });

    testWidgets('flips while it is held, and flips back', (
      WidgetTester tester,
    ) async {
      await _pump(tester, onTap: () {});
      final Border rest = _border(tester);

      final TestGesture finger = await tester.startGesture(
        tester.getCenter(find.byKey(_key)),
      );
      await tester.pump(
        PressListener.showAfter + const Duration(milliseconds: 10),
      );
      await tester.pump();
      final Border held = _border(tester);

      expect(held.top.color, rest.bottom.color);
      expect(held.bottom.color, rest.top.color);
      expect(held.top.width, BevelKey.shaded);
      expect(held.bottom.width, BevelKey.lit);

      await finger.up();
      await tester.pumpAndSettle();
      expect(_border(tester), rest);
    });

    testWidgets('does not flip for a finger that is only scrolling past', (
      WidgetTester tester,
    ) async {
      await _pump(tester, onTap: () {});
      final Border rest = _border(tester);

      final TestGesture finger = await tester.startGesture(
        tester.getCenter(find.byKey(_key)),
      );
      await finger.moveBy(const Offset(0, 30));
      await tester.pump(PressListener.showAfter * 3);

      expect(_border(tester), rest);
      await finger.up();
      await tester.pumpAndSettle();
    });

    testWidgets('a quick tap flashes it once', (WidgetTester tester) async {
      await _pump(tester, onTap: () {});
      final Border rest = _border(tester);

      await tester.tap(find.byKey(_key));
      await tester.pump();
      expect(_border(tester).top.color, rest.bottom.color);

      await tester.pump(PressListener.flashFor);
      await tester.pumpAndSettle();
      expect(_border(tester), rest);
    });
  });

  testWidgets('takes its colours from the theme', (WidgetTester tester) async {
    await _pump(tester, onTap: () {});
    final Color c64Fill = _decoration(tester).color!;

    TileColors.current = TilePalette.beige;
    await _pump(tester, onTap: () {});
    await tester.pumpAndSettle();

    expect(_decoration(tester).color, isNot(c64Fill));
  });
}

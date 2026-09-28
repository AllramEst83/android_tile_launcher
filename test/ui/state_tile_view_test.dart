import 'package:android_tile_launcher/ui/state_tile_view.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester, {
  required String state,
  VoidCallback? onTap,
}) => tester.pumpWidget(
  MaterialApp(
    theme: tileLauncherTheme(),
    home: Scaffold(
      body: StateTileContentView(
        label: 'FLASHLIGHT',
        state: state,
        ink: Colors.white,
        onTap: onTap,
      ),
    ),
  ),
);

void main() {
  testWidgets('shows its label and ON when on', (WidgetTester tester) async {
    await _pump(tester, state: '[ON]');

    expect(find.text('FLASHLIGHT'), findsOneWidget);
    expect(find.text('[ON]'), findsOneWidget);
  });

  testWidgets('shows OFF when off', (WidgetTester tester) async {
    await _pump(tester, state: '[OFF]');

    expect(find.text('[OFF]'), findsOneWidget);
  });

  testWidgets('tapping calls onTap when given', (WidgetTester tester) async {
    var toggled = false;
    await _pump(tester, state: '[OFF]', onTap: () => toggled = true);

    await tester.tap(find.byType(StateTileContentView));

    expect(toggled, isTrue);
  });

  testWidgets('a tap anywhere on the tile counts, not just on the text', (
    WidgetTester tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: tileLauncherTheme(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              height: 200,
              child: StateTileContentView(
                label: 'SOUND',
                state: '[RING]',
                ink: Colors.white,
                onTap: () => taps++,
              ),
            ),
          ),
        ),
      ),
    );

    final Rect tile = tester.getRect(find.byType(StateTileContentView));
    await tester.tapAt(tile.centerRight - const Offset(5, 0));
    await tester.tapAt(tile.bottomLeft + const Offset(5, -5));

    expect(taps, 2);
  });

  testWidgets('is not tappable when onTap is null', (
    WidgetTester tester,
  ) async {
    await _pump(tester, state: '[OFF]');

    expect(find.byType(GestureDetector), findsNothing);
  });
}

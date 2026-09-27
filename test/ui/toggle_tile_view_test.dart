import 'package:android_tile_launcher/ui/theme.dart';
import 'package:android_tile_launcher/ui/toggle_tile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester, {
  required bool on,
  VoidCallback? onToggle,
}) => tester.pumpWidget(
  MaterialApp(
    theme: tileLauncherTheme(),
    home: Scaffold(
      body: ToggleTileContentView(
        label: 'FLASHLIGHT',
        on: on,
        ink: Colors.white,
        onToggle: onToggle,
      ),
    ),
  ),
);

void main() {
  testWidgets('shows its label and ON when on', (WidgetTester tester) async {
    await _pump(tester, on: true);

    expect(find.text('FLASHLIGHT'), findsOneWidget);
    expect(find.text('[ON]'), findsOneWidget);
  });

  testWidgets('shows OFF when off', (WidgetTester tester) async {
    await _pump(tester, on: false);

    expect(find.text('[OFF]'), findsOneWidget);
  });

  testWidgets('tapping calls onToggle when given', (WidgetTester tester) async {
    var toggled = false;
    await _pump(tester, on: false, onToggle: () => toggled = true);

    await tester.tap(find.byType(ToggleTileContentView));

    expect(toggled, isTrue);
  });

  testWidgets('is not tappable when onToggle is null', (
    WidgetTester tester,
  ) async {
    await _pump(tester, on: false);

    expect(find.byType(GestureDetector), findsNothing);
  });
}

import 'package:android_tile_launcher/ui/theme.dart';
import 'package:android_tile_launcher/ui/tile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, String label) => tester.pumpWidget(
  MaterialApp(
    theme: tileLauncherTheme(),
    home: Scaffold(
      body: AppTileContent(label: label, ink: Colors.white),
    ),
  ),
);

void main() {
  testWidgets('shows the label uppercase and its first letter as the glyph', (
    WidgetTester tester,
  ) async {
    await _pump(tester, 'Clock');

    expect(find.text('CLOCK'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
  });

  testWidgets('an empty label glyphs as a question mark', (
    WidgetTester tester,
  ) async {
    await _pump(tester, '');

    expect(find.text('?'), findsOneWidget);
  });
}

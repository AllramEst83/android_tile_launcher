import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/ui/ready_tile_view.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester, {
  double width = 200,
  VoidCallback? onTap,
}) => tester.pumpWidget(
  MaterialApp(
    theme: tileLauncherTheme(),
    home: Scaffold(
      body: SizedBox(
        width: width,
        height: 120,
        child: ReadyTileContentView(ink: Colors.white, onTap: onTap),
      ),
    ),
  ),
);

Color? _cursor(WidgetTester tester) =>
    tester.widget<Container>(find.byKey(readyCursorKey)).color;

void main() {
  testWidgets('shows the prompt, and a hint on a wide tile', (
    WidgetTester tester,
  ) async {
    await _pump(tester);

    expect(find.text(Messages.bootReady), findsOneWidget);
    expect(find.text(Messages.readyTileHint), findsOneWidget);
  });

  testWidgets('a small tile is just the prompt and the cursor', (
    WidgetTester tester,
  ) async {
    await _pump(tester, width: 100);

    expect(find.text(Messages.bootReady), findsOneWidget);
    expect(find.text(Messages.readyTileHint), findsNothing);
  });

  testWidgets('the cursor blinks', (WidgetTester tester) async {
    await _pump(tester);
    expect(_cursor(tester), Colors.white);

    await tester.pump(const Duration(milliseconds: 500));
    expect(_cursor(tester), Colors.transparent);

    await tester.pump(const Duration(milliseconds: 500));
    expect(_cursor(tester), Colors.white);
  });

  testWidgets('a tap calls onTap', (WidgetTester tester) async {
    int taps = 0;
    await _pump(tester, onTap: () => taps++);
    await tester.tap(find.byType(ReadyTileContentView));
    expect(taps, 1);
  });
}

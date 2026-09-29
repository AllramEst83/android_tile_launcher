import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/ui/help_screen.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _open(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: tileLauncherTheme(),
      home: Builder(
        builder: (BuildContext context) => TextButton(
          onPressed: () => showHelpScreen(context),
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('has a close key, and closes', (WidgetTester tester) async {
    await _open(tester);

    expect(find.byKey(helpCloseKey), findsOneWidget);

    await tester.tap(find.byKey(helpCloseKey));
    await tester.pumpAndSettle();

    expect(find.byKey(helpCloseKey), findsNothing);
  });

  testWidgets('covers getting around, the tiles, resizing, settings and data', (
    WidgetTester tester,
  ) async {
    await _open(tester);

    for (final String title in <String>[
      Messages.helpGettingAroundTitle,
      Messages.helpTilesTitle,
      Messages.helpResizingTitle,
      Messages.helpSettingsTitle,
      Messages.helpPrivacyTitle,
    ]) {
      expect(find.text(title), findsOneWidget, reason: title);
    }
  });

  testWidgets('a phone-width screen at EXTRA LARGE does not overflow', (
    WidgetTester tester,
  ) async {
    tester.view
      ..physicalSize = const Size(360 * 3, 780 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: tileLauncherTheme(),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: const HelpScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}

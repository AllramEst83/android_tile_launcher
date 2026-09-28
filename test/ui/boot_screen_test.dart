import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/ui/boot_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Duration get _wholeShow =>
    BootScreen.perCharacter *
    (BootScreen.script.fold<int>(0, (int n, String l) => n + l.length) +
        BootScreen.holdCharacters);

Future<void> _pump(
  WidgetTester tester, {
  bool animate = false,
  bool error = false,
  VoidCallback? onDone,
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: BootScreen(animate: animate, error: error, onDone: onDone),
    ),
  ),
);

void main() {
  group('plain', () {
    testWidgets('shows the banner, the memory line and READY.', (
      WidgetTester tester,
    ) async {
      await _pump(tester);

      expect(find.text(Messages.bootBanner), findsOneWidget);
      expect(find.text(Messages.bootMemory), findsOneWidget);
      expect(find.text(Messages.bootReady), findsOneWidget);
      expect(find.byKey(bootCursorKey), findsNothing);
    });

    testWidgets('says so when the app list could not be read', (
      WidgetTester tester,
    ) async {
      await _pump(tester, error: true);

      expect(find.text(Messages.appListError), findsOneWidget);
      expect(find.text(Messages.bootReady), findsNothing);
    });
  });

  group('animated', () {
    testWidgets('starts with nothing typed but the cursor', (
      WidgetTester tester,
    ) async {
      await _pump(tester, animate: true);

      expect(find.text(Messages.bootBanner), findsNothing);
      expect(find.byKey(bootCursorKey), findsOneWidget);
    });

    testWidgets('types the banner out a character at a time', (
      WidgetTester tester,
    ) async {
      await _pump(tester, animate: true);

      await tester.pump(BootScreen.perCharacter * 4);
      expect(find.text(Messages.bootBanner.substring(0, 4)), findsOneWidget);

      await tester.pump(BootScreen.perCharacter * 6);
      expect(find.text(Messages.bootBanner.substring(0, 10)), findsOneWidget);
    });

    testWidgets('ends with every line of the script on screen, then is done', (
      WidgetTester tester,
    ) async {
      int done = 0;
      await _pump(tester, animate: true, onDone: () => done++);

      await tester.pump();
      await tester.pump(_wholeShow - const Duration(milliseconds: 100));
      expect(done, 0);
      for (final String line in BootScreen.script.where((l) => l.isNotEmpty)) {
        expect(find.text(line), findsWidgets, reason: line);
      }

      await tester.pump(const Duration(milliseconds: 200));
      expect(done, 1);
    });

    testWidgets('a tap finishes it at once, and only once', (
      WidgetTester tester,
    ) async {
      int done = 0;
      await _pump(tester, animate: true, onDone: () => done++);
      await tester.pump(BootScreen.perCharacter * 3);

      await tester.tap(find.byType(BootScreen));
      await tester.pump();
      expect(done, 1);

      await tester.pump(_wholeShow);
      expect(done, 1);
    });

    testWidgets('the cursor blinks once everything is typed', (
      WidgetTester tester,
    ) async {
      await _pump(tester, animate: true);
      await tester.pump();
      await tester.pump(
        BootScreen.perCharacter *
            BootScreen.script.fold<int>(0, (int n, String l) => n + l.length),
      );

      final List<bool> seen = <bool>[];
      for (int i = 0; i < 4; i++) {
        await tester.pump(BootScreen.blink);
        seen.add(find.byKey(bootCursorKey).evaluate().isNotEmpty);
      }

      expect(seen, contains(true));
      expect(seen, contains(false));
    });

    testWidgets('turning into the error screen stops the show for good', (
      WidgetTester tester,
    ) async {
      int done = 0;
      await _pump(tester, animate: true, onDone: () => done++);
      await tester.pump(BootScreen.perCharacter * 3);

      await _pump(tester, error: true, onDone: () => done++);
      expect(find.text(Messages.appListError), findsOneWidget);
      await tester.pump(_wholeShow * 2);

      expect(done, 0);
      expect(find.text(Messages.appListError), findsOneWidget);
    });
  });
}

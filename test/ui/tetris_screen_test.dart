import 'package:android_tile_launcher/games/tetris/tetris_screen.dart';
import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/ui/pad_key.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _open(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: tileLauncherTheme(),
      home: Builder(
        builder: (BuildContext context) => TextButton(
          onPressed: () => showTetris(context),
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  // Not pumpAndSettle: Flame's game loop schedules a frame every tick for as
  // long as the game is mounted, so it never "settles". Two pumps: the
  // first starts the push transition, the second finishes it.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  testWidgets('opens with a fresh score, level, and lines', (
    WidgetTester tester,
  ) async {
    await _open(tester);

    expect(find.textContaining('SCORE 0'), findsOneWidget);
    expect(find.textContaining('LEVEL 1'), findsOneWidget);
    expect(find.textContaining('LINES 0'), findsOneWidget);
  });

  testWidgets('the close button returns to whatever opened it', (
    WidgetTester tester,
  ) async {
    await _open(tester);

    await tester.tap(find.byKey(tetrisCloseKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(tetrisCloseKey), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('LEFT, RIGHT and ROTATE do not crash the game', (
    WidgetTester tester,
  ) async {
    await _open(tester);

    await tester.tap(find.byKey(tetrisLeftKey));
    await tester.pump();
    await tester.tap(find.byKey(tetrisRightKey));
    await tester.pump();
    await tester.tap(find.byKey(tetrisRotateKey));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byKey(tetrisCloseKey), findsOneWidget);
  });

  testWidgets('PAUSE freezes the game and shows PAUSED; PLAY resumes it', (
    WidgetTester tester,
  ) async {
    await _open(tester);

    await tester.tap(find.byKey(tetrisPauseKey));
    await tester.pump();

    expect(find.byKey(tetrisPausedKey), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(tetrisPauseKey),
        matching: find.text(Messages.tetrisResume),
      ),
      findsOneWidget,
    );

    // Actions are no-ops while paused: SLAM would otherwise always change
    // the score/board at once.
    await tester.tap(find.byKey(tetrisHardDropKey));
    await tester.pump();
    expect(find.textContaining('SCORE 0'), findsOneWidget);

    await tester.tap(find.byKey(tetrisPauseKey));
    await tester.pump();

    expect(find.byKey(tetrisPausedKey), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(tetrisPauseKey),
        matching: find.text(Messages.tetrisPause),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'hard-dropping until it tops out shows GAME OVER, and RESTART works',
    (WidgetTester tester) async {
      await _open(tester);

      // No side-to-side movement, so every piece stacks in the middle column
      // and the board tops out quickly.
      int guard = 0;
      while (find.byKey(tetrisGameOverKey).evaluate().isEmpty && guard < 60) {
        await tester.tap(find.byKey(tetrisHardDropKey));
        await tester.pump();
        guard++;
      }

      expect(find.byKey(tetrisGameOverKey), findsOneWidget);
      expect(find.text(Messages.tetrisGameOver), findsOneWidget);

      // Nothing left to pause once the game is over.
      final PadKey pauseKey = tester.widget(find.byKey(tetrisPauseKey));
      expect(pauseKey.onTap, isNull);

      await tester.tap(find.byKey(tetrisRestartKey));
      await tester.pump();

      expect(find.byKey(tetrisGameOverKey), findsNothing);
      expect(find.textContaining('SCORE 0'), findsOneWidget);
    },
  );
}

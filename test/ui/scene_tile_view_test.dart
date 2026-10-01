import 'package:android_tile_launcher/model/scene_animation.dart';
import 'package:android_tile_launcher/ui/scene_tile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const Key _fakeLottieKey = ValueKey<String>('fake-lottie');

/// Stands in for the real [DotLottieView] so no test ever mounts the real
/// platform view — the same seam `QrScannerScreen.scannerBuilder` uses for
/// the camera preview. Shows [animation]'s label as plain text so a test can
/// tell which one was built without touching a real `.lottie` file.
Widget _fakeLottie(SceneAnimation animation) =>
    Text(animation.label, key: _fakeLottieKey);

Future<void> _pump(
  WidgetTester tester, {
  SceneAnimation animation = SceneAnimation.rocket,
  VoidCallback? onTap,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: SceneTileContentView(
        animation: animation,
        onTap: onTap,
        lottieBuilder: _fakeLottie,
      ),
    ),
  );
}

void main() {
  testWidgets('shows the given animation', (WidgetTester tester) async {
    await _pump(tester);

    expect(find.text(SceneAnimation.rocket.label), findsOneWidget);
  });

  testWidgets('switching the animation shows its own art instead', (
    WidgetTester tester,
  ) async {
    await _pump(tester, animation: SceneAnimation.flower);

    expect(find.text(SceneAnimation.rocket.label), findsNothing);
    expect(find.text(SceneAnimation.flower.label), findsOneWidget);
  });

  testWidgets('tapping it calls onTap', (WidgetTester tester) async {
    int taps = 0;
    await _pump(tester, onTap: () => taps++);

    await tester.tap(find.byKey(sceneTileArtKey));

    expect(taps, 1);
  });

  testWidgets('with no onTap, a tap does nothing (the grid editor)', (
    WidgetTester tester,
  ) async {
    await _pump(tester);

    await tester.tap(find.byKey(sceneTileArtKey));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('with no override, builds a real DotLottieView', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SceneTileContentView(animation: SceneAnimation.rocket),
      ),
    );

    expect(find.byKey(sceneTileArtKey), findsOneWidget);
  });

  for (final SceneAnimation animation in SceneAnimation.values) {
    testWidgets(
      'every animation mounts a real DotLottieView without throwing: ${animation.name}',
      (WidgetTester tester) async {
        // No lottieBuilder override: this mounts the real DotLottieView.
        // Note this does *not* prove `animation.lottieAsset` resolves to a
        // real bundled file — a failed `rootBundle.load` inside its
        // FutureBuilder is swallowed (`snapshot.hasData` just stays false
        // and it renders an empty Container), so it would not have caught
        // the `colm_and_easy.lottie` typo. See
        // `scene_animation_test.dart`'s "is actually bundled" check for that.
        await tester.pumpWidget(
          MaterialApp(home: SceneTileContentView(animation: animation)),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
      },
    );
  }
}

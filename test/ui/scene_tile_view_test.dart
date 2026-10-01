import 'package:android_tile_launcher/model/scene_animation.dart';
import 'package:android_tile_launcher/ui/scene_tile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester, {
  SceneAnimation animation = SceneAnimation.rocket,
  VoidCallback? onTap,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: SceneTileContentView(
        animation: animation,
        ink: Colors.white,
        onTap: onTap,
      ),
    ),
  );
  // flutter_animate starts each effect after a zero-duration `Future.delayed`
  // (its own `Animate.delay` defaults to none); without this extra pump that
  // timer is still outstanding when the test ends, and the binding's own
  // "no pending timers" check (rightly) fails the test over it. A duration,
  // not a bare `pump()`, so the fake clock actually advances past it.
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('the rocket shows its hull and flame', (
    WidgetTester tester,
  ) async {
    await _pump(tester);

    expect(find.text(rocketHull.join('\n')), findsOneWidget);
    expect(find.text(rocketFlame), findsOneWidget);
  });

  testWidgets('the palm tree shows its fronds/trunk and the shoreline', (
    WidgetTester tester,
  ) async {
    await _pump(tester, animation: SceneAnimation.palmTree);

    expect(find.text(palmTree.join('\n')), findsOneWidget);
    expect(find.text(palmWaves), findsOneWidget);
  });

  testWidgets('the flower shows its head, stem and the ground', (
    WidgetTester tester,
  ) async {
    await _pump(tester, animation: SceneAnimation.flower);

    expect(find.text(flowerHead), findsOneWidget);
    expect(find.text(flowerStem.join('\n')), findsOneWidget);
    expect(find.text(flowerGround), findsOneWidget);
  });

  testWidgets('stays correct through several seconds of its own animation', (
    WidgetTester tester,
  ) async {
    await _pump(tester);

    // The moving pieces (flame, bob, twinkle) never change what text is
    // shown, only how it is transformed — so this should hold at any point
    // in the loop, not just the instant it mounts.
    await tester.pump(const Duration(seconds: 3));

    expect(find.text(rocketHull.join('\n')), findsOneWidget);
    expect(find.text(rocketFlame), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('switching the animation shows its own art instead', (
    WidgetTester tester,
  ) async {
    await _pump(tester, animation: SceneAnimation.flower);

    expect(find.text(rocketHull.join('\n')), findsNothing);
    expect(find.text(flowerHead), findsOneWidget);
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
}

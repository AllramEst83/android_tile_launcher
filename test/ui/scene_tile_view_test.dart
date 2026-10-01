import 'package:android_tile_launcher/model/scene_animation.dart';
import 'package:android_tile_launcher/ui/scene_tile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester, {
  SceneAnimation animation = SceneAnimation.rocket,
  VoidCallback? onTap,
}) => tester.pumpWidget(
  MaterialApp(
    home: SceneTileContentView(
      animation: animation,
      ink: Colors.white,
      onTap: onTap,
    ),
  ),
);

/// The art's lines, top to bottom, as actually rendered — a frame's own
/// lines are not always distinct from each other (two blank-ish rows, say),
/// so comparing this whole list is the one way to tell frames apart that
/// does not break on a repeated line within one of them.
List<String> _rendered(WidgetTester tester) => tester
    .widgetList<Text>(
      find.descendant(
        of: find.byKey(sceneTileArtKey),
        matching: find.byType(Text),
      ),
    )
    .map((Text t) => t.data!)
    .toList();

void main() {
  testWidgets('shows the animation\'s first frame', (
    WidgetTester tester,
  ) async {
    await _pump(tester);

    expect(_rendered(tester), framesOf(SceneAnimation.rocket).first);
  });

  testWidgets('advances to the next frame on its own timer', (
    WidgetTester tester,
  ) async {
    await _pump(tester);
    final List<List<String>> frames = framesOf(SceneAnimation.rocket);

    await tester.pump(const Duration(milliseconds: 600));

    expect(_rendered(tester), frames[1]);
  });

  testWidgets('loops back to the first frame after the last', (
    WidgetTester tester,
  ) async {
    await _pump(tester);
    final List<List<String>> frames = framesOf(SceneAnimation.rocket);

    for (int i = 0; i < frames.length; i++) {
      await tester.pump(const Duration(milliseconds: 600));
    }

    expect(_rendered(tester), frames.first);
  });

  testWidgets('switching the animation shows its own frames instead', (
    WidgetTester tester,
  ) async {
    await _pump(tester, animation: SceneAnimation.flower);

    expect(_rendered(tester), framesOf(SceneAnimation.flower).first);
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

  testWidgets('stops ticking while backgrounded, resumes on return', (
    WidgetTester tester,
  ) async {
    await _pump(tester);
    final List<List<String>> frames = framesOf(SceneAnimation.rocket);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 5));
    expect(_rendered(tester), frames.first);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 600));
    expect(_rendered(tester), frames[1]);
  });
}

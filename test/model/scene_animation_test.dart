import 'package:android_tile_launcher/model/scene_animation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every animation has at least two frames, so it can loop', () {
    for (final SceneAnimation animation in SceneAnimation.values) {
      expect(framesOf(animation).length, greaterThanOrEqualTo(2));
    }
  });

  test('every frame of one animation has the same number of lines', () {
    for (final SceneAnimation animation in SceneAnimation.values) {
      final List<List<String>> frames = framesOf(animation);
      final int lines = frames.first.length;
      for (final List<String> frame in frames) {
        expect(frame.length, lines);
      }
    }
  });

  test('three to start with: rocket, palm tree, flower', () {
    expect(SceneAnimation.values, <SceneAnimation>[
      SceneAnimation.rocket,
      SceneAnimation.palmTree,
      SceneAnimation.flower,
    ]);
  });

  test('each has its own label for the picker sheet', () {
    expect(SceneAnimation.rocket.label, 'ROCKET LAUNCH');
    expect(SceneAnimation.palmTree.label, 'PALM TREE');
    expect(SceneAnimation.flower.label, 'FLOWER');
  });
}

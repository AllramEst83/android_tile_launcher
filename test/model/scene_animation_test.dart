import 'package:android_tile_launcher/model/scene_animation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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

  test('none of the art pieces are empty', () {
    expect(rocketHull, isNotEmpty);
    expect(rocketFlame, isNotEmpty);
    expect(palmTree, isNotEmpty);
    expect(palmWaves, isNotEmpty);
    expect(flowerHead, isNotEmpty);
    expect(flowerStem, isNotEmpty);
    expect(flowerGround, isNotEmpty);
  });
}

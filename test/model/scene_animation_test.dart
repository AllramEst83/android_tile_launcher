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

  test('each points at its own bundled .lottie asset', () {
    expect(SceneAnimation.rocket.lottieAsset, 'lottie/rocket_lunch.lottie');
    expect(SceneAnimation.palmTree.lottieAsset, 'lottie/palm_tree_leaf.lottie');
    expect(SceneAnimation.flower.lottieAsset, 'lottie/plant.lottie');
  });

  test('every asset path is distinct', () {
    final Set<String> paths = SceneAnimation.values
        .map((SceneAnimation a) => a.lottieAsset)
        .toSet();
    expect(paths, hasLength(SceneAnimation.values.length));
  });
}

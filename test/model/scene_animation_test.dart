import 'dart:typed_data';

import 'package:android_tile_launcher/model/scene_animation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'five to start with: rocket, palm tree, flower, calm and easy, retro vinyl',
    () {
      expect(SceneAnimation.values, <SceneAnimation>[
        SceneAnimation.rocket,
        SceneAnimation.palmTree,
        SceneAnimation.flower,
        SceneAnimation.calmAndEasy,
        SceneAnimation.retroVinyl,
      ]);
    },
  );

  test('each has its own label for the picker sheet', () {
    expect(SceneAnimation.rocket.label, 'ROCKET LAUNCH');
    expect(SceneAnimation.palmTree.label, 'PALM TREE');
    expect(SceneAnimation.flower.label, 'FLOWER');
    expect(SceneAnimation.calmAndEasy.label, 'CALM AND EASY');
    expect(SceneAnimation.retroVinyl.label, 'RETRO VINYL');
  });

  test('each points at its own bundled .lottie asset', () {
    expect(SceneAnimation.rocket.lottieAsset, 'lottie/rocket_lunch.lottie');
    expect(SceneAnimation.palmTree.lottieAsset, 'lottie/palm_tree_leaf.lottie');
    expect(SceneAnimation.flower.lottieAsset, 'lottie/plant.lottie');
    expect(
      SceneAnimation.calmAndEasy.lottieAsset,
      'lottie/calm_and_easy.lottie',
    );
    expect(SceneAnimation.retroVinyl.lottieAsset, 'lottie/retro_vinyl.lottie');
  });

  test('every asset path is distinct', () {
    final Set<String> paths = SceneAnimation.values
        .map((SceneAnimation a) => a.lottieAsset)
        .toSet();
    expect(paths, hasLength(SceneAnimation.values.length));
  });

  test('every label is distinct', () {
    final Set<String> labels = SceneAnimation.values
        .map((SceneAnimation a) => a.label)
        .toSet();
    expect(labels, hasLength(SceneAnimation.values.length));
  });

  for (final SceneAnimation animation in SceneAnimation.values) {
    test('${animation.name}\'s .lottie file is actually bundled', () async {
      // The same path `DotLottieView` resolves against the asset bundle
      // (`scene_tile_view.dart`'s `_getCreationParams`); unlike mounting the
      // widget itself, a missing file here throws instead of silently
      // rendering an empty Container, so this is the check that catches a
      // `lottieAsset` path that doesn't match what's actually in
      // `assets/lottie/` (declared in `pubspec.yaml`) — exactly the typo a
      // `colm_and_easy.lottie` vs. `calm_and_easy.lottie` mismatch was.
      final ByteData data = await rootBundle.load(
        'assets/${animation.lottieAsset}',
      );
      expect(data.lengthInBytes, greaterThan(0));
    });
  }
}

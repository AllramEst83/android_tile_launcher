import 'dart:typed_data';

import 'package:android_tile_launcher/model/scene_animation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the picker lists them in order, oldest first', () {
    expect(SceneAnimation.values, <SceneAnimation>[
      SceneAnimation.rocket,
      SceneAnimation.palmTree,
      SceneAnimation.flower,
      SceneAnimation.calmAndEasy,
      SceneAnimation.retroVinyl,
      SceneAnimation.rainyDay,
      SceneAnimation.cockroach,
      SceneAnimation.octopus,
      SceneAnimation.dinosaur,
      SceneAnimation.fly,
      SceneAnimation.butterfly,
    ]);
  });

  test('each has its own label for the picker sheet', () {
    expect(SceneAnimation.rocket.label, 'ROCKET LAUNCH');
    expect(SceneAnimation.palmTree.label, 'PALM TREE');
    expect(SceneAnimation.flower.label, 'FLOWER');
    expect(SceneAnimation.calmAndEasy.label, 'CALM AND EASY');
    expect(SceneAnimation.retroVinyl.label, 'RETRO VINYL');
    expect(SceneAnimation.rainyDay.label, 'RAINY DAY');
    expect(SceneAnimation.cockroach.label, 'COCKROACH');
    expect(SceneAnimation.octopus.label, 'OCTOPUS');
    expect(SceneAnimation.dinosaur.label, 'DINOSAUR');
    expect(SceneAnimation.fly.label, 'FLY');
    expect(SceneAnimation.butterfly.label, 'BUTTERFLY');
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
    expect(SceneAnimation.rainyDay.lottieAsset, 'lottie/rainy_day.lottie');
    expect(SceneAnimation.cockroach.lottieAsset, 'lottie/cockroach.lottie');
    expect(SceneAnimation.octopus.lottieAsset, 'lottie/octopus.lottie');
    expect(SceneAnimation.dinosaur.lottieAsset, 'lottie/dinosaur.lottie');
    expect(SceneAnimation.fly.lottieAsset, 'lottie/fly.lottie');
    expect(SceneAnimation.butterfly.lottieAsset, 'lottie/butterfly.lottie');
  });

  test('each has a sensible draw scale', () {
    for (final SceneAnimation a in SceneAnimation.values) {
      expect(a.scale, inInclusiveRange(1.0, 2.0), reason: a.label);
    }
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

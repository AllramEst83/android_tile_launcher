/// One of the Scene tile's short, continuously looping animations — a real
/// Lottie/dotLottie file (`dotlottie_flutter`, in `scene_tile_view.dart`)
/// rather than ASCII art or any hand-rolled frame/tween system. More arrive
/// the same way these three did: a case here with its own `.lottie` asset
/// (bundled from `assets/lottie/`, declared in `pubspec.yaml`).
enum SceneAnimation {
  rocket('ROCKET LAUNCH', 'lottie/rocket_lunch.lottie', 1.0),
  palmTree('PALM TREE', 'lottie/palm_tree_leaf.lottie', 1.3),
  flower('FLOWER', 'lottie/plant.lottie', 1.4),
  calmAndEasy('CALM AND EASY', 'lottie/calm_and_easy.lottie', 1.0),
  retroVinyl('RETRO VINYL', 'lottie/retro_vinyl.lottie', 1.8),
  rainyDay('RAINY DAY', 'lottie/rainy_day.lottie', 1.1),
  cockroach('COCKROACH', 'lottie/cockroach.lottie', 1.0),
  octopus('OCTOPUS', 'lottie/octopus.lottie', 1.0),
  dinosaur('DINOSAUR', 'lottie/dinosaur.lottie', 1.0),
  fly('FLY', 'lottie/fly.lottie', 1.0),
  butterfly('BUTTERFLY', 'lottie/butterfly.lottie', 1.0);

  const SceneAnimation(this.label, this.lottieAsset, this.scale);

  final String label;

  /// Path under `assets/` to this animation's `.lottie` file — what
  /// `DotLottieView(sourceType: 'asset', source: ...)` expects.
  final String lottieAsset;

  /// How much bigger than the tile this file is drawn so its artwork fills the
  /// tile: `.lottie` files carry different built-in margins, so each gets its
  /// own factor (measured from the rendered frames, never past the point where
  /// the artwork would be clipped by the tile edge).
  final double scale;
}

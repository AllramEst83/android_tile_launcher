/// One of the Scene tile's short, continuously looping animations — a real
/// Lottie/dotLottie file (`dotlottie_flutter`, in `scene_tile_view.dart`)
/// rather than ASCII art or any hand-rolled frame/tween system. More arrive
/// the same way these three did: a case here with its own `.lottie` asset
/// (bundled from `assets/lottie/`, declared in `pubspec.yaml`).
enum SceneAnimation {
  rocket('ROCKET LAUNCH', 'lottie/rocket_lunch.lottie'),
  palmTree('PALM TREE', 'lottie/palm_tree_leaf.lottie'),
  flower('FLOWER', 'lottie/plant.lottie');

  const SceneAnimation(this.label, this.lottieAsset);

  final String label;

  /// Path under `assets/` to this animation's `.lottie` file — what
  /// `DotLottieView(sourceType: 'asset', source: ...)` expects.
  final String lottieAsset;
}

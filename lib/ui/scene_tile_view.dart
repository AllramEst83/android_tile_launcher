import 'package:android_tile_launcher/model/scene_animation.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:dotlottie_flutter/dotlottie_flutter.dart';
import 'package:flutter/material.dart';

/// Key so tests can find the art.
const Key sceneTileArtKey = ValueKey<String>('scene-tile-art');

/// The Scene tile's content: [animation]'s `.lottie` file, autoplaying and
/// looping forever, scaled to fit and centred in whatever space the tile
/// gives it — so it stays centred as the tile is resized in the grid
/// editor, same as [BoxFit.contain] does for any image.
class SceneTileContentView extends StatelessWidget {
  const SceneTileContentView({
    super.key,
    required this.animation,
    this.onTap,
    this.lottieBuilder,
  });

  final SceneAnimation animation;
  final VoidCallback? onTap;

  /// Builds the looping animation for [animation]; defaults to a real
  /// [DotLottieView]. A test overrides this to avoid mounting the real
  /// platform view, the same seam `QrScannerScreen.scannerBuilder` uses for
  /// the camera preview.
  final Widget Function(SceneAnimation animation)? lottieBuilder;

  @override
  Widget build(BuildContext context) {
    final Widget Function(SceneAnimation) build =
        lottieBuilder ?? _defaultLottie;
    final Widget art = Padding(
      key: sceneTileArtKey,
      padding: const EdgeInsets.all(TileMetrics.gutter / 2),
      child: SizedBox.expand(child: build(animation)),
    );
    final VoidCallback? tap = onTap;
    if (tap == null) return art;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: tap,
      child: art,
    );
  }
}

Widget _defaultLottie(SceneAnimation animation) => DotLottieView(
  key: ValueKey<String>('scene-lottie-${animation.name}'),
  sourceType: 'asset',
  source: animation.lottieAsset,
  autoplay: true,
  loop: true,
  fit: BoxFit.contain,
);

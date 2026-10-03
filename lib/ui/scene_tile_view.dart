import 'package:android_tile_launcher/model/scene_animation.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:dotlottie_flutter/dotlottie_flutter.dart';
import 'package:flutter/material.dart';

/// Key so tests can find the art.
const Key sceneTileArtKey = ValueKey<String>('scene-tile-art');

/// The Scene tile's content: [animation]'s `.lottie` file, autoplaying and
/// looping forever, scaled to fill whatever space the tile gives it (and, per
/// [SceneAnimation.scale], a little past its edges) and centred — so it stays centred
/// as the tile is resized in the grid editor, same as [BoxFit.contain] does
/// for any image.
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
      padding: const EdgeInsets.all(TileMetrics.gutter / 4),
      // DotLottieView is a real platform view (AndroidView/UiKitView) and
      // claims every touch inside its own bounds directly, with nothing
      // declared in its `gestureRecognizers` for Flutter's gesture arena to
      // share — without this, the GestureDetector below never sees the tap
      // that is meant to open the picker sheet. The animation itself has no
      // interactive parts of its own, so ignoring its pointer events costs
      // nothing.
      child: ClipRect(
        child: IgnorePointer(
          child: SizedBox.expand(
            child: Transform.scale(
              scale: animation.scale,
              child: build(animation),
            ),
          ),
        ),
      ),
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

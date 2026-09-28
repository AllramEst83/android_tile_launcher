import 'package:android_tile_launcher/model/settings.dart';

/// Which of the phone's screens a wallpaper goes on.
enum WallpaperTarget {
  lock('LOCK SCREEN', 'THE LOCK SCREEN'),
  home('HOME SCREEN', 'THE HOME SCREEN'),
  both('BOTH', 'BOTH SCREENS');

  const WallpaperTarget(this.label, this.phrase);

  /// On its key.
  final String label;

  /// In a sentence: "PUT IT ON [phrase]".
  final String phrase;
}

/// The bundled picture that goes with a theme: the same look as the launcher
/// wearing it. Replaced by dropping a picture with the same name into
/// `assets/wallpapers/`.
String wallpaperAssetOf(ThemeVariant theme) =>
    'assets/wallpapers/wallpaper_${theme.name}.png';

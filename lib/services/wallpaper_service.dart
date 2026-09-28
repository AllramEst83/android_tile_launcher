import 'dart:typed_data';

import 'package:android_tile_launcher/model/wallpaper.dart';

/// How a wallpaper request ended.
enum WallpaperResult {
  /// The phone took it.
  done,

  /// The phone refused: wallpapers are locked by a work profile or a policy, or
  /// the permission is missing.
  refused,

  /// Anything else: the picture could not be read, or the phone gave up.
  failed,
}

/// Puts a picture on the phone's lock screen or home screen, or takes it off
/// again. Only what the user asked for on the settings screen calls this;
/// nothing is set on its own. Never throws.
abstract interface class WallpaperService {
  /// Sets [image] (the bytes of a PNG or JPEG) as the wallpaper of [target].
  Future<WallpaperResult> set(Uint8List image, WallpaperTarget target);

  /// Puts the phone's own default wallpaper back on [target].
  Future<WallpaperResult> clear(WallpaperTarget target);
}

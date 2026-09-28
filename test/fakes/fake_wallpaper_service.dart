import 'dart:typed_data';

import 'package:android_tile_launcher/model/wallpaper.dart';
import 'package:android_tile_launcher/services/wallpaper_service.dart';

/// Records what was set or cleared, and answers with [result].
class FakeWallpaperService implements WallpaperService {
  FakeWallpaperService([this.result = WallpaperResult.done]);

  WallpaperResult result;

  /// Every `set`, in order: the picture's size in bytes and where it went.
  final List<(int, WallpaperTarget)> sets = <(int, WallpaperTarget)>[];
  final List<WallpaperTarget> clears = <WallpaperTarget>[];

  @override
  Future<WallpaperResult> set(Uint8List image, WallpaperTarget target) async {
    sets.add((image.length, target));
    return result;
  }

  @override
  Future<WallpaperResult> clear(WallpaperTarget target) async {
    clears.add(target);
    return result;
  }
}

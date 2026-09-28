import 'dart:io';

import 'package:android_tile_launcher/model/settings.dart';
import 'package:android_tile_launcher/model/wallpaper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('each theme has its own picture under assets/wallpapers', () {
    expect(ThemeVariant.values.map(wallpaperAssetOf), <String>[
      'assets/wallpapers/wallpaper_c64.png',
      'assets/wallpapers/wallpaper_oled.png',
      'assets/wallpapers/wallpaper_beige.png',
    ]);
  });

  test('every picture that a theme points at is in the repo', () {
    for (final ThemeVariant theme in ThemeVariant.values) {
      expect(
        File(wallpaperAssetOf(theme)).existsSync(),
        isTrue,
        reason: '$theme',
      );
    }
  });

  test('a target reads as a key and as part of a sentence', () {
    expect(WallpaperTarget.lock.label, 'LOCK SCREEN');
    expect(WallpaperTarget.lock.phrase, 'THE LOCK SCREEN');
    expect(WallpaperTarget.both.label, 'BOTH');
    expect(WallpaperTarget.both.phrase, 'BOTH SCREENS');
  });
}

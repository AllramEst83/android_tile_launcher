import 'package:android_tile_launcher/model/settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('the defaults', () {
    test('are the C64 blue screen, four columns, the normal gap', () {
      const LauncherSettings defaults = LauncherSettings();

      expect(defaults.theme, ThemeVariant.c64);
      expect(defaults.columns, 4);
      expect(defaults.gap, GridGap.normal);
      // The behaviour the launcher had before there were settings.
      expect(defaults.swipeDown, GestureAction.refreshApps);
      expect(defaults.swipeUp, GestureAction.none);
    });

    test('the gaps are 4, 8 and 14 pixels', () {
      expect(GridGap.tight.pixels, 4);
      expect(GridGap.normal.pixels, 8);
      expect(GridGap.relaxed.pixels, 14);
    });
  });

  group('JSON', () {
    test('round-trips every setting', () {
      const LauncherSettings settings = LauncherSettings(
        theme: ThemeVariant.beige,
        columns: 6,
        gap: GridGap.tight,
        swipeDown: GestureAction.notifications,
        swipeUp: GestureAction.searchApps,
      );

      expect(LauncherSettings.fromJson(settings.toJson()), settings);
    });

    test('anything that is not an object is the defaults', () {
      expect(LauncherSettings.fromJson(null), const LauncherSettings());
      expect(LauncherSettings.fromJson('nope'), const LauncherSettings());
      expect(LauncherSettings.fromJson(<Object?>[1]), const LauncherSettings());
    });

    test('a missing choice keeps its default, the rest are kept', () {
      final LauncherSettings settings = LauncherSettings.fromJson(
        <String, Object?>{'theme': 'oled'},
      );

      expect(settings.theme, ThemeVariant.oled);
      expect(settings.columns, 4);
    });

    test('a choice that is not one of the offered ones is ignored', () {
      final LauncherSettings settings = LauncherSettings.fromJson(
        <String, Object?>{
          'theme': 'neon',
          'columns': 5,
          'gap': 'huge',
          // Real actions, but not ones this gesture may be set to.
          'swipeDown': 'searchApps',
          'swipeUp': 'notifications',
        },
      );

      expect(settings, const LauncherSettings());
    });

    test('a value of the wrong type is ignored, not fatal', () {
      final LauncherSettings settings = LauncherSettings.fromJson(
        <String, Object?>{'theme': 3, 'columns': '6', 'gap': null},
      );

      expect(settings, const LauncherSettings());
    });
  });

  group('the choices offered', () {
    test('every gesture can be turned off', () {
      expect(LauncherSettings.swipeDownChoices, contains(GestureAction.none));
      expect(LauncherSettings.swipeUpChoices, contains(GestureAction.none));
    });

    test('a swipe down and a swipe up have different things to offer', () {
      expect(
        LauncherSettings.swipeDownChoices,
        contains(GestureAction.notifications),
      );
      expect(
        LauncherSettings.swipeUpChoices,
        contains(GestureAction.searchApps),
      );
      expect(
        LauncherSettings.swipeUpChoices,
        isNot(contains(GestureAction.notifications)),
      );
    });

    test('4 or 6 columns', () {
      expect(LauncherSettings.columnChoices, <int>[4, 6]);
    });
  });

  test('copyWith changes only what is given', () {
    const LauncherSettings settings = LauncherSettings();

    final LauncherSettings changed = settings.copyWith(columns: 6);

    expect(changed.columns, 6);
    expect(changed.theme, settings.theme);
    expect(changed.gap, settings.gap);
  });
}

import 'package:flutter/material.dart';

/// The VIC-II palette the Commodore 64 could draw, in Pepto's calibration.
///
/// Tiles pick their fill from these sixteen and nothing else: the limit is the
/// look. Named by the colour, not by the job, so a tile can say what it wants.
abstract final class C64 {
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color red = Color(0xFF813338);
  static const Color cyan = Color(0xFF75CEC8);
  static const Color purple = Color(0xFF8E3C97);
  static const Color green = Color(0xFF56AC4D);
  static const Color blue = Color(0xFF2E2C9B);
  static const Color yellow = Color(0xFFEDF171);
  static const Color orange = Color(0xFF8E5029);
  static const Color brown = Color(0xFF553800);
  static const Color lightRed = Color(0xFFC46C71);
  static const Color darkGrey = Color(0xFF4A4A4A);
  static const Color grey = Color(0xFF7B7B7B);
  static const Color lightGreen = Color(0xFFA9FF9F);
  static const Color lightBlue = Color(0xFF706DEB);
  static const Color lightGrey = Color(0xFFB2B2B2);

  /// The stripe from the Commodore wordmark, top to bottom. Used as an accent
  /// rule, never as a tile fill.
  static const List<Color> rainbow = <Color>[
    Color(0xFFE2342B),
    Color(0xFFF58220),
    Color(0xFFFFEC00),
    Color(0xFF3AB54A),
    Color(0xFF0095DA),
  ];
}

/// The screen a C64 powers on to: light blue on blue, inside a lighter border.
abstract final class TileColors {
  static const Color canvas = C64.blue;
  static const Color bezel = C64.lightBlue;
  static const Color text = C64.lightBlue;
  static const Color textBright = C64.white;
  static const Color textDim = C64.grey;
}

/// The mosaic the home screen is laid out on: four columns, a tight gutter, and
/// square corners. Tile sizes are whole numbers of columns and base rows.
abstract final class TileMetrics {
  static const int columns = 4;
  static const double gutter = 8;
  static const double margin = 12;

  /// Hard edges. The Commodore look has bevels, not rounded corners.
  static const double radius = 0;
  static const double bevel = 2;
}

/// No pixel font is bundled yet (see plan.md, Phase 1.1), so this resolves to
/// the platform's monospace face. It is never fetched at runtime: the launcher
/// has to draw itself at boot with no network.
const String kMonoFontFamily = 'monospace';

ThemeData tileLauncherTheme() {
  const TextStyle base = TextStyle(
    fontFamily: kMonoFontFamily,
    color: TileColors.text,
    height: 1.25,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: TileColors.canvas,
    colorScheme: const ColorScheme.dark(
      primary: C64.lightBlue,
      onPrimary: C64.black,
      secondary: C64.cyan,
      onSecondary: C64.black,
      surface: C64.blue,
      onSurface: C64.lightBlue,
      error: C64.lightRed,
    ),
    fontFamily: kMonoFontFamily,
    textTheme: TextTheme(
      displayLarge: base.copyWith(fontSize: 48, color: TileColors.textBright),
      headlineMedium: base.copyWith(fontSize: 24, color: TileColors.textBright),
      titleSmall: base.copyWith(fontSize: 12, letterSpacing: 1),
      bodyMedium: base.copyWith(fontSize: 14),
      labelSmall: base.copyWith(fontSize: 10, color: TileColors.textDim),
    ),
  );
}

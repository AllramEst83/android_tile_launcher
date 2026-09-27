import 'package:android_tile_launcher/model/c64_colour.dart';
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

/// Turns a [C64Colour] selector into an actual fill and a contrasting ink
/// colour, so a tile never has to guess whether black or white text reads on
/// its own background. The only place a `C64Colour` becomes a `Color`.
extension C64ColourSwatch on C64Colour {
  Color get fill => switch (this) {
    C64Colour.black => C64.black,
    C64Colour.white => C64.white,
    C64Colour.red => C64.red,
    C64Colour.cyan => C64.cyan,
    C64Colour.purple => C64.purple,
    C64Colour.green => C64.green,
    C64Colour.blue => C64.blue,
    C64Colour.yellow => C64.yellow,
    C64Colour.orange => C64.orange,
    C64Colour.brown => C64.brown,
    C64Colour.lightRed => C64.lightRed,
    C64Colour.darkGrey => C64.darkGrey,
    C64Colour.grey => C64.grey,
    C64Colour.lightGreen => C64.lightGreen,
    C64Colour.lightBlue => C64.lightBlue,
    C64Colour.lightGrey => C64.lightGrey,
  };

  Color get ink => switch (this) {
    C64Colour.white ||
    C64Colour.cyan ||
    C64Colour.yellow ||
    C64Colour.lightRed ||
    C64Colour.grey ||
    C64Colour.lightGreen ||
    C64Colour.lightGrey => C64.black,
    C64Colour.black ||
    C64Colour.red ||
    C64Colour.purple ||
    C64Colour.green ||
    C64Colour.blue ||
    C64Colour.orange ||
    C64Colour.brown ||
    C64Colour.darkGrey ||
    C64Colour.lightBlue => C64.white,
  };
}

/// The one pixel font the whole app draws with, bundled as an asset (OFL 1.1,
/// see `fonts/OFL.txt`) so the launcher can draw itself at boot with no
/// network. Every text style in [tileLauncherTheme] goes through this
/// constant; swapping the font later is a one-line change here.
const String kPixelFontFamily = 'PressStart2P';

ThemeData tileLauncherTheme() {
  const TextStyle base = TextStyle(
    fontFamily: kPixelFontFamily,
    color: TileColors.text,
    height: 1.6,
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
    fontFamily: kPixelFontFamily,
    textTheme: TextTheme(
      displayLarge: base.copyWith(fontSize: 48, color: TileColors.textBright),
      headlineMedium: base.copyWith(fontSize: 24, color: TileColors.textBright),
      titleSmall: base.copyWith(fontSize: 12, letterSpacing: 1),
      bodyMedium: base.copyWith(fontSize: 14),
      labelSmall: base.copyWith(fontSize: 10, color: TileColors.textDim),
    ),
  );
}

import 'package:android_tile_launcher/model/c64_colour.dart';
import 'package:android_tile_launcher/model/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

/// The colours the launcher's own chrome is drawn in (the canvas behind the
/// tiles, text, borders, and the few status colours). Tile fills are not part
/// of it: they are always the sixteen VIC-II colours ([C64], `C64Colour`),
/// whatever screen they sit on.
///
/// Three are offered (`ThemeVariant`): the C64's own blue screen, a pitch-black
/// one for OLED screens, and the beige of the C64's case.
class TilePalette {
  const TilePalette({
    required this.brightness,
    required this.canvas,
    required this.bezel,
    required this.text,
    required this.textBright,
    required this.textDim,
    required this.muted,
    required this.accent,
    required this.highlight,
    required this.danger,
  });

  /// Whether the canvas is dark or light, for the parts of Flutter that ask
  /// (the system bars' icons, dialogs).
  final Brightness brightness;

  /// The screen everything is drawn on.
  final Color canvas;

  /// Borders and rules.
  final Color bezel;

  /// Ordinary text, and text on a border.
  final Color text;

  /// Text that matters most: names, numbers, what is selected.
  final Color textBright;

  /// Text that recedes: hints, disabled things.
  final Color textDim;

  /// Secondary text that must still be easy to read.
  final Color muted;

  /// A second voice: the answer under a sum, a date, a running total.
  final Color accent;

  /// What is chosen, or asks for a decision.
  final Color highlight;

  /// Something went wrong.
  final Color danger;

  /// The C64 power-on screen: light blue on blue.
  static const TilePalette c64 = TilePalette(
    brightness: Brightness.dark,
    canvas: C64.blue,
    bezel: C64.lightBlue,
    text: C64.lightBlue,
    textBright: C64.white,
    textDim: C64.grey,
    muted: C64.lightGrey,
    accent: C64.cyan,
    highlight: C64.yellow,
    danger: C64.lightRed,
  );

  /// Pitch black, so an OLED screen lights only what is drawn on it.
  static const TilePalette oled = TilePalette(
    brightness: Brightness.dark,
    canvas: C64.black,
    bezel: C64.lightBlue,
    text: C64.lightBlue,
    textBright: C64.white,
    textDim: C64.grey,
    muted: C64.lightGrey,
    accent: C64.cyan,
    highlight: C64.yellow,
    danger: C64.lightRed,
  );

  /// The beige of the C64's case: dark brown on beige, with the C64's own blue
  /// and purple as accents.
  static const TilePalette beige = TilePalette(
    brightness: Brightness.light,
    canvas: Color(0xFFD8CDB2),
    bezel: Color(0xFF8E5029),
    text: Color(0xFF553800),
    textBright: C64.black,
    textDim: Color(0xFF7A6A4C),
    muted: Color(0xFF5E4E32),
    accent: C64.blue,
    highlight: C64.purple,
    danger: C64.red,
  );

  /// The palette for [variant].
  static TilePalette of(ThemeVariant variant) => switch (variant) {
    ThemeVariant.c64 => c64,
    ThemeVariant.oled => oled,
    ThemeVariant.beige => beige,
  };
}

/// The colours the launcher's chrome is drawn in right now: whatever
/// [TilePalette] is [current]. The app sets [current] when the theme setting
/// changes and then rebuilds everything, so any widget can read these without
/// a `BuildContext`.
abstract final class TileColors {
  static TilePalette current = TilePalette.c64;

  static Color get canvas => current.canvas;
  static Color get bezel => current.bezel;
  static Color get text => current.text;
  static Color get textBright => current.textBright;
  static Color get textDim => current.textDim;
  static Color get muted => current.muted;
  static Color get accent => current.accent;
  static Color get highlight => current.highlight;
  static Color get danger => current.danger;
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

  /// A tile's bevel: the lit top and left sides, and the thicker shaded bottom
  /// and right ones, so a tile stands up like a key. A pressed tile swaps them,
  /// which is what moves its content down and right.
  static const double tileBevelLight = 3;
  static const double tileBevelDark = 5;
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

/// How the system bars are drawn over [palette]: no colour behind the status
/// bar, the navigation bar the colour of the canvas, and icons that show up on
/// it (light on a dark canvas, dark on a light one).
SystemUiOverlayStyle systemUiStyleFor(TilePalette palette) {
  final Brightness icons = palette.brightness == Brightness.dark
      ? Brightness.light
      : Brightness.dark;
  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: palette.canvas,
    statusBarIconBrightness: icons,
    systemNavigationBarIconBrightness: icons,
  );
}

ThemeData tileLauncherTheme() {
  final TilePalette palette = TileColors.current;
  final TextStyle base = TextStyle(
    fontFamily: kPixelFontFamily,
    color: palette.text,
    height: 1.6,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: palette.brightness,
    scaffoldBackgroundColor: palette.canvas,
    colorScheme: ColorScheme(
      brightness: palette.brightness,
      primary: palette.bezel,
      onPrimary: palette.canvas,
      secondary: palette.accent,
      onSecondary: palette.canvas,
      surface: palette.canvas,
      onSurface: palette.text,
      error: palette.danger,
      onError: palette.canvas,
    ),
    fontFamily: kPixelFontFamily,
    textTheme: TextTheme(
      displayLarge: base.copyWith(fontSize: 48, color: palette.textBright),
      headlineMedium: base.copyWith(fontSize: 24, color: palette.textBright),
      titleSmall: base.copyWith(fontSize: 12, letterSpacing: 1),
      bodyMedium: base.copyWith(fontSize: 14),
      labelSmall: base.copyWith(fontSize: 10, color: palette.textDim),
    ),
  );
}

import 'dart:math' as math;

import 'package:android_tile_launcher/app.dart';
import 'package:android_tile_launcher/model/settings.dart';
import 'package:android_tile_launcher/services/grid_state.dart';
import 'package:android_tile_launcher/services/settings_state.dart';
import 'package:android_tile_launcher/ui/home_shell.dart';
import 'package:android_tile_launcher/ui/settings_scope.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_app_repository.dart';
import '../fakes/fake_tile_services.dart';
import '../fakes/in_memory_local_store.dart';

/// WCAG relative luminance and contrast ratio.
double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

double _contrast(Color a, Color b) {
  final double la = _luminance(a);
  final double lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  tearDown(() => TileColors.current = TilePalette.c64);

  group('every palette can be read on its own canvas', () {
    for (final ThemeVariant variant in ThemeVariant.values) {
      final TilePalette p = TilePalette.of(variant);
      // The C64's own light blue on blue is the look and is about 2.6:1; the
      // two palettes made for this launcher have to read well.
      final double floor = variant == ThemeVariant.c64 ? 2.5 : 4;

      test('${variant.label}: text that matters is easy to read', () {
        expect(_contrast(p.textBright, p.canvas), greaterThanOrEqualTo(7));
        expect(_contrast(p.muted, p.canvas), greaterThanOrEqualTo(4));
        expect(_contrast(p.text, p.canvas), greaterThanOrEqualTo(floor));
      });

      test('${variant.label}: the status colours show up', () {
        expect(_contrast(p.accent, p.canvas), greaterThanOrEqualTo(floor));
        expect(_contrast(p.highlight, p.canvas), greaterThanOrEqualTo(floor));
        expect(_contrast(p.danger, p.canvas), greaterThanOrEqualTo(2.5));
      });

      test('${variant.label}: borders and dim text still show', () {
        expect(_contrast(p.bezel, p.canvas), greaterThanOrEqualTo(2.5));
        expect(_contrast(p.textDim, p.canvas), greaterThanOrEqualTo(2.5));
      });
    }
  });

  group('the palettes', () {
    test('the C64 screen is blue, the OLED one black, the beige light', () {
      expect(TilePalette.c64.canvas, C64.blue);
      expect(TilePalette.oled.canvas, C64.black);
      expect(TilePalette.beige.brightness, Brightness.light);
      expect(TilePalette.c64.brightness, Brightness.dark);
      expect(TilePalette.oled.brightness, Brightness.dark);
    });

    test('each variant has its own palette', () {
      expect(
        <TilePalette>{
          for (final ThemeVariant v in ThemeVariant.values) TilePalette.of(v),
        }.length,
        ThemeVariant.values.length,
      );
    });

    test('TileColors reads whichever palette is current', () {
      TileColors.current = TilePalette.beige;

      expect(TileColors.canvas, TilePalette.beige.canvas);
      expect(TileColors.text, TilePalette.beige.text);
      expect(TileColors.accent, TilePalette.beige.accent);
    });

    test('the Flutter theme follows the palette', () {
      TileColors.current = TilePalette.oled;
      final ThemeData oled = tileLauncherTheme();
      TileColors.current = TilePalette.beige;
      final ThemeData beige = tileLauncherTheme();

      expect(oled.scaffoldBackgroundColor, C64.black);
      expect(oled.brightness, Brightness.dark);
      expect(beige.scaffoldBackgroundColor, TilePalette.beige.canvas);
      expect(beige.brightness, Brightness.light);
      expect(beige.textTheme.bodyMedium?.color, TilePalette.beige.text);
    });

    test('the system bars: light icons on dark, dark icons on light', () {
      expect(
        systemUiStyleFor(TilePalette.c64).statusBarIconBrightness,
        Brightness.light,
      );
      expect(
        systemUiStyleFor(TilePalette.beige).statusBarIconBrightness,
        Brightness.dark,
      );
      expect(
        systemUiStyleFor(TilePalette.oled).systemNavigationBarColor,
        C64.black,
      );
    });
  });

  group('changing the theme in the running app', () {
    Future<SettingsState> pumpApp(WidgetTester tester) async {
      final SettingsState settings = SettingsState(store: InMemoryLocalStore());
      await tester.pumpWidget(
        TileLauncherApp(
          appRepository: FakeAppRepository(),
          gridState: GridState(store: InMemoryLocalStore()),
          settingsState: settings,
          services: fakeTileServices(),
        ),
      );
      await tester.pump();
      return settings;
    }

    testWidgets('starts in the C64 palette', (WidgetTester tester) async {
      await pumpApp(tester);

      expect(TileColors.current, same(TilePalette.c64));
      expect(
        Theme.of(tester.element(find.byType(HomeShell)))
            .scaffoldBackgroundColor,
        C64.blue,
      );
    });

    testWidgets('the palette a saved setting names is in place at once', (
      WidgetTester tester,
    ) async {
      final SettingsState settings = SettingsState(store: InMemoryLocalStore());
      await settings.update(const LauncherSettings(theme: ThemeVariant.oled));

      await tester.pumpWidget(
        TileLauncherApp(
          appRepository: FakeAppRepository(),
          gridState: GridState(store: InMemoryLocalStore()),
          settingsState: settings,
          services: fakeTileServices(),
        ),
      );

      expect(TileColors.current, same(TilePalette.oled));
    });

    testWidgets('changing it repaints the whole app, state kept', (
      WidgetTester tester,
    ) async {
      final SettingsState settings = await pumpApp(tester);

      await settings.update(const LauncherSettings(theme: ThemeVariant.beige));
      // The theme fades to the new colours; let it finish.
      await tester.pumpAndSettle();

      expect(TileColors.current, same(TilePalette.beige));
      expect(
        Theme.of(tester.element(find.byType(HomeShell)))
            .scaffoldBackgroundColor,
        TilePalette.beige.canvas,
      );

      await settings.update(const LauncherSettings(theme: ThemeVariant.c64));
      await tester.pumpAndSettle();
      expect(TileColors.current, same(TilePalette.c64));
    });

    testWidgets('text that reads the palette directly changes too', (
      WidgetTester tester,
    ) async {
      final SettingsState settings = await pumpApp(tester);
      // The "swipe left" hint is drawn from the theme's label style, and the
      // add-tile button beside it from `TileColors` directly.
      Color hintColour() => tester
          .widget<Text>(find.text('SWIPE LEFT FOR ALL APPS'))
          .style!
          .color!;
      final Color before = hintColour();

      await settings.update(const LauncherSettings(theme: ThemeVariant.beige));
      // The theme fades to the new colours; let it finish.
      await tester.pumpAndSettle();

      expect(hintColour(), isNot(before));
      expect(hintColour(), TilePalette.beige.textDim);
    });

    testWidgets('a scope tells widgets the current settings', (
      WidgetTester tester,
    ) async {
      final SettingsState settings = SettingsState(store: InMemoryLocalStore());
      int columns = 0;
      await tester.pumpWidget(
        SettingsScope(
          state: settings,
          child: Builder(
            builder: (BuildContext context) {
              columns = SettingsScope.of(context).columns;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(columns, 4);

      await settings.update(const LauncherSettings(columns: 6));
      await tester.pump();

      expect(columns, 6);
    });

    testWidgets('without a scope the defaults apply', (
      WidgetTester tester,
    ) async {
      LauncherSettings? seen;
      await tester.pumpWidget(
        Builder(
          builder: (BuildContext context) {
            seen = SettingsScope.of(context);
            return const SizedBox();
          },
        ),
      );

      expect(seen, const LauncherSettings());
    });
  });
}

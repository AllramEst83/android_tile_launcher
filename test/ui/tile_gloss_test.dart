import 'dart:ui' as ui;

import 'package:android_tile_launcher/model/c64_colour.dart';
import 'package:android_tile_launcher/model/settings.dart';
import 'package:android_tile_launcher/services/settings_state.dart';
import 'package:android_tile_launcher/ui/press_listener.dart';
import 'package:android_tile_launcher/ui/settings_scope.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:android_tile_launcher/ui/tile_gloss.dart';
import 'package:android_tile_launcher/ui/tile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/in_memory_local_store.dart';

const Key _tile = Key('tile');

Future<void> _pump(
  WidgetTester tester, {
  bool effects = true,
  bool selected = false,
}) async {
  final SettingsState settings = SettingsState(store: InMemoryLocalStore());
  await settings.update(LauncherSettings(effects: effects));
  await tester.pumpWidget(
    SettingsScope(
      state: settings,
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 120,
              height: 120,
              child: TileView(
                key: _tile,
                colour: C64Colour.green,
                content: const SizedBox(),
                onTap: () {},
                selected: selected,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

TileGlossPainter _painter(WidgetTester tester) =>
    tester
            .widget<CustomPaint>(
              find.descendant(
                of: find.byType(TileGloss),
                matching: find.byType(CustomPaint),
              ),
            )
            .painter!
        as TileGlossPainter;

void main() {
  group('on a tile', () {
    testWidgets('is drawn by default, over the tile, taking no touches', (
      WidgetTester tester,
    ) async {
      await _pump(tester);

      expect(find.byType(TileGloss), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(TileGloss),
          matching: find.byType(IgnorePointer),
        ),
        findsWidgets,
      );
      // The tile keeps its size: the effects are layered on, not laid out.
      expect(tester.getSize(find.byKey(_tile)), const Size(120, 120));
    });

    testWidgets('is absent when switched off in settings', (
      WidgetTester tester,
    ) async {
      await _pump(tester, effects: false);

      expect(find.byType(TileGloss), findsNothing);
      expect(tester.getSize(find.byKey(_tile)), const Size(120, 120));
    });

    testWidgets('a selected tile gets scanlines only', (
      WidgetTester tester,
    ) async {
      await _pump(tester, selected: true);

      expect(_painter(tester).outlined, isTrue);
    });

    testWidgets('a pressed tile loses its shine and moves its shade', (
      WidgetTester tester,
    ) async {
      await _pump(tester);
      expect(_painter(tester).sunk, isFalse);

      final TestGesture finger = await tester.startGesture(
        tester.getCenter(find.byKey(_tile)),
      );
      await tester.pump(
        PressListener.showAfter + const Duration(milliseconds: 10),
      );
      await tester.pump();

      expect(_painter(tester).sunk, isTrue);
      await finger.up();
      await tester.pumpAndSettle();
      expect(_painter(tester).sunk, isFalse);
    });

    testWidgets('a tap still reaches the tile through it', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      final SettingsState settings = SettingsState(store: InMemoryLocalStore());
      await tester.pumpWidget(
        SettingsScope(
          state: settings,
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 120,
                  height: 120,
                  child: TileView(
                    key: _tile,
                    colour: C64Colour.green,
                    content: const SizedBox(),
                    onTap: () => taps++,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(_tile));
      await tester.pumpAndSettle();

      expect(taps, 1);
    });
  });

  group('the painter', () {
    void paintOn(TileGlossPainter painter, Size size) {
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      painter.paint(Canvas(recorder), size);
      recorder.endRecording().dispose();
    }

    test('draws at every state and size without trouble', () {
      for (final bool sunk in <bool>[false, true]) {
        for (final bool outlined in <bool>[false, true]) {
          final TileGlossPainter painter = TileGlossPainter(
            sunk: sunk,
            outlined: outlined,
          );
          for (final Size size in const <Size>[
            Size(80, 80),
            Size(360, 80),
            Size(360, 360),
            Size(12, 12),
            Size(4, 4),
            Size.zero,
          ]) {
            paintOn(painter, size);
          }
        }
      }
    });

    test('repaints only when the tile changes state', () {
      const TileGlossPainter rest = TileGlossPainter(
        sunk: false,
        outlined: false,
      );

      expect(
        rest.shouldRepaint(
          const TileGlossPainter(sunk: false, outlined: false),
        ),
        isFalse,
      );
      expect(
        rest.shouldRepaint(const TileGlossPainter(sunk: true, outlined: false)),
        isTrue,
      );
      expect(
        rest.shouldRepaint(const TileGlossPainter(sunk: false, outlined: true)),
        isTrue,
      );
    });

    test('the bevel is thicker on the shaded sides', () {
      expect(
        TileMetrics.tileBevelDark,
        greaterThan(TileMetrics.tileBevelLight),
      );
      expect(TileMetrics.tileBevelLight, greaterThan(TileMetrics.bevel));
    });

    test('pressing sinks the content by exactly one bevel unit', () {
      // `tile_press_test.dart`'s own "sinks by the width of the bevel" asserts
      // this in pixels; this is the design invariant behind that number, so a
      // future bevel tweak that breaks it fails here with a clear reason
      // rather than a bare offset mismatch there.
      expect(
        TileMetrics.tileBevelDark - TileMetrics.tileBevelLight,
        TileMetrics.bevel,
      );
    });
  });
}

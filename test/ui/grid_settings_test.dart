import 'package:android_tile_launcher/model/c64_colour.dart';
import 'package:android_tile_launcher/model/pinned_tile.dart';
import 'package:android_tile_launcher/model/settings.dart';
import 'package:android_tile_launcher/model/tile.dart';
import 'package:android_tile_launcher/model/tile_layout.dart';
import 'package:android_tile_launcher/model/tile_size.dart';
import 'package:android_tile_launcher/services/settings_state.dart';
import 'package:android_tile_launcher/ui/app_tile_grid.dart';
import 'package:android_tile_launcher/ui/editable_tile_grid.dart';
import 'package:android_tile_launcher/ui/settings_scope.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:android_tile_launcher/ui/tile_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_tile_services.dart';
import '../fakes/in_memory_local_store.dart';

Tile _tile(String id, TileSize size) =>
    Tile(id: id, size: size, colour: C64Colour.red);

void main() {
  group('TileSize.spanIn', () {
    test('small is one column and medium two, whatever the width', () {
      expect(TileSize.small.spanIn(4), 1);
      expect(TileSize.small.spanIn(6), 1);
      expect(TileSize.medium.spanIn(4), 2);
      expect(TileSize.medium.spanIn(6), 2);
    });

    test('wide and large take the full width', () {
      expect(TileSize.wide.spanIn(4), 4);
      expect(TileSize.wide.spanIn(6), 6);
      expect(TileSize.large.spanIn(4), 4);
      expect(TileSize.large.spanIn(6), 6);
    });

    test('nothing is wider than the mosaic', () {
      expect(TileSize.medium.spanIn(1), 1);
    });
  });

  group('packTiles on six columns', () {
    test('six small tiles fill a row', () {
      final List<PlacedTile> placed = packTiles(<Tile>[
        for (int i = 0; i < 7; i++) _tile('$i', TileSize.small),
      ], columns: 6);

      expect(placed.map((PlacedTile p) => (p.column, p.row)), <(int, int)>[
        (0, 0),
        (1, 0),
        (2, 0),
        (3, 0),
        (4, 0),
        (5, 0),
        (0, 1),
      ]);
    });

    test('a wide tile takes a whole row and has that span', () {
      final List<PlacedTile> placed = packTiles(<Tile>[
        _tile('a', TileSize.small),
        _tile('wide', TileSize.wide),
      ], columns: 6);

      expect(placed[1].column, 0);
      expect(placed[1].span, 6);
      // Below the small one, not beside it.
      expect(placed[1].row, 1);
    });

    test('medium tiles sit three across', () {
      final List<PlacedTile> placed = packTiles(<Tile>[
        for (int i = 0; i < 3; i++) _tile('$i', TileSize.medium),
      ], columns: 6);

      expect(placed.map((PlacedTile p) => p.column), <int>[0, 2, 4]);
      expect(totalRows(placed), 2);
    });

    test('four columns are still the default', () {
      final List<PlacedTile> placed = packTiles(<Tile>[
        for (int i = 0; i < 5; i++) _tile('$i', TileSize.small),
      ]);

      expect(placed.last.row, 1);
      expect(placed[3].column, 3);
    });
  });

  group('layoutTiles', () {
    test('the gap is between tiles, and cells fill the width', () {
      final List<PlacedTile> placed = packTiles(<Tile>[
        for (int i = 0; i < 6; i++) _tile('$i', TileSize.small),
      ], columns: 6);

      final List<TileRect> rects = layoutTiles(
        placed,
        maxWidth: 400,
        columns: 6,
        gap: 4,
      );

      // (400 - 5 gaps of 4) / 6
      final double cell = (400 - 20) / 6;
      expect(rects.first.width, closeTo(cell, 0.001));
      expect(rects[1].left, closeTo(cell + 4, 0.001));
      expect(rects.last.left + rects.last.width, closeTo(400, 0.001));
    });

    test('a wide tile is the whole width, on either grid', () {
      for (final int columns in <int>[4, 6]) {
        final List<PlacedTile> placed = packTiles(<Tile>[
          _tile('wide', TileSize.wide),
        ], columns: columns);

        final List<TileRect> rects = layoutTiles(
          placed,
          maxWidth: 360,
          columns: columns,
          gap: 8,
        );

        expect(rects.single.width, closeTo(360, 0.001), reason: '$columns');
      }
    });

    test('a bigger gap makes smaller cells and a taller grid', () {
      final List<PlacedTile> placed = packTiles(<Tile>[
        for (int i = 0; i < 8; i++) _tile('$i', TileSize.small),
      ]);

      final double tight = gridHeight(placed, maxWidth: 400, gap: 4);
      final double relaxed = gridHeight(placed, maxWidth: 400, gap: 14);

      expect(
        layoutTiles(placed, maxWidth: 400, gap: 14).first.width,
        lessThan(layoutTiles(placed, maxWidth: 400, gap: 4).first.width),
      );
      // Two rows either way: the height is two cells and a gap.
      expect(tight, isNot(relaxed));
    });

    test('the defaults are four columns and an 8 pixel gap', () {
      final List<PlacedTile> placed = packTiles(<Tile>[
        _tile('a', TileSize.small),
        _tile('b', TileSize.small),
      ]);

      final List<TileRect> rects = layoutTiles(placed, maxWidth: 392);

      // (392 - 3 * 8) / 4
      expect(rects.first.width, closeTo(92, 0.001));
      expect(rects[1].left, closeTo(100, 0.001));
    });
  });

  group('the home grid follows the settings', () {
    Future<SettingsState> pump(
      WidgetTester tester,
      LauncherSettings settings,
      List<Tile> tiles,
    ) async {
      tester.view
        ..physicalSize = const Size(400, 800)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final SettingsState state = SettingsState(store: InMemoryLocalStore());
      await state.update(settings);
      await tester.pumpWidget(
        SettingsScope(
          state: state,
          child: MaterialApp(
            theme: tileLauncherTheme(),
            home: Scaffold(
              body: AppTileGrid(
                tiles: tiles,
                labelFor: (Tile t) => t.id,
                services: fakeTileServices(),
                emptyMessage: 'empty',
                onLaunch: (_) {},
                onRefresh: () async {},
              ),
            ),
          ),
        ),
      );
      return state;
    }

    Size sizeOf(WidgetTester tester, String id) =>
        tester.getSize(find.byKey(ValueKey<String>(id)));

    testWidgets('four columns and the normal gap by default', (
      WidgetTester tester,
    ) async {
      await pump(tester, const LauncherSettings(), <Tile>[
        _tile('a', TileSize.small),
      ]);

      // Room for the margin either side: (400 - 24 - 3 * 8) / 4
      expect(sizeOf(tester, 'a').width, closeTo(88, 0.01));
    });

    testWidgets('six columns make the tiles narrower', (
      WidgetTester tester,
    ) async {
      await pump(tester, const LauncherSettings(columns: 6), <Tile>[
        _tile('a', TileSize.small),
      ]);

      // (400 - 24 - 5 * 8) / 6
      expect(sizeOf(tester, 'a').width, closeTo(56, 0.01));
    });

    testWidgets('a tighter gap makes them bigger', (WidgetTester tester) async {
      await pump(tester, const LauncherSettings(gap: GridGap.tight), <Tile>[
        _tile('a', TileSize.small),
      ]);

      // (400 - 24 - 3 * 4) / 4
      expect(sizeOf(tester, 'a').width, closeTo(91, 0.01));
    });

    testWidgets('a wide tile is the full width on six columns too', (
      WidgetTester tester,
    ) async {
      await pump(tester, const LauncherSettings(columns: 6), <Tile>[
        _tile('w', TileSize.wide),
      ]);

      expect(sizeOf(tester, 'w').width, closeTo(376, 0.01));
    });

    testWidgets('changing the setting re-lays the grid out at once', (
      WidgetTester tester,
    ) async {
      final SettingsState state = await pump(
        tester,
        const LauncherSettings(),
        <Tile>[_tile('a', TileSize.small)],
      );

      await state.update(const LauncherSettings(columns: 6));
      await tester.pump();

      expect(sizeOf(tester, 'a').width, closeTo(56, 0.01));
    });
  });

  testWidgets('the grid editor follows the settings too', (
    WidgetTester tester,
  ) async {
    tester.view
      ..physicalSize = const Size(400, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final SettingsState state = SettingsState(store: InMemoryLocalStore());
    await state.update(
      const LauncherSettings(columns: 6, gap: GridGap.relaxed),
    );
    await tester.pumpWidget(
      SettingsScope(
        state: state,
        child: MaterialApp(
          theme: tileLauncherTheme(),
          home: Scaffold(
            body: EditableTileGrid(
              tiles: <PinnedTile>[
                const PinnedTile(
                  id: 'a',
                  size: TileSize.small,
                  colour: C64Colour.red,
                ),
              ],
              labelFor: (String id) => id,
              services: fakeTileServices(),
              selected: null,
              onSelect: (_) {},
              onDelete: (_) {},
              onReorder: (_, _, _) {},
            ),
          ),
        ),
      ),
    );

    // (400 - 5 * 14) / 6
    expect(
      tester.getSize(find.byKey(const ValueKey<String>('a'))).width,
      closeTo(55, 0.01),
    );
  });
}

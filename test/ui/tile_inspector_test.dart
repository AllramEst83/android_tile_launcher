import 'package:android_tile_launcher/model/c64_colour.dart';
import 'package:android_tile_launcher/model/pinned_tile.dart';
import 'package:android_tile_launcher/model/settings.dart';
import 'package:android_tile_launcher/model/tile_size.dart';
import 'package:android_tile_launcher/services/settings_state.dart';
import 'package:android_tile_launcher/ui/settings_scope.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:android_tile_launcher/ui/tile_inspector.dart';
import 'package:android_tile_launcher/ui/tile_size_grid_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/in_memory_local_store.dart';

Future<void> _pump(
  WidgetTester tester, {
  required TileSize size,
  required int columns,
}) async {
  tester.view
    ..physicalSize = const Size(400, 900)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final SettingsState settings = SettingsState(store: InMemoryLocalStore());
  await settings.update(LauncherSettings(columns: columns));
  await tester.pumpWidget(
    SettingsScope(
      state: settings,
      child: MaterialApp(
        theme: tileLauncherTheme(),
        home: Material(
          child: SingleChildScrollView(
            child: TileInspector(
              label: 'Clock',
              tile: PinnedTile(id: 'clock', size: size, colour: C64Colour.red),
              onApply: () {},
              onSizeSelected: (TileSize _) {},
              onColourSelected: (C64Colour _) {},
            ),
          ),
        ),
      ),
    ),
  );
}

bool _filled(WidgetTester tester, int columns, int rows) {
  final DecoratedBox box = tester.widget<DecoratedBox>(
    find.descendant(
      of: find.byKey(sizeGridCellKey(columns, rows)),
      matching: find.byType(DecoratedBox),
    ),
  );
  return (box.decoration as BoxDecoration).color == TileColors.accent;
}

void main() {
  group('the size panel mirrors the width the grid really draws', () {
    testWidgets('a 6-wide tile on 4 columns reads and paints 4 wide', (
      WidgetTester tester,
    ) async {
      await _pump(tester, size: TileSize.size6x2, columns: 4);

      expect(find.text('4 × 2'), findsOneWidget);
      expect(_filled(tester, 4, 2), isTrue);
      expect(find.byKey(sizeGridCellKey(5, 1)), findsNothing);
    });

    testWidgets('a full-width wide tile on 6 columns reads and paints 6 wide', (
      WidgetTester tester,
    ) async {
      await _pump(tester, size: TileSize.wide, columns: 6);

      expect(find.text('6 × 2'), findsOneWidget);
      expect(_filled(tester, 6, 2), isTrue);
    });
  });
}

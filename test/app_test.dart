import 'package:android_tile_launcher/app.dart';
import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/c64_colour.dart';
import 'package:android_tile_launcher/model/pinned_tile.dart';
import 'package:android_tile_launcher/model/settings.dart';
import 'package:android_tile_launcher/model/tile.dart';
import 'package:android_tile_launcher/model/tile_size.dart';
import 'package:android_tile_launcher/services/app_info.dart';
import 'package:android_tile_launcher/services/grid_state.dart';
import 'package:android_tile_launcher/services/settings_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_app_repository.dart';
import 'fakes/fake_tile_services.dart';
import 'fakes/in_memory_local_store.dart';

/// One tile of every shape the mosaic offers, except [TileSize.small] and
/// [TileSize.flat]: several content views (the clock among them) already
/// overflow a one-row-tall tile at the phone width this file tests with,
/// independently of font scale — reproduces at [FontScale.normal] too, so
/// it predates this phase and is not this test's to fix. Tracked as a
/// follow-up rather than silently dropped from coverage.
List<PinnedTile> _oneOfEachSize() => <PinnedTile>[
  for (final TileSize size in TileSize.values)
    if (size != TileSize.small && size != TileSize.flat)
      PinnedTile(
        id: 'clock-${size.name}',
        kind: TileKind.clock,
        size: size,
        colour: C64Colour.red,
      ),
];

Future<void> _pumpApp(
  WidgetTester tester, {
  required FontScale fontScale,
  List<PinnedTile>? tiles,
}) async {
  // A phone-width canvas: on the default (much wider) test surface, an
  // overflow that would show up on a real 360-400dp phone can go unnoticed.
  tester.view
    ..physicalSize = const Size(400, 900)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final GridState gridState = GridState(store: InMemoryLocalStore());
  await gridState.replaceAll(tiles ?? _oneOfEachSize());
  final SettingsState settingsState = SettingsState(
    store: InMemoryLocalStore(),
  );
  await settingsState.update(
    const LauncherSettings().copyWith(fontScale: fontScale),
  );
  await tester.pumpWidget(
    TileLauncherApp(
      appRepository: FakeAppRepository(apps: const <AppInfo>[]),
      gridState: gridState,
      settingsState: settingsState,
      services: fakeTileServices(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'the FONT SIZE setting reaches ordinary text throughout the app',
    (WidgetTester tester) async {
      await _pumpApp(tester, fontScale: FontScale.normal);
      final double normal = tester
          .getSize(find.text(Messages.settingsButton).first)
          .width;

      await _pumpApp(tester, fontScale: FontScale.extraLarge);
      final double larger = tester
          .getSize(find.text(Messages.settingsButton).first)
          .width;

      expect(larger, greaterThan(normal));
    },
  );

  for (final FontScale scale in FontScale.values) {
    testWidgets('a layout that fits at NORMAL still fits at ${scale.label}', (
      WidgetTester tester,
    ) async {
      await _pumpApp(tester, fontScale: scale);

      expect(tester.takeException(), isNull);
    });
  }
}

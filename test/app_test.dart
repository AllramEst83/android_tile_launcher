import 'package:android_tile_launcher/app.dart';
import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/bluetooth_status.dart';
import 'package:android_tile_launcher/model/c64_colour.dart';
import 'package:android_tile_launcher/model/pinned_tile.dart';
import 'package:android_tile_launcher/model/settings.dart';
import 'package:android_tile_launcher/model/tile.dart';
import 'package:android_tile_launcher/model/tile_size.dart';
import 'package:android_tile_launcher/services/app_info.dart';
import 'package:android_tile_launcher/services/grid_state.dart';
import 'package:android_tile_launcher/services/settings_state.dart';
import 'package:android_tile_launcher/services/tile_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_app_repository.dart';
import 'fakes/fake_bluetooth_service.dart';
import 'fakes/fake_tile_services.dart';
import 'fakes/in_memory_local_store.dart';

/// One tile of every shape the mosaic offers, including the one-row-tall
/// sizes ([TileSize.small], [TileSize.flat], and now [TileSize.size3x1] and
/// [TileSize.size4x1]): the clock content view used to overflow those at the
/// phone width this file tests with, independently of font scale, and was
/// excluded here rather than fixed. Phase 35 fixed it (the time is now
/// `Flexible` around its own `FittedBox`, and the date line drops first on a
/// tile too short for both), so every size is exercised.
List<PinnedTile> _oneOfEachSize() => <PinnedTile>[
  for (final TileSize size in TileSize.values)
    PinnedTile(
      id: 'clock-${size.name}',
      kind: TileKind.clock,
      size: size,
      colour: C64Colour.red,
    ),
];

/// Every kind at every size — every [TileKind] by 24 sizes, one flat list
/// rather than
/// one pump per combination, the same trick [_oneOfEachSize] already uses.
/// Phase 35's new one-row-tall widths ([TileSize.size3x1], [TileSize.size4x1])
/// prompted the question for the clock specifically; this checks every other
/// kind reacts the same width-agnostic way to a short tile instead of
/// assuming it from the mail/weather/agenda tiles' own past fixes.
List<PinnedTile> _oneOfEachKindAndSize() => <PinnedTile>[
  for (final TileKind kind in TileKind.values)
    for (final TileSize size in TileSize.values)
      PinnedTile(
        id: switch (kind) {
          TileKind.app => 'com.example.unknown.${size.name}',
          TileKind.contact => contactTileId('c-${size.name}'),
          _ => '${kind.name}-${size.name}',
        },
        kind: kind,
        size: size,
        colour: C64Colour.red,
        label: switch (kind) {
          TileKind.app || TileKind.contact => 'Test',
          _ => null,
        },
      ),
];

Future<void> _pumpApp(
  WidgetTester tester, {
  required FontScale fontScale,
  List<PinnedTile>? tiles,
  TileServices? services,
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
      services: services ?? fakeTileServices(),
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

  testWidgets('every kind fits at every size, at EXTRA LARGE', (
    WidgetTester tester,
  ) async {
    // Connected devices, not just the bare ON/OFF state, so the Bluetooth
    // tile's own device-list layout is exercised at every size here too.
    final FakeBluetoothService bluetooth = FakeBluetoothService()
      ..statusResult = BluetoothOn(<PairedDevice>[
        for (int i = 0; i < 5; i++)
          PairedDevice(
            name: 'Device $i with a fairly long name',
            address: '$i',
            connected: true,
          ),
      ]);
    await _pumpApp(
      tester,
      fontScale: FontScale.extraLarge,
      tiles: _oneOfEachKindAndSize(),
      services: fakeTileServices(bluetooth: bluetooth),
    );

    expect(tester.takeException(), isNull);
  });
}

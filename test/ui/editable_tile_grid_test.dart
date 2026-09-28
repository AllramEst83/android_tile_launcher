import 'package:android_tile_launcher/model/c64_colour.dart';
import 'package:android_tile_launcher/model/pinned_tile.dart';
import 'package:android_tile_launcher/model/tile_size.dart';
import 'package:android_tile_launcher/services/tile_services.dart';
import 'package:android_tile_launcher/ui/editable_tile_grid.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_agenda_repository.dart';
import '../fakes/fake_device_repository.dart';
import '../fakes/fake_system_control_service.dart';
import '../fakes/fake_weather_repository.dart';

final TileServices _services = TileServices(
  systemControl: FakeSystemControlService(),
  device: FakeDeviceRepository(),
  weather: FakeWeatherRepository(),
  agenda: FakeAgendaRepository(),
);

/// [count] tiles of [size]. Large ones are a full grid width square, so a few
/// of them are far taller than the viewport the tests give them.
List<PinnedTile> _tiles(int count, {TileSize size = TileSize.large}) =>
    <PinnedTile>[
      for (int i = 0; i < count; i++)
        PinnedTile(
          id: 'app$i',
          size: size,
          colour: C64Colour.values[i % C64Colour.values.length],
        ),
    ];

/// A 400x600 scrolling viewport, as the editor has above its inspector panel.
Future<ScrollController> _pump(
  WidgetTester tester,
  List<PinnedTile> tiles,
  List<(String, String)> reorders,
) async {
  final ScrollController controller = ScrollController();
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    MaterialApp(
      theme: tileLauncherTheme(),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 400,
            height: 600,
            child: SingleChildScrollView(
              controller: controller,
              padding: const EdgeInsets.all(TileMetrics.margin),
              child: EditableTileGrid(
                tiles: tiles,
                labelFor: (String id) => id.toUpperCase(),
                services: _services,
                selected: null,
                onSelect: (_) {},
                onDelete: (_) {},
                onReorder: (String moving, String target) =>
                    reorders.add((moving, target)),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  return controller;
}

Future<void> _hold(WidgetTester tester, TestGesture gesture) => tester.pump(
  EditableTileGrid.pickUpDelay + const Duration(milliseconds: 50),
);

void main() {
  testWidgets('holding a tile and dropping it on another reorders', (
    WidgetTester tester,
  ) async {
    final List<(String, String)> reorders = <(String, String)>[];
    await _pump(tester, _tiles(2, size: TileSize.small), reorders);

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('app0'))),
    );
    await _hold(tester, gesture);
    await gesture.moveTo(tester.getCenter(find.byKey(const ValueKey('app1'))));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(reorders, <(String, String)>[('app0', 'app1')]);
  });

  testWidgets('the tile a held one is over is framed, and only then', (
    WidgetTester tester,
  ) async {
    await _pump(tester, _tiles(2, size: TileSize.small), <(String, String)>[]);
    Finder framed() => find.byWidgetPredicate(
      (Widget w) => w is Container && w.foregroundDecoration != null,
    );
    expect(framed(), findsNothing);

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('app0'))),
    );
    await _hold(tester, gesture);
    await gesture.moveTo(tester.getCenter(find.byKey(const ValueKey('app1'))));
    await tester.pump();

    expect(framed(), findsOneWidget);

    await gesture.up();
    await tester.pumpAndSettle();

    expect(framed(), findsNothing);
  });

  testWidgets('a plain drag scrolls the grid and moves nothing', (
    WidgetTester tester,
  ) async {
    final List<(String, String)> reorders = <(String, String)>[];
    final ScrollController controller = await _pump(
      tester,
      _tiles(4),
      reorders,
    );

    await tester.drag(find.text('APP0'), const Offset(0, -200));
    await tester.pumpAndSettle();

    expect(controller.offset, greaterThan(0));
    expect(reorders, isEmpty);
  });

  testWidgets('a held tile near the bottom edge scrolls the grid down', (
    WidgetTester tester,
  ) async {
    final List<(String, String)> reorders = <(String, String)>[];
    final ScrollController controller = await _pump(
      tester,
      _tiles(4),
      reorders,
    );
    expect(controller.offset, 0);

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.text('APP0')),
    );
    await _hold(tester, gesture);
    // Into the bottom edge zone of the 600px viewport.
    await gesture.moveTo(const Offset(200, 590));
    await tester.pump(const Duration(milliseconds: 500));

    expect(controller.offset, greaterThan(100));

    // Let go: the scrolling stops (a running timer would fail the test).
    await gesture.up();
    await tester.pumpAndSettle();
    final double stopped = controller.offset;
    await tester.pump(const Duration(milliseconds: 200));

    expect(controller.offset, stopped);
  });

  testWidgets('a held tile near the top edge scrolls back up', (
    WidgetTester tester,
  ) async {
    final ScrollController controller = await _pump(
      tester,
      _tiles(4),
      <(String, String)>[],
    );
    controller.jumpTo(600);
    await tester.pump();
    final double before = controller.offset;

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.text('APP1')),
    );
    await _hold(tester, gesture);
    await gesture.moveTo(const Offset(200, 8));
    await tester.pump(const Duration(milliseconds: 500));

    expect(controller.offset, lessThan(before));

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('a held tile in the middle of the screen does not scroll', (
    WidgetTester tester,
  ) async {
    final ScrollController controller = await _pump(
      tester,
      _tiles(4),
      <(String, String)>[],
    );

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.text('APP0')),
    );
    await _hold(tester, gesture);
    await gesture.moveTo(const Offset(200, 300));
    await tester.pump(const Duration(milliseconds: 500));

    expect(controller.offset, 0);

    await gesture.up();
    await tester.pumpAndSettle();
  });
}

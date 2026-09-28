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
  List<(String, String, bool)> reorders,
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
                onReorder: (String moving, String target, bool after) =>
                    reorders.add((moving, target, after)),
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
  /// Holds `from` and moves the finger to [target]'s left or right side.
  Future<TestGesture> holdAndHover(
    WidgetTester tester, {
    required String from,
    required String target,
    required bool rightSide,
  }) async {
    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.byKey(ValueKey(from))),
    );
    await _hold(tester, gesture);
    final Rect rect = tester.getRect(find.byKey(ValueKey(target)));
    await gesture.moveTo(
      Offset(rightSide ? rect.right - 8 : rect.left + 8, rect.center.dy),
    );
    await tester.pump();
    return gesture;
  }

  testWidgets('dropped on the right half of a tile: goes after it', (
    WidgetTester tester,
  ) async {
    final List<(String, String, bool)> reorders = <(String, String, bool)>[];
    await _pump(tester, _tiles(2, size: TileSize.small), reorders);

    final TestGesture gesture = await holdAndHover(
      tester,
      from: 'app0',
      target: 'app1',
      rightSide: true,
    );
    await gesture.up();
    await tester.pumpAndSettle();

    expect(reorders, <(String, String, bool)>[('app0', 'app1', true)]);
  });

  testWidgets('dropped on the left half of a tile: goes before it', (
    WidgetTester tester,
  ) async {
    final List<(String, String, bool)> reorders = <(String, String, bool)>[];
    await _pump(tester, _tiles(2, size: TileSize.small), reorders);

    final TestGesture gesture = await holdAndHover(
      tester,
      from: 'app1',
      target: 'app0',
      rightSide: false,
    );
    await gesture.up();
    await tester.pumpAndSettle();

    expect(reorders, <(String, String, bool)>[('app1', 'app0', false)]);
  });

  group('the insertion line', () {
    Finder line() => find.byKey(const ValueKey('drop-line'));

    testWidgets('is on the near side of the tile, in the gutter', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        _tiles(3, size: TileSize.small),
        <(String, String, bool)>[],
      );
      expect(line(), findsNothing);
      final Rect target = tester.getRect(find.byKey(const ValueKey('app1')));

      final TestGesture gesture = await holdAndHover(
        tester,
        from: 'app0',
        target: 'app1',
        rightSide: false,
      );

      expect(line(), findsOneWidget);
      expect(
        tester.getCenter(line()).dx,
        closeTo(target.left - TileMetrics.gutter / 2, 0.5),
      );
      expect(tester.getSize(line()).height, target.height);

      await gesture.moveTo(Offset(target.right - 8, target.center.dy));
      await tester.pump();

      expect(line(), findsOneWidget);
      expect(
        tester.getCenter(line()).dx,
        closeTo(target.right + TileMetrics.gutter / 2, 0.5),
      );

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('goes when the tile is dropped', (WidgetTester tester) async {
      await _pump(
        tester,
        _tiles(2, size: TileSize.small),
        <(String, String, bool)>[],
      );

      final TestGesture gesture = await holdAndHover(
        tester,
        from: 'app0',
        target: 'app1',
        rightSide: true,
      );
      expect(line(), findsOneWidget);
      await gesture.up();
      await tester.pumpAndSettle();

      expect(line(), findsNothing);
    });

    testWidgets('goes when the held tile leaves every tile', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        _tiles(2, size: TileSize.small),
        <(String, String, bool)>[],
      );

      final TestGesture gesture = await holdAndHover(
        tester,
        from: 'app0',
        target: 'app1',
        rightSide: true,
      );
      // Into the empty canvas to the right of both tiles.
      await gesture.moveTo(const Offset(380, 300));
      await tester.pump();

      expect(line(), findsNothing);

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('is not shown over the tile being held itself', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        _tiles(2, size: TileSize.small),
        <(String, String, bool)>[],
      );

      final TestGesture gesture = await holdAndHover(
        tester,
        from: 'app0',
        target: 'app0',
        rightSide: true,
      );

      expect(line(), findsNothing);

      await gesture.up();
      await tester.pumpAndSettle();
    });
  });

  testWidgets('a plain drag scrolls the grid and moves nothing', (
    WidgetTester tester,
  ) async {
    final List<(String, String, bool)> reorders = <(String, String, bool)>[];
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
    final List<(String, String, bool)> reorders = <(String, String, bool)>[];
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
      <(String, String, bool)>[],
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
      <(String, String, bool)>[],
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

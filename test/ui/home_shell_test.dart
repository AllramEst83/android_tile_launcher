import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/c64_colour.dart';
import 'package:android_tile_launcher/model/tile_size.dart';
import 'package:android_tile_launcher/services/app_info.dart';
import 'package:android_tile_launcher/services/grid_state.dart';
import 'package:android_tile_launcher/ui/app_drawer.dart';
import 'package:android_tile_launcher/ui/app_tile_grid.dart';
import 'package:android_tile_launcher/ui/editable_tile_grid.dart';
import 'package:android_tile_launcher/ui/home_shell.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_app_repository.dart';
import '../fakes/in_memory_local_store.dart';

Finder _onHome(Finder matching) =>
    find.descendant(of: find.byType(AppTileGrid), matching: matching);

Finder _inDrawer(Finder matching) =>
    find.descendant(of: find.byType(AppDrawer), matching: matching);

Finder _inEditor(Finder matching) =>
    find.descendant(of: find.byType(EditableTileGrid), matching: matching);

GridState _gridState() => GridState(store: InMemoryLocalStore());

Future<void> pumpShell(
  WidgetTester tester,
  FakeAppRepository repository, {
  GridState? gridState,
}) => tester.pumpWidget(
  MaterialApp(
    theme: tileLauncherTheme(),
    home: HomeShell(
      appRepository: repository,
      gridState: gridState ?? _gridState(),
    ),
  ),
);

Future<void> _swipeToDrawer(WidgetTester tester) async {
  await tester.drag(find.byType(PageView), const Offset(-600, 0));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('boot screen shows while the app list is still loading', (
    WidgetTester tester,
  ) async {
    await pumpShell(tester, FakeAppRepository());

    expect(find.text(Messages.bootBanner), findsOneWidget);
    expect(find.text(Messages.bootReady), findsOneWidget);
  });

  testWidgets('back never leaves the launcher', (WidgetTester tester) async {
    await pumpShell(tester, FakeAppRepository());

    expect(
      find.byWidgetPredicate((Widget w) => w is PopScope && !w.canPop),
      findsOneWidget,
    );
  });

  testWidgets('a listing failure shows the error line', (
    WidgetTester tester,
  ) async {
    await pumpShell(tester, FakeAppRepository(listError: Exception('boom')));
    await tester.pump();

    expect(find.text(Messages.appListError), findsOneWidget);
  });

  testWidgets('home says so when nothing is pinned yet', (
    WidgetTester tester,
  ) async {
    await pumpShell(
      tester,
      FakeAppRepository(
        apps: const [AppInfo(label: 'Clock', packageName: 'pkg.clock')],
      ),
    );
    await tester.pump();

    expect(_onHome(find.text(Messages.nothingPinned)), findsOneWidget);
    expect(_onHome(find.text('CLOCK')), findsNothing);
  });

  testWidgets('home shows a tile for each pinned app', (
    WidgetTester tester,
  ) async {
    final GridState gridState = _gridState();
    await gridState.pin('pkg.clock');
    await pumpShell(
      tester,
      FakeAppRepository(
        apps: const [
          AppInfo(label: 'Clock', packageName: 'pkg.clock'),
          AppInfo(label: 'Maps', packageName: 'pkg.maps'),
        ],
      ),
      gridState: gridState,
    );
    await tester.pump();

    expect(_onHome(find.text('CLOCK')), findsOneWidget);
    expect(_onHome(find.text('MAPS')), findsNothing);
  });

  testWidgets('swiping left reveals every installed app in the drawer', (
    WidgetTester tester,
  ) async {
    await pumpShell(
      tester,
      FakeAppRepository(
        apps: const [
          AppInfo(label: 'Clock', packageName: 'pkg.clock'),
          AppInfo(label: 'Maps', packageName: 'pkg.maps'),
        ],
      ),
    );
    await tester.pump();

    await _swipeToDrawer(tester);

    expect(_inDrawer(find.text('CLOCK')), findsOneWidget);
    expect(_inDrawer(find.text('MAPS')), findsOneWidget);
  });

  testWidgets('pinning from the drawer adds a tile to home', (
    WidgetTester tester,
  ) async {
    await pumpShell(
      tester,
      FakeAppRepository(
        apps: const [AppInfo(label: 'Clock', packageName: 'pkg.clock')],
      ),
    );
    await tester.pump();

    await _swipeToDrawer(tester);
    await tester.longPress(_inDrawer(find.text('CLOCK')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Messages.pinToGrid));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(PageView), const Offset(600, 0));
    await tester.pumpAndSettle();

    expect(_onHome(find.text('CLOCK')), findsOneWidget);
  });

  testWidgets('pulling down on home asks the repository for a refresh', (
    WidgetTester tester,
  ) async {
    final GridState gridState = _gridState();
    await gridState.pin('pkg.clock');
    final FakeAppRepository repository = FakeAppRepository(
      apps: const [AppInfo(label: 'Clock', packageName: 'pkg.clock')],
    );
    await pumpShell(tester, repository, gridState: gridState);
    await tester.pump();

    await tester.fling(
      _onHome(find.byType(SingleChildScrollView)),
      const Offset(0, 300),
      1000,
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(repository.refreshCalls, 1);
  });

  group('grid editor', () {
    Future<GridState> pinTwo(WidgetTester tester) async {
      final GridState gridState = _gridState();
      await gridState.pin('pkg.clock');
      await gridState.pin('pkg.maps');
      await pumpShell(
        tester,
        FakeAppRepository(
          apps: const [
            AppInfo(label: 'Clock', packageName: 'pkg.clock'),
            AppInfo(label: 'Maps', packageName: 'pkg.maps'),
          ],
        ),
        gridState: gridState,
      );
      await tester.pump();
      return gridState;
    }

    testWidgets('long-pressing a tile enters the editor with it selected', (
      WidgetTester tester,
    ) async {
      await pinTwo(tester);

      await tester.longPress(_onHome(find.text('CLOCK')));
      await tester.pumpAndSettle();

      expect(find.text(Messages.cancel), findsOneWidget);
      expect(find.text(Messages.apply), findsOneWidget);
      expect(find.text(Messages.tileSize), findsOneWidget);
      expect(find.text(Messages.tileColour), findsOneWidget);
    });

    testWidgets('cancel discards every staged change', (
      WidgetTester tester,
    ) async {
      final GridState gridState = await pinTwo(tester);

      await tester.longPress(_onHome(find.text('CLOCK')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('delete-pkg.clock')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(Messages.cancel));
      await tester.pumpAndSettle();

      expect(gridState.pinned.map((p) => p.packageName), [
        'pkg.clock',
        'pkg.maps',
      ]);
      expect(find.text(Messages.apply), findsNothing);
      expect(_onHome(find.text('CLOCK')), findsOneWidget);
    });

    testWidgets('apply commits a delete', (WidgetTester tester) async {
      final GridState gridState = await pinTwo(tester);

      await tester.longPress(_onHome(find.text('CLOCK')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('delete-pkg.clock')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(Messages.apply));
      await tester.pumpAndSettle();

      expect(gridState.pinned.map((p) => p.packageName), ['pkg.maps']);
    });

    testWidgets('apply commits a resize', (WidgetTester tester) async {
      final GridState gridState = await pinTwo(tester);

      await tester.longPress(_onHome(find.text('CLOCK')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2x2'));
      await tester.pump();
      await tester.tap(find.text(Messages.apply));
      await tester.pumpAndSettle();

      final clock = gridState.pinned.firstWhere(
        (p) => p.packageName == 'pkg.clock',
      );
      expect(clock.size, TileSize.medium);
    });

    testWidgets('apply commits a recolour', (WidgetTester tester) async {
      final GridState gridState = await pinTwo(tester);

      await tester.longPress(_onHome(find.text('CLOCK')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey(C64Colour.orange)));
      await tester.pump();
      await tester.tap(find.text(Messages.apply));
      await tester.pumpAndSettle();

      final clock = gridState.pinned.firstWhere(
        (p) => p.packageName == 'pkg.clock',
      );
      expect(clock.colour, C64Colour.orange);
    });

    testWidgets('dragging a tile onto another reorders them on apply', (
      WidgetTester tester,
    ) async {
      final GridState gridState = await pinTwo(tester);

      await tester.longPress(_onHome(find.text('CLOCK')));
      await tester.pumpAndSettle();

      final Offset from = tester.getCenter(_inEditor(find.text('MAPS')));
      final Offset to = tester.getCenter(_inEditor(find.text('CLOCK')));
      final TestGesture gesture = await tester.startGesture(from);
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.moveTo(to);
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.up();
      await tester.pumpAndSettle();
      await tester.tap(find.text(Messages.apply));
      await tester.pumpAndSettle();

      expect(gridState.pinned.map((p) => p.packageName), [
        'pkg.maps',
        'pkg.clock',
      ]);
    });
  });
}

import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/services/app_info.dart';
import 'package:android_tile_launcher/services/grid_state.dart';
import 'package:android_tile_launcher/ui/app_drawer.dart';
import 'package:android_tile_launcher/ui/app_tile_grid.dart';
import 'package:android_tile_launcher/ui/home_shell.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_app_repository.dart';

Finder _onHome(Finder matching) =>
    find.descendant(of: find.byType(AppTileGrid), matching: matching);

Finder _inDrawer(Finder matching) =>
    find.descendant(of: find.byType(AppDrawer), matching: matching);

Future<void> pumpShell(
  WidgetTester tester,
  FakeAppRepository repository, {
  GridState? gridState,
}) => tester.pumpWidget(
  MaterialApp(
    theme: tileLauncherTheme(),
    home: HomeShell(
      appRepository: repository,
      gridState: gridState ?? GridState(),
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
    final GridState gridState = GridState()..pin('pkg.clock');
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
    final GridState gridState = GridState()..pin('pkg.clock');
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
}

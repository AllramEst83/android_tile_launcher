import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/services/app_info.dart';
import 'package:android_tile_launcher/services/grid_state.dart';
import 'package:android_tile_launcher/ui/app_drawer.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/in_memory_local_store.dart';

const List<AppInfo> _apps = [
  AppInfo(label: 'Clock', packageName: 'pkg.clock'),
  AppInfo(label: 'Maps', packageName: 'pkg.maps'),
];

GridState _gridState() => GridState(store: InMemoryLocalStore());

Future<void> _pump(
  WidgetTester tester, {
  List<AppInfo> apps = _apps,
  GridState? gridState,
  ValueChanged<String>? onLaunch,
  Future<bool> Function(String)? onOpenDetails,
  Future<bool> Function(String)? onUninstall,
}) => tester.pumpWidget(
  MaterialApp(
    theme: tileLauncherTheme(),
    home: Scaffold(
      body: AppDrawer(
        apps: apps,
        gridState: gridState ?? _gridState(),
        onLaunch: onLaunch ?? (_) {},
        onOpenDetails: onOpenDetails ?? (_) async => true,
        onUninstall: onUninstall ?? (_) async => true,
      ),
    ),
  ),
);

void main() {
  testWidgets('shows every app grouped by initial with a jump index', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('CLOCK'), findsOneWidget);
    expect(find.text('MAPS'), findsOneWidget);
    // Once as the section header, once as the jump-index button.
    expect(find.text('C'), findsNWidgets(2));
    expect(find.text('M'), findsNWidgets(2));
  });

  testWidgets('typing switches to a ranked flat list with no jump index', (
    tester,
  ) async {
    await _pump(tester);

    await tester.enterText(find.byType(TextField), 'ma');
    await tester.pump();

    expect(find.text('MAPS'), findsOneWidget);
    expect(find.text('CLOCK'), findsNothing);
    // Search mode drops the section headers and the jump index.
    expect(find.text('M'), findsNothing);
  });

  testWidgets('a query that matches nothing says so', (tester) async {
    await _pump(tester);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump();

    expect(find.text(Messages.noSearchResults), findsOneWidget);
  });

  testWidgets('tapping a row launches its package', (tester) async {
    final List<String> launched = [];
    await _pump(tester, onLaunch: launched.add);

    await tester.tap(find.text('CLOCK'));

    expect(launched, ['pkg.clock']);
  });

  testWidgets('long-press offers to pin an unpinned app', (tester) async {
    await _pump(tester);

    await tester.longPress(find.text('CLOCK'));
    await tester.pumpAndSettle();

    expect(find.text(Messages.pinToGrid), findsOneWidget);
    expect(find.text(Messages.unpinFromGrid), findsNothing);
  });

  testWidgets('long-press offers to unpin an already-pinned app', (
    tester,
  ) async {
    final gridState = _gridState();
    await gridState.pin('pkg.clock');
    await _pump(tester, gridState: gridState);

    await tester.longPress(find.text('CLOCK'));
    await tester.pumpAndSettle();

    expect(find.text(Messages.unpinFromGrid), findsOneWidget);
  });

  testWidgets('tapping "pin to grid" pins the app', (tester) async {
    final gridState = _gridState();
    await _pump(tester, gridState: gridState);

    await tester.longPress(find.text('CLOCK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Messages.pinToGrid));
    await tester.pumpAndSettle();

    expect(gridState.isPinned('pkg.clock'), isTrue);
  });

  testWidgets('tapping "app details" opens Android\'s app info screen', (
    tester,
  ) async {
    final List<String> opened = [];
    await _pump(
      tester,
      onOpenDetails: (packageName) async {
        opened.add(packageName);
        return true;
      },
    );

    await tester.longPress(find.text('CLOCK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Messages.appDetails));
    await tester.pumpAndSettle();

    expect(opened, ['pkg.clock']);
  });

  testWidgets('tapping "uninstall" asks the repository to uninstall', (
    tester,
  ) async {
    final List<String> uninstalled = [];
    await _pump(
      tester,
      onUninstall: (packageName) async {
        uninstalled.add(packageName);
        return true;
      },
    );

    await tester.longPress(find.text('CLOCK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Messages.uninstall));
    await tester.pumpAndSettle();

    expect(uninstalled, ['pkg.clock']);
  });
}

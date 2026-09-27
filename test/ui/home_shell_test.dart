import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/services/app_info.dart';
import 'package:android_tile_launcher/ui/home_shell.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_app_repository.dart';

Future<void> pumpShell(WidgetTester tester, FakeAppRepository repository) =>
    tester.pumpWidget(
      MaterialApp(
        theme: tileLauncherTheme(),
        home: HomeShell(appRepository: repository),
      ),
    );

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

  testWidgets('shows a tile per app, labelled uppercase', (
    WidgetTester tester,
  ) async {
    await pumpShell(
      tester,
      FakeAppRepository(
        apps: const [
          AppInfo(label: 'Clock', packageName: 'pkg.clock'),
          AppInfo(label: 'maps', packageName: 'pkg.maps'),
        ],
      ),
    );
    await tester.pump();

    expect(find.text('CLOCK'), findsOneWidget);
    expect(find.text('MAPS'), findsOneWidget);
    expect(find.text(Messages.bootBanner), findsNothing);
  });

  testWidgets('an empty listing says so', (WidgetTester tester) async {
    await pumpShell(tester, FakeAppRepository());
    await tester.pump();

    expect(find.text(Messages.noAppsFound), findsOneWidget);
  });

  testWidgets('a listing failure shows the error line', (
    WidgetTester tester,
  ) async {
    await pumpShell(tester, FakeAppRepository(listError: Exception('boom')));
    await tester.pump();

    expect(find.text(Messages.appListError), findsOneWidget);
  });

  testWidgets('tapping a tile launches its package', (
    WidgetTester tester,
  ) async {
    final FakeAppRepository repository = FakeAppRepository(
      apps: const [AppInfo(label: 'Clock', packageName: 'pkg.clock')],
    );
    await pumpShell(tester, repository);
    await tester.pump();

    await tester.tap(find.text('CLOCK'));

    expect(repository.launched, ['pkg.clock']);
  });

  testWidgets('pulling down asks the repository for a refresh', (
    WidgetTester tester,
  ) async {
    final FakeAppRepository repository = FakeAppRepository(
      apps: const [AppInfo(label: 'Clock', packageName: 'pkg.clock')],
    );
    await pumpShell(tester, repository);
    await tester.pump();

    await tester.fling(
      find.byType(SingleChildScrollView),
      const Offset(0, 300),
      1000,
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(repository.refreshCalls, 1);
  });
}

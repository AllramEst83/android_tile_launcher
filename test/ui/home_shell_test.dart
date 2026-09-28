import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/c64_colour.dart';
import 'package:android_tile_launcher/model/device_status.dart';
import 'package:android_tile_launcher/model/sound_mode.dart';
import 'package:android_tile_launcher/model/tile.dart';
import 'package:android_tile_launcher/model/tile_size.dart';
import 'package:android_tile_launcher/model/weather.dart';
import 'package:android_tile_launcher/model/weather_snapshot.dart';
import 'package:android_tile_launcher/services/app_info.dart';
import 'package:android_tile_launcher/services/grid_state.dart';
import 'package:android_tile_launcher/services/tile_services.dart';
import 'package:android_tile_launcher/ui/app_drawer.dart';
import 'package:android_tile_launcher/ui/app_tile_grid.dart';
import 'package:android_tile_launcher/ui/clock_tile_view.dart';
import 'package:android_tile_launcher/ui/device_tile_view.dart';
import 'package:android_tile_launcher/ui/editable_tile_grid.dart';
import 'package:android_tile_launcher/ui/home_shell.dart';
import 'package:android_tile_launcher/ui/state_tile_view.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:android_tile_launcher/ui/weather_tile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_app_repository.dart';
import '../fakes/fake_device_repository.dart';
import '../fakes/fake_system_control_service.dart';
import '../fakes/fake_weather_repository.dart';
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
  FakeSystemControlService? systemControlService,
  FakeDeviceRepository? deviceRepository,
  FakeWeatherRepository? weatherRepository,
}) => tester.pumpWidget(
  MaterialApp(
    theme: tileLauncherTheme(),
    home: HomeShell(
      appRepository: repository,
      gridState: gridState ?? _gridState(),
      services: TileServices(
        systemControl: systemControlService ?? FakeSystemControlService(),
        device: deviceRepository ?? FakeDeviceRepository(),
        weather: weatherRepository ?? FakeWeatherRepository(),
      ),
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

      expect(gridState.pinned.map((p) => p.id), ['pkg.clock', 'pkg.maps']);
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

      expect(gridState.pinned.map((p) => p.id), ['pkg.maps']);
    });

    testWidgets('apply commits a resize', (WidgetTester tester) async {
      final GridState gridState = await pinTwo(tester);

      await tester.longPress(_onHome(find.text('CLOCK')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2x2'));
      await tester.pump();
      await tester.tap(find.text(Messages.apply));
      await tester.pumpAndSettle();

      final clock = gridState.pinned.firstWhere((p) => p.id == 'pkg.clock');
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

      final clock = gridState.pinned.firstWhere((p) => p.id == 'pkg.clock');
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

      expect(gridState.pinned.map((p) => p.id), ['pkg.maps', 'pkg.clock']);
    });
  });

  group('add tile', () {
    testWidgets('tapping + ADD TILE pins a clock tile onto home', (
      WidgetTester tester,
    ) async {
      final GridState gridState = _gridState();
      await pumpShell(tester, FakeAppRepository(), gridState: gridState);
      await tester.pump();

      await tester.tap(find.text(Messages.addTile));
      await tester.pumpAndSettle();
      await tester.tap(find.text('CLOCK'));
      await tester.pumpAndSettle();

      expect(gridState.isPinned('clock'), isTrue);
      expect(_onHome(find.byType(ClockTileContentView)), findsOneWidget);
    });

    testWidgets('a device tile shows what the repository reports', (
      WidgetTester tester,
    ) async {
      final GridState gridState = _gridState();
      await pumpShell(
        tester,
        FakeAppRepository(),
        gridState: gridState,
        deviceRepository: FakeDeviceRepository(
          const DeviceStatus(batteryPercent: 64),
        ),
      );
      await tester.pump();

      await tester.tap(find.text(Messages.addTile));
      await tester.pumpAndSettle();
      await tester.tap(find.text('DEVICE'));
      await tester.pumpAndSettle();

      expect(gridState.isPinned('device'), isTrue);
      expect(_onHome(find.byType(DeviceTileContentView)), findsOneWidget);
      expect(_onHome(find.text('BATTERY  64%')), findsOneWidget);
    });

    testWidgets('tapping the weather tile asks for location, then shows it', (
      WidgetTester tester,
    ) async {
      final GridState gridState = _gridState();
      final FakeWeatherRepository weather = FakeWeatherRepository(
        const WeatherNeedsPlace(),
        WeatherReady(
          Forecast(
            place: const Place(
              name: 'Gothenburg',
              latitude: 57.7,
              longitude: 11.97,
            ),
            source: 'SMHI',
            now: const Conditions(
              temperature: 9.6,
              feelsLike: 8,
              humidity: 70,
              code: 3,
              windSpeed: 3,
              windDirection: 180,
              precipitation: 0,
            ),
            days: [
              DayForecast(
                date: DateTime(2026, 9, 28),
                code: 3,
                low: 6,
                high: 11,
                precipitation: 0,
              ),
            ],
          ),
        ),
      );
      await pumpShell(
        tester,
        FakeAppRepository(),
        gridState: gridState,
        weatherRepository: weather,
      );
      await tester.pump();

      await tester.tap(find.text(Messages.addTile));
      await tester.pumpAndSettle();
      await tester.tap(find.text('WEATHER'));
      await tester.pumpAndSettle();

      expect(_onHome(find.text(Messages.weatherTapToLocate)), findsOneWidget);

      await tester.tap(_onHome(find.byType(WeatherTileContentView)));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 500));

      expect(weather.locateCalls, 1);
      expect(_onHome(find.text('10°')), findsOneWidget);
      expect(_onHome(find.text('GOTHENBURG')), findsOneWidget);
    });

    testWidgets('a permanent refusal is not asked again on tap', (
      WidgetTester tester,
    ) async {
      final GridState gridState = _gridState();
      final FakeWeatherRepository weather = FakeWeatherRepository(
        const WeatherLocationDenied(permanent: true),
      );
      await pumpShell(
        tester,
        FakeAppRepository(),
        gridState: gridState,
        weatherRepository: weather,
      );
      await tester.pump();
      await gridState.pinSystemTile(TileKind.weather);
      await tester.pumpAndSettle();

      await tester.tap(_onHome(find.byType(WeatherTileContentView)));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 500));

      expect(weather.locateCalls, 0);
      expect(
        _onHome(find.text(Messages.weatherAllowInSettings)),
        findsOneWidget,
      );
    });

    testWidgets('tapping the sound tile cycles normal, vibrate, silent', (
      WidgetTester tester,
    ) async {
      final GridState gridState = _gridState();
      final FakeSystemControlService control = FakeSystemControlService();
      await pumpShell(
        tester,
        FakeAppRepository(),
        gridState: gridState,
        systemControlService: control,
      );
      await tester.pump();

      await tester.tap(find.text(Messages.addTile));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SOUND'));
      await tester.pumpAndSettle();

      expect(_onHome(find.text(SoundMode.normal.label)), findsOneWidget);

      for (final SoundMode expected in [SoundMode.vibrate, SoundMode.silent]) {
        await tester.tap(_onHome(find.byType(StateTileContentView)));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 500));
        expect(_onHome(find.text(expected.label)), findsOneWidget);
      }
      expect(control.soundCalls, [SoundMode.vibrate, SoundMode.silent]);
    });

    testWidgets('tapping a toggle tile flips it through the control service', (
      WidgetTester tester,
    ) async {
      final GridState gridState = _gridState();
      final FakeSystemControlService control = FakeSystemControlService();
      await pumpShell(
        tester,
        FakeAppRepository(),
        gridState: gridState,
        systemControlService: control,
      );
      await tester.pump();

      await tester.tap(find.text(Messages.addTile));
      await tester.pumpAndSettle();
      await tester.tap(find.text('FLASHLIGHT'));
      await tester.pumpAndSettle();

      expect(_onHome(find.text('[OFF]')), findsOneWidget);

      await tester.tap(_onHome(find.byType(StateTileContentView)));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 500));

      expect(control.setCalls, [(TileKind.flashlight, true)]);
      expect(_onHome(find.text('[ON]')), findsOneWidget);
    });
  });
}

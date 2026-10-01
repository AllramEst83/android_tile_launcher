import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/agenda_snapshot.dart';
import 'package:android_tile_launcher/model/c64_colour.dart';
import 'package:android_tile_launcher/model/calendar_event.dart';
import 'package:android_tile_launcher/model/camera_access.dart';
import 'package:android_tile_launcher/model/clock_format.dart';
import 'package:android_tile_launcher/model/contact.dart';
import 'package:android_tile_launcher/model/device_status.dart';
import 'package:android_tile_launcher/model/mail.dart';
import 'package:android_tile_launcher/model/settings.dart';
import 'package:android_tile_launcher/model/sound_mode.dart';
import 'package:android_tile_launcher/model/text_tv_page.dart';
import 'package:android_tile_launcher/model/tile.dart';
import 'package:android_tile_launcher/model/tile_size.dart';
import 'package:android_tile_launcher/model/weather.dart';
import 'package:android_tile_launcher/model/weather_snapshot.dart';
import 'package:android_tile_launcher/services/app_info.dart';
import 'package:android_tile_launcher/services/app_repository.dart';
import 'package:android_tile_launcher/services/first_run.dart';
import 'package:android_tile_launcher/services/grid_state.dart';
import 'package:android_tile_launcher/services/launch_stats.dart';
import 'package:android_tile_launcher/services/settings_state.dart';
import 'package:android_tile_launcher/ui/agenda_sheet.dart';
import 'package:android_tile_launcher/ui/agenda_tile_view.dart';
import 'package:android_tile_launcher/ui/alarm_sheet.dart';
import 'package:android_tile_launcher/ui/alarm_tile_view.dart';
import 'package:android_tile_launcher/ui/app_drawer.dart';
import 'package:android_tile_launcher/ui/app_icon.dart';
import 'package:android_tile_launcher/ui/app_tile_grid.dart';
import 'package:android_tile_launcher/ui/bluetooth_sheet.dart';
import 'package:android_tile_launcher/ui/boot_screen.dart';
import 'package:android_tile_launcher/ui/calc_pad.dart';
import 'package:android_tile_launcher/ui/calc_sheet.dart';
import 'package:android_tile_launcher/ui/calc_tile_view.dart';
import 'package:android_tile_launcher/ui/clock_tile_view.dart';
import 'package:android_tile_launcher/ui/contact_picker.dart';
import 'package:android_tile_launcher/ui/contact_sheet.dart';
import 'package:android_tile_launcher/ui/device_tile_view.dart';
import 'package:android_tile_launcher/ui/digit_pad.dart';
import 'package:android_tile_launcher/ui/editable_tile_grid.dart';
import 'package:android_tile_launcher/ui/files_sheet.dart';
import 'package:android_tile_launcher/ui/files_tile_view.dart';
import 'package:android_tile_launcher/ui/home_shell.dart';
import 'package:android_tile_launcher/ui/mail_setup_sheet.dart';
import 'package:android_tile_launcher/ui/mail_sheet.dart';
import 'package:android_tile_launcher/ui/mail_tile_view.dart';
import 'package:android_tile_launcher/ui/qr_scanner_screen.dart';
import 'package:android_tile_launcher/ui/qr_scanner_tile_view.dart';
import 'package:android_tile_launcher/ui/settings_scope.dart';
import 'package:android_tile_launcher/ui/settings_screen.dart';
import 'package:android_tile_launcher/ui/state_tile_view.dart';
import 'package:android_tile_launcher/ui/text_tv_screen.dart';
import 'package:android_tile_launcher/ui/text_tv_tile_view.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:android_tile_launcher/ui/tile_size_grid_picker.dart';
import 'package:android_tile_launcher/ui/tile_view.dart';
import 'package:android_tile_launcher/ui/timer_pad.dart';
import 'package:android_tile_launcher/ui/weather_tile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_agenda_repository.dart';
import '../fakes/fake_alarm_service.dart';
import '../fakes/fake_app_repository.dart';
import '../fakes/fake_camera_service.dart';
import '../fakes/fake_contacts.dart';
import '../fakes/fake_device_repository.dart';
import '../fakes/fake_mail_service.dart';
import '../fakes/fake_shade_service.dart';
import '../fakes/fake_system_control_service.dart';
import '../fakes/fake_text_tv_repository.dart';
import '../fakes/fake_tile_services.dart';
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
  FakeAgendaRepository? agendaRepository,
  FakeContactsRepository? contactsRepository,
  FakePhoneService? phoneService,
  FakeSmsService? smsService,
  FakeWhatsAppService? whatsAppService,
  FakeMailService? mailService,
  FakeTextTvRepository? textTvRepository,
  FakeAlarmService? alarmService,
  SettingsState? settingsState,
  FakeShadeService? shadeService,
  FakeCameraService? cameraService,
  FirstRun? firstRun,
  LaunchStats? launchStats,
  AppIconLoader? icons,
}) => tester.pumpWidget(
  SettingsScope(
    state: settingsState ?? SettingsState(store: InMemoryLocalStore()),
    child: MaterialApp(
      theme: tileLauncherTheme(),
      home: HomeShell(
        firstRun: firstRun,
        launchStats: launchStats,
        appRepository: repository,
        gridState: gridState ?? _gridState(),
        services: fakeTileServices(
          systemControl: systemControlService,
          device: deviceRepository,
          weather: weatherRepository,
          agenda: agendaRepository,
          contacts: contactsRepository,
          phone: phoneService,
          sms: smsService,
          whatsApp: whatsAppService,
          mail: mailService,
          textTv: textTvRepository,
          alarm: alarmService,
          shade: shadeService,
          camera: cameraService,
          icons: icons,
        ),
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

  testWidgets(
    'the app list refreshes when the launcher comes back to the front',
    (WidgetTester tester) async {
      final FakeAppRepository repository = FakeAppRepository(
        apps: const [AppInfo(label: 'Clock', packageName: 'pkg.clock')],
      );
      await pumpShell(tester, repository);
      await tester.pump();

      // Simulates installing an app while the launcher is backgrounded (the
      // Play Store, say) — nothing here asks for a refresh directly.
      repository.apps = const [
        AppInfo(label: 'Clock', packageName: 'pkg.clock'),
        AppInfo(label: 'Maps', packageName: 'pkg.maps'),
      ];
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(repository.refreshCalls, 1);
      await _swipeToDrawer(tester);
      expect(_inDrawer(find.text('MAPS')), findsOneWidget);
    },
  );

  group('grid editor', () {
    Future<GridState> pinTwo(WidgetTester tester) async {
      // A realistic phone-tall canvas, not the default (wider-than-tall)
      // test surface: the inspector panel below the canvas grew genuinely
      // taller once its size picker started filling the panel's own width
      // (Phase 42), and a landscape-shaped surface left too little of it
      // for the canvas above to still hold both pinned tiles on-screen at
      // the coordinates these tests compute drag gestures against.
      tester.view
        ..physicalSize = const Size(400, 900)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);

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
      await tester.tap(find.byKey(sizeGridCellKey(2, 2)));
      await tester.pump();
      await tester.tap(find.text(Messages.apply));
      await tester.pumpAndSettle();

      final clock = gridState.pinned.firstWhere((p) => p.id == 'pkg.clock');
      expect(clock.size, TileSize.medium);
    });

    testWidgets(
      'the largest size in the grid picker is reachable without overflowing',
      (WidgetTester tester) async {
        final GridState gridState = await pinTwo(tester);

        await tester.longPress(_onHome(find.text('CLOCK')));
        await tester.pumpAndSettle();
        // The panel is narrow on a phone; the picker's own 4x6 grid (Phase
        // 37, replacing 24 separate size buttons) must fit it without a
        // RenderFlex overflow.
        await tester.tap(find.byKey(sizeGridCellKey(4, 6)));
        await tester.pump();
        await tester.tap(find.text(Messages.apply));
        await tester.pumpAndSettle();

        final clock = gridState.pinned.firstWhere((p) => p.id == 'pkg.clock');
        expect(clock.size, TileSize.size4x6);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('a 6-column mosaic offers a real 6-wide size, not just 4', (
      WidgetTester tester,
    ) async {
      tester.view
        ..physicalSize = const Size(400, 900)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final GridState gridState = _gridState();
      await gridState.pin('pkg.clock');
      await gridState.pin('pkg.maps');
      final SettingsState settingsState = SettingsState(
        store: InMemoryLocalStore(),
      );
      await settingsState.update(const LauncherSettings(columns: 6));
      await pumpShell(
        tester,
        FakeAppRepository(
          apps: const [
            AppInfo(label: 'Clock', packageName: 'pkg.clock'),
            AppInfo(label: 'Maps', packageName: 'pkg.maps'),
          ],
        ),
        gridState: gridState,
        settingsState: settingsState,
      );
      await tester.pump();

      await tester.longPress(_onHome(find.text('CLOCK')));
      await tester.pumpAndSettle();

      expect(find.byKey(sizeGridCellKey(6, 1)), findsOneWidget);

      await tester.tap(find.byKey(sizeGridCellKey(6, 3)));
      await tester.pump();
      await tester.tap(find.text(Messages.apply));
      await tester.pumpAndSettle();

      final clock = gridState.pinned.firstWhere((p) => p.id == 'pkg.clock');
      expect(clock.size, TileSize.size6x3);
      expect(tester.takeException(), isNull);
    });

    testWidgets('FLIP swaps the columns and rows of a resized tile', (
      WidgetTester tester,
    ) async {
      final GridState gridState = await pinTwo(tester);

      await tester.longPress(_onHome(find.text('CLOCK')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(sizeGridCellKey(3, 2)));
      await tester.pump();
      await tester.tap(find.text(Messages.tileSizeFlip));
      await tester.pump();
      await tester.tap(find.text(Messages.apply));
      await tester.pumpAndSettle();

      final clock = gridState.pinned.firstWhere((p) => p.id == 'pkg.clock');
      expect(clock.size, TileSize.size2x3);
    });

    testWidgets('FLIP does nothing once a tile is taller than 4 rows', (
      WidgetTester tester,
    ) async {
      final GridState gridState = await pinTwo(tester);

      await tester.longPress(_onHome(find.text('CLOCK')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(sizeGridCellKey(2, 5)));
      await tester.pump();
      await tester.tap(find.text(Messages.tileSizeFlip));
      await tester.pump();
      await tester.tap(find.text(Messages.apply));
      await tester.pumpAndSettle();

      final clock = gridState.pinned.firstWhere((p) => p.id == 'pkg.clock');
      expect(clock.size, TileSize.size2x5);
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
      // The left half of the clock tile: the map tile goes before it.
      final Rect clock = tester.getRect(
        _inEditor(find.byKey(const ValueKey('pkg.clock'))),
      );
      final Offset to = Offset(clock.left + 10, clock.center.dy);
      final TestGesture gesture = await tester.startGesture(from);
      // A tile comes off the grid once it has been held for a moment.
      await tester.pump(
        EditableTileGrid.pickUpDelay + const Duration(milliseconds: 50),
      );
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

    testWidgets(
      'tapping the agenda tile asks for the calendar, then shows it',
      (WidgetTester tester) async {
        final GridState gridState = _gridState();
        final DateTime today = DateTime.now();
        final FakeAgendaRepository agenda = FakeAgendaRepository(
          const AgendaNeedsPermission(),
          AgendaReady(<CalendarEvent>[
            CalendarEvent(
              id: 1,
              title: 'Holiday',
              start: DateTime(today.year, today.month, today.day),
              end: DateTime(today.year, today.month, today.day + 1),
              allDay: true,
            ),
          ]),
        );
        await pumpShell(
          tester,
          FakeAppRepository(),
          gridState: gridState,
          agendaRepository: agenda,
        );
        await tester.pump();
        await gridState.pinSystemTile(TileKind.agenda);
        await tester.pumpAndSettle();

        expect(_onHome(find.text(Messages.agendaTapToAllow)), findsOneWidget);

        await tester.tap(_onHome(find.byType(AgendaTileContentView)));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 500));

        expect(agenda.allowCalls, 1);
        expect(_onHome(find.text('HOLIDAY')), findsOneWidget);
      },
    );

    testWidgets('tapping an agenda tile with events opens the day and week', (
      WidgetTester tester,
    ) async {
      final GridState gridState = _gridState();
      final DateTime today = DateTime.now();
      final FakeAgendaRepository agenda = FakeAgendaRepository(
        AgendaReady(<CalendarEvent>[
          CalendarEvent(
            id: 1,
            title: 'Holiday',
            start: DateTime(today.year, today.month, today.day),
            end: DateTime(today.year, today.month, today.day + 1),
            allDay: true,
          ),
        ]),
      );
      await pumpShell(
        tester,
        FakeAppRepository(),
        gridState: gridState,
        agendaRepository: agenda,
      );
      await tester.pump();
      await gridState.pinSystemTile(TileKind.agenda);
      await tester.pumpAndSettle();

      await tester.tap(_onHome(find.byType(AgendaTileContentView)));
      await tester.pumpAndSettle();

      expect(agenda.allowCalls, 0);
      expect(find.byKey(agendaWeekToggleKey), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('HOLIDAY'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a permanently refused agenda tile is not asked again', (
      WidgetTester tester,
    ) async {
      final GridState gridState = _gridState();
      final FakeAgendaRepository agenda = FakeAgendaRepository(
        const AgendaDenied(permanent: true),
      );
      await pumpShell(
        tester,
        FakeAppRepository(),
        gridState: gridState,
        agendaRepository: agenda,
      );
      await tester.pump();
      await gridState.pinSystemTile(TileKind.agenda);
      await tester.pumpAndSettle();

      await tester.tap(_onHome(find.byType(AgendaTileContentView)));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 500));

      expect(agenda.allowCalls, 0);
      expect(
        _onHome(find.text(Messages.agendaAllowInSettings)),
        findsOneWidget,
      );
    });

    testWidgets('pinning a contact from ADD TILE puts their tile on home', (
      WidgetTester tester,
    ) async {
      final GridState gridState = _gridState();
      await pumpShell(
        tester,
        FakeAppRepository(),
        gridState: gridState,
        contactsRepository: FakeContactsRepository(<Contact>[
          const Contact(
            key: 'k1',
            name: 'Anna Andersson',
            numbers: <PhoneNumber>[PhoneNumber('070-123 45 67', 'MOBILE')],
          ),
        ]),
      );
      await tester.pump();

      await tester.tap(find.text(Messages.addTile));
      await tester.pumpAndSettle();
      await tester.tap(find.text('CONTACT'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(contactRowKey('k1')));
      await tester.pumpAndSettle();

      expect(gridState.isPinned(contactTileId('k1')), isTrue);
      expect(_onHome(find.text('ANNA ANDERSSON')), findsOneWidget);
    });

    testWidgets('a contact tile opens its sheet, and does nothing by itself', (
      WidgetTester tester,
    ) async {
      final GridState gridState = _gridState();
      await gridState.pinContact(key: 'k1', name: 'Anna Andersson');
      final FakePhoneService phone = FakePhoneService();
      final FakeSmsService sms = FakeSmsService();
      final FakeWhatsAppService whatsApp = FakeWhatsAppService();
      await pumpShell(
        tester,
        FakeAppRepository(),
        gridState: gridState,
        contactsRepository: FakeContactsRepository(<Contact>[
          const Contact(
            key: 'k1',
            name: 'Anna Andersson',
            numbers: <PhoneNumber>[PhoneNumber('070-123 45 67', 'MOBILE')],
          ),
        ]),
        phoneService: phone,
        smsService: sms,
        whatsAppService: whatsApp,
      );
      await tester.pump();
      await tester.pumpAndSettle();

      await tester.tap(_onHome(find.text('ANNA ANDERSSON')));
      await tester.pumpAndSettle();

      expect(find.byKey(contactCallKey), findsOneWidget);
      expect(phone.called, isEmpty);
      expect(sms.sent, isEmpty);
      expect(whatsApp.opened, isEmpty);

      await tester.tap(find.byKey(contactCallKey));
      await tester.pumpAndSettle();

      expect(phone.called, <String>['0701234567']);
    });

    testWidgets('a contact tile is labelled by name in the grid editor', (
      WidgetTester tester,
    ) async {
      final GridState gridState = _gridState();
      await gridState.pinContact(key: 'k1', name: 'Anna Andersson');
      await pumpShell(tester, FakeAppRepository(), gridState: gridState);
      await tester.pump();
      await tester.pumpAndSettle();

      await tester.longPress(_onHome(find.text('ANNA ANDERSSON')));
      await tester.pumpAndSettle();

      // In the editor a tap selects the tile (the inspector names it), and
      // never opens the sheet.
      expect(_inEditor(find.text('ANNA ANDERSSON')), findsOneWidget);
      expect(find.byKey(contactCallKey), findsNothing);
      expect(find.text('ANNA ANDERSSON'), findsWidgets);
    });

    testWidgets('an unset-up mail tile sets mail up, then shows the inbox', (
      WidgetTester tester,
    ) async {
      final GridState gridState = _gridState();
      final FakeMailService mail = FakeMailService();
      await pumpShell(
        tester,
        FakeAppRepository(),
        gridState: gridState,
        mailService: mail,
      );
      await tester.pump();
      await gridState.pinSystemTile(TileKind.mail);
      await tester.pumpAndSettle();
      expect(_onHome(find.text(Messages.mailTapToSetUp)), findsOneWidget);

      await tester.tap(_onHome(find.byType(MailTileContentView)));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(mailEmailKey), 'kay@gmail.com');
      await tester.enterText(find.byKey(mailPasswordKey), 'secret');
      await tester.pump();
      // Once the account is saved the tile reads an inbox.
      mail.result = const MailMessages(<MailMessage>[], total: 0, unread: 3);
      await tester.tap(find.byKey(mailConnectKey));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 500));

      expect(mail.setUps, hasLength(1));
      expect(_onHome(find.text('3')), findsOneWidget);
    });

    testWidgets('a mail tile with an inbox opens the inbox on tap', (
      WidgetTester tester,
    ) async {
      final GridState gridState = _gridState();
      final FakeMailService mail = FakeMailService(
        const MailMessages(
          <MailMessage>[
            MailMessage(uid: 9, from: 'Anna', subject: 'Hello', unread: true),
          ],
          total: 1,
          unread: 1,
          validity: 1,
        ),
      )..saved = const MailAccountInfo(email: 'kay@gmail.com', host: 'h');
      await pumpShell(
        tester,
        FakeAppRepository(),
        gridState: gridState,
        mailService: mail,
      );
      await tester.pump();
      await gridState.pinSystemTile(TileKind.mail);
      await tester.pumpAndSettle();

      await tester.tap(_onHome(find.byType(MailTileContentView)));
      await tester.pumpAndSettle();

      expect(find.byKey(mailMessageKey(9)), findsOneWidget);
      expect(find.byKey(mailForgetKey), findsOneWidget);
      // Nothing was moved or forgotten by opening it.
      expect(mail.moves, isEmpty);
      expect(mail.forgets, 0);
    });

    testWidgets(
      'a mail tile that cannot read its account offers set up again',
      (WidgetTester tester) async {
        final GridState gridState = _gridState();
        // No saved account visible (as when the stored one cannot be read), yet
        // the read failed rather than saying "not set up".
        final FakeMailService mail = FakeMailService(
          const MailUnavailable('the saved mail account is unreadable'),
        );
        await pumpShell(
          tester,
          FakeAppRepository(),
          gridState: gridState,
          mailService: mail,
        );
        await tester.pump();
        await gridState.pinSystemTile(TileKind.mail);
        await tester.pumpAndSettle();

        await tester.tap(_onHome(find.byType(MailTileContentView)));
        await tester.pumpAndSettle();

        expect(find.byKey(mailConnectKey), findsOneWidget);
      },
    );

    testWidgets(
      'the Text TV tile shows headlines, and opens the viewer on tap',
      (WidgetTester tester) async {
        final GridState gridState = _gridState();
        final FakeTextTvRepository textTv = FakeTextTvRepository(
          <int, TextTvPage>{
            100: const TextTvPage(
              number: 100,
              parts: <List<String>>[
                <String>[
                  '100 SVT Text',
                  '',
                  '  Fyra dödades i ryska attacker',
                  '                   130',
                ],
              ],
            ),
          },
        );
        await pumpShell(
          tester,
          FakeAppRepository(),
          gridState: gridState,
          textTvRepository: textTv,
        );
        await tester.pump();
        await gridState.pinSystemTile(TileKind.textTv);
        await tester.pumpAndSettle();
        expect(
          _onHome(find.text('FYRA DÖDADES I RYSKA ATTACKER')),
          findsOneWidget,
        );

        await tester.tap(_onHome(find.byType(TextTvTileContentView)));
        await tester.pumpAndSettle();

        // The viewer covers the home screen, with its close button on top.
        expect(find.byKey(textTvCloseKey), findsOneWidget);

        final int before = textTv.requests.length;
        await tester.tap(find.byKey(textTvCloseKey));
        await tester.pumpAndSettle();

        expect(find.byKey(textTvCloseKey), findsNothing);
        // Back on home the tile read again.
        expect(textTv.requests.length, greaterThan(before));
        expect(_onHome(find.byType(TextTvTileContentView)), findsOneWidget);
      },
    );

    testWidgets('the alarm tile opens the timer, which hands it to the clock', (
      WidgetTester tester,
    ) async {
      final GridState gridState = _gridState();
      final FakeAlarmService alarm = FakeAlarmService();
      await pumpShell(
        tester,
        FakeAppRepository(),
        gridState: gridState,
        alarmService: alarm,
      );
      await tester.pump();
      await gridState.pinSystemTile(TileKind.alarm);
      await tester.pumpAndSettle();

      await tester.tap(_onHome(find.byType(AlarmTileContentView)));
      await tester.pumpAndSettle();
      // Nothing is set by opening it.
      expect(alarm.timers, isEmpty);
      for (final int d in <int>[5, 0, 0]) {
        await tester.tap(find.byKey(DigitPad.digitKey(timerPadPrefix, d)));
        await tester.pump();
      }
      await tester.tap(find.byKey(timerStartKey));
      await tester.pumpAndSettle();

      expect(alarm.timers, <Duration>[const Duration(minutes: 5)]);

      await tester.tap(find.byKey(alarmCloseKey));
      await tester.pumpAndSettle();
      expect(find.byKey(alarmCloseKey), findsNothing);
    });

    testWidgets(
      'the alarm tile shows the next alarm due, and re-reads once the sheet '
      'closes',
      (WidgetTester tester) async {
        final GridState gridState = _gridState();
        final FakeAlarmService alarm = FakeAlarmService();
        await pumpShell(
          tester,
          FakeAppRepository(),
          gridState: gridState,
          alarmService: alarm,
        );
        await tester.pump();
        await gridState.pinSystemTile(TileKind.alarm);
        await tester.pumpAndSettle();

        expect(_onHome(find.text(Messages.alarmNone)), findsOneWidget);

        // As if an alarm was set from the clock app while the sheet was open.
        alarm.nextAlarm = DateTime(2026, 9, 28, 7, 30);
        await tester.tap(_onHome(find.byType(AlarmTileContentView)));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(alarmCloseKey));
        await tester.pumpAndSettle();

        expect(
          _onHome(find.text(formatClockTime(alarm.nextAlarm!))),
          findsOneWidget,
        );
      },
    );

    testWidgets('the calc tile opens the calculator, which works', (
      WidgetTester tester,
    ) async {
      final GridState gridState = _gridState();
      await pumpShell(tester, FakeAppRepository(), gridState: gridState);
      await tester.pump();
      await gridState.pinSystemTile(TileKind.calc);
      await tester.pumpAndSettle();

      await tester.tap(_onHome(find.byType(CalcTileContentView)));
      await tester.pumpAndSettle();
      for (final String key in <String>['6', '*', '7', '=']) {
        await tester.tap(find.byKey(calcKey(key)));
        await tester.pump();
      }

      expect(tester.widget<Text>(find.byKey(calcExpressionKey)).data, '42');

      await tester.tap(find.byKey(calcCloseKey));
      await tester.pumpAndSettle();

      expect(find.byKey(calcCloseKey), findsNothing);
    });

    testWidgets('the files tile opens the file explorer', (
      WidgetTester tester,
    ) async {
      final GridState gridState = _gridState();
      await pumpShell(tester, FakeAppRepository(), gridState: gridState);
      await tester.pump();
      await gridState.pinSystemTile(TileKind.files);
      await tester.pumpAndSettle();

      await tester.tap(_onHome(find.byType(FilesTileContentView)));
      await tester.pumpAndSettle();

      expect(find.text(Messages.filesTapToAllow), findsOneWidget);

      await tester.tap(find.byKey(filesCloseKey));
      await tester.pumpAndSettle();

      expect(find.byKey(filesCloseKey), findsNothing);
    });

    testWidgets('the QR scanner tile opens the scanner', (
      WidgetTester tester,
    ) async {
      final GridState gridState = _gridState();
      // Denied, so the screen shows "tap to allow" rather than a real
      // camera preview, which this test harness cannot provide.
      await pumpShell(
        tester,
        FakeAppRepository(),
        gridState: gridState,
        cameraService: FakeCameraService(
          result: const CameraDenied(permanent: false),
        ),
      );
      await tester.pump();
      await gridState.pinSystemTile(TileKind.qrScanner);
      await tester.pumpAndSettle();

      await tester.tap(_onHome(find.byType(QrScannerTileContentView)));
      await tester.pumpAndSettle();

      expect(find.text(Messages.qrScannerTapToAllow), findsOneWidget);

      await tester.tap(find.byKey(qrScannerCloseKey));
      await tester.pumpAndSettle();

      expect(find.byKey(qrScannerCloseKey), findsNothing);
    });

    testWidgets('the bluetooth tile opens the bluetooth sheet', (
      WidgetTester tester,
    ) async {
      final GridState gridState = _gridState();
      await pumpShell(tester, FakeAppRepository(), gridState: gridState);
      await tester.pump();
      await gridState.pinSystemTile(TileKind.bluetooth);
      await tester.pumpAndSettle();

      await tester.tap(_onHome(find.byType(StateTileContentView)));
      await tester.pumpAndSettle();

      expect(find.byKey(bluetoothCloseKey), findsOneWidget);

      await tester.tap(find.byKey(bluetoothCloseKey));
      await tester.pumpAndSettle();

      expect(find.byKey(bluetoothCloseKey), findsNothing);
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

    testWidgets('the rotation-lock tile flips between LOCKED and AUTO', (
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
      // The last kind in the list, so it starts below the sheet's own fold.
      await tester.ensureVisible(find.text('ROTATION'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ROTATION'));
      await tester.pumpAndSettle();

      expect(_onHome(find.text('[AUTO]')), findsOneWidget);

      await tester.tap(_onHome(find.byType(StateTileContentView)));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 500));

      expect(control.setCalls, [(TileKind.orientationLock, true)]);
      expect(_onHome(find.text('[LOCKED]')), findsOneWidget);
    });
  });
  group('settings and swipe gestures', () {
    Future<(SettingsState, FakeShadeService)> pumpWith(
      WidgetTester tester,
      LauncherSettings settings,
    ) async {
      final SettingsState state = SettingsState(store: InMemoryLocalStore());
      await state.update(settings);
      final FakeShadeService shade = FakeShadeService();
      await pumpShell(
        tester,
        FakeAppRepository(),
        settingsState: state,
        shadeService: shade,
      );
      await tester.pump();
      return (state, shade);
    }

    Future<void> swipe(WidgetTester tester, double dy) async {
      // From the top corner: in the middle of an empty grid the message is
      // what is under the finger, not the list.
      await tester.dragFrom(
        tester.getTopLeft(find.byType(AppTileGrid)) + const Offset(30, 30),
        Offset(0, dy),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('SETTINGS opens the settings screen, and it closes again', (
      WidgetTester tester,
    ) async {
      await pumpShell(tester, FakeAppRepository());
      await tester.pump();

      await tester.tap(find.text(Messages.settingsButton));
      await tester.pumpAndSettle();
      expect(find.byKey(settingsCloseKey), findsOneWidget);

      await tester.tap(find.byKey(settingsCloseKey));
      await tester.pumpAndSettle();
      expect(find.byKey(settingsCloseKey), findsNothing);
    });

    testWidgets('swipe down can pull the notification shade', (
      WidgetTester tester,
    ) async {
      final (_, FakeShadeService shade) = await pumpWith(
        tester,
        const LauncherSettings(swipeDown: GestureAction.notifications),
      );

      await swipe(tester, 300);

      expect(shade.notificationCalls, 1);
      expect(shade.quickSettingsCalls, 0);
    });

    testWidgets('swipe down can pull quick settings', (
      WidgetTester tester,
    ) async {
      final (_, FakeShadeService shade) = await pumpWith(
        tester,
        const LauncherSettings(swipeDown: GestureAction.quickSettings),
      );

      await swipe(tester, 300);

      expect(shade.quickSettingsCalls, 1);
      expect(shade.notificationCalls, 0);
    });

    testWidgets('by default swipe down refreshes and pulls nothing down', (
      WidgetTester tester,
    ) async {
      final FakeAppRepository repository = FakeAppRepository();
      final FakeShadeService shade = FakeShadeService();
      await pumpShell(tester, repository, shadeService: shade);
      await tester.pump();
      final int refreshed = repository.refreshCalls;

      await swipe(tester, 300);

      expect(repository.refreshCalls, refreshed + 1);
      expect(shade.notificationCalls + shade.quickSettingsCalls, 0);
    });

    testWidgets('swipe down set to nothing does nothing', (
      WidgetTester tester,
    ) async {
      final (_, FakeShadeService shade) = await pumpWith(
        tester,
        const LauncherSettings(swipeDown: GestureAction.none),
      );

      await swipe(tester, 300);

      expect(shade.notificationCalls + shade.quickSettingsCalls, 0);
    });

    testWidgets('swipe up does nothing until it is given something to do', (
      WidgetTester tester,
    ) async {
      await pumpWith(tester, const LauncherSettings());

      await swipe(tester, -300);

      final PageView pages = tester.widget<PageView>(find.byType(PageView));
      expect(pages.controller!.page, 0);
    });

    testWidgets('swipe up can open All Apps', (WidgetTester tester) async {
      await pumpWith(
        tester,
        const LauncherSettings(swipeUp: GestureAction.allApps),
      );

      await swipe(tester, -300);

      final PageView pages = tester.widget<PageView>(find.byType(PageView));
      expect(pages.controller!.page, 1);
    });

    testWidgets('swipe up can open All Apps with the search field ready', (
      WidgetTester tester,
    ) async {
      await pumpWith(
        tester,
        const LauncherSettings(swipeUp: GestureAction.searchApps),
      );

      await swipe(tester, -300);

      final PageView pages = tester.widget<PageView>(find.byType(PageView));
      expect(pages.controller!.page, 1);
      final EditableText field = tester.widget<EditableText>(
        find.descendant(
          of: find.byType(AppDrawer),
          matching: find.byType(EditableText),
        ),
      );
      expect(field.focusNode.hasFocus, isTrue);
    });

    testWidgets('a swipe that stops short does not count', (
      WidgetTester tester,
    ) async {
      final (_, FakeShadeService shade) = await pumpWith(
        tester,
        const LauncherSettings(swipeDown: GestureAction.notifications),
      );

      await swipe(tester, 40);

      expect(shade.notificationCalls, 0);
    });
  });
  group('the first-run boot animation', () {
    Future<(FirstRun, InMemoryLocalStore)> pumpFirstRun(
      WidgetTester tester, {
      required bool first,
    }) async {
      final InMemoryLocalStore store = InMemoryLocalStore();
      if (!first) await store.write(FirstRun.storeKey, true);
      final FirstRun firstRun = FirstRun(store: store);
      await firstRun.load();
      await pumpShell(tester, FakeAppRepository(), firstRun: firstRun);
      return (firstRun, store);
    }

    testWidgets('plays on the first run, even after the apps are loaded', (
      WidgetTester tester,
    ) async {
      await pumpFirstRun(tester, first: true);
      await tester.pump(const Duration(milliseconds: 500));

      // The apps are long since listed; the show is still on.
      expect(find.byType(BootScreen), findsOneWidget);
      expect(find.byType(AppTileGrid), findsNothing);
      await tester.pumpAndSettle();
    });

    testWidgets('gives way to home when it is over, and is remembered', (
      WidgetTester tester,
    ) async {
      final (FirstRun firstRun, InMemoryLocalStore store) = await pumpFirstRun(
        tester,
        first: true,
      );

      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.byType(BootScreen), findsNothing);
      expect(find.byType(AppTileGrid), findsOneWidget);
      expect(firstRun.isFirstRun, isFalse);
      expect(await store.read(FirstRun.storeKey), isTrue);
    });

    testWidgets('a tap skips it', (WidgetTester tester) async {
      await pumpFirstRun(tester, first: true);
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byType(BootScreen));
      await tester.pumpAndSettle();

      expect(find.byType(AppTileGrid), findsOneWidget);
    });

    testWidgets('is not played again once it has been seen', (
      WidgetTester tester,
    ) async {
      await pumpFirstRun(tester, first: false);
      await tester.pump();

      expect(find.byType(BootScreen), findsNothing);
      expect(find.byType(AppTileGrid), findsOneWidget);
    });

    testWidgets('a failing app list is shown at once, not after the show', (
      WidgetTester tester,
    ) async {
      final InMemoryLocalStore store = InMemoryLocalStore();
      final FirstRun firstRun = FirstRun(store: store);
      await firstRun.load();
      await pumpShell(
        tester,
        FakeAppRepository()..listError = Exception('boom'),
        firstRun: firstRun,
      );
      await tester.pump();

      expect(find.text(Messages.appListError), findsOneWidget);
      await tester.pumpAndSettle();
    });
  });
  group('most used apps', () {
    const List<AppInfo> apps = <AppInfo>[
      AppInfo(label: 'Clock', packageName: 'pkg.clock'),
      AppInfo(label: 'Maps', packageName: 'pkg.maps'),
      AppInfo(label: 'Notes', packageName: 'pkg.notes'),
    ];

    Future<LaunchStats> statsWith(Map<String, int> counts) async {
      final LaunchStats stats = LaunchStats(store: InMemoryLocalStore());
      for (final MapEntry<String, int> e in counts.entries) {
        for (int i = 0; i < e.value; i++) {
          await stats.record(e.key);
        }
      }
      return stats;
    }

    Future<void> openAddSheet(WidgetTester tester) async {
      await tester.tap(find.text(Messages.addTile));
      await tester.pumpAndSettle();
    }

    testWidgets('launching from the drawer counts, and still launches', (
      WidgetTester tester,
    ) async {
      final FakeAppRepository repository = FakeAppRepository(apps: apps);
      final LaunchStats stats = LaunchStats(store: InMemoryLocalStore());
      await pumpShell(tester, repository, launchStats: stats);
      await tester.pump();
      await _swipeToDrawer(tester);

      await tester.tap(_inDrawer(find.text('MAPS')));
      await tester.pump();

      expect(repository.launched, <String>['pkg.maps']);
      expect(stats.countOf('pkg.maps'), 1);
    });

    testWidgets('launching from a home tile counts', (
      WidgetTester tester,
    ) async {
      final GridState gridState = _gridState();
      await gridState.pin('pkg.clock');
      final FakeAppRepository repository = FakeAppRepository(apps: apps);
      final LaunchStats stats = LaunchStats(store: InMemoryLocalStore());
      await pumpShell(
        tester,
        repository,
        gridState: gridState,
        launchStats: stats,
      );
      await tester.pump();

      await tester.tap(_onHome(find.text('CLOCK')));
      await tester.pump();

      expect(repository.launched, <String>['pkg.clock']);
      expect(stats.countOf('pkg.clock'), 1);
    });

    testWidgets('+ ADD TILE offers the ones used most, most first', (
      WidgetTester tester,
    ) async {
      final LaunchStats stats = await statsWith(<String, int>{
        'pkg.maps': 5,
        'pkg.notes': 9,
        'pkg.clock': 1,
      });
      await pumpShell(
        tester,
        FakeAppRepository(apps: apps),
        launchStats: stats,
      );
      await tester.pump();

      await openAddSheet(tester);

      expect(find.text(Messages.addTileMostUsed), findsOneWidget);
      expect(find.byKey(const ValueKey('suggest-pkg.notes')), findsOneWidget);
      expect(find.byKey(const ValueKey('suggest-pkg.maps')), findsOneWidget);
      // Once is not a habit.
      expect(find.byKey(const ValueKey('suggest-pkg.clock')), findsNothing);
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('suggest-pkg.notes'))).dy,
        lessThan(
          tester.getTopLeft(find.byKey(const ValueKey('suggest-pkg.maps'))).dy,
        ),
      );
      // The other tile kinds are still there below them.
      expect(find.text(Messages.addTileOther), findsOneWidget);
    });

    testWidgets('tapping one pins that app', (WidgetTester tester) async {
      final GridState gridState = _gridState();
      final LaunchStats stats = await statsWith(<String, int>{'pkg.maps': 4});
      await pumpShell(
        tester,
        FakeAppRepository(apps: apps),
        gridState: gridState,
        launchStats: stats,
      );
      await tester.pump();
      await openAddSheet(tester);

      await tester.tap(find.byKey(const ValueKey('suggest-pkg.maps')));
      await tester.pumpAndSettle();

      expect(gridState.isPinned('pkg.maps'), isTrue);
      expect(_onHome(find.text('MAPS')), findsOneWidget);
    });

    testWidgets('an app already on home is not suggested', (
      WidgetTester tester,
    ) async {
      final GridState gridState = _gridState();
      await gridState.pin('pkg.maps');
      final LaunchStats stats = await statsWith(<String, int>{
        'pkg.maps': 9,
        'pkg.notes': 3,
      });
      await pumpShell(
        tester,
        FakeAppRepository(apps: apps),
        gridState: gridState,
        launchStats: stats,
      );
      await tester.pump();

      await openAddSheet(tester);

      expect(find.byKey(const ValueKey('suggest-pkg.maps')), findsNothing);
      expect(find.byKey(const ValueKey('suggest-pkg.notes')), findsOneWidget);
    });

    testWidgets('an app that has since been uninstalled is not suggested', (
      WidgetTester tester,
    ) async {
      final LaunchStats stats = await statsWith(<String, int>{'pkg.gone': 9});
      await pumpShell(
        tester,
        FakeAppRepository(apps: apps),
        launchStats: stats,
      );
      await tester.pump();

      await openAddSheet(tester);

      expect(find.text(Messages.addTileMostUsed), findsNothing);
      expect(find.text(Messages.addTileOther), findsNothing);
    });

    testWidgets('without any habits the sheet is as it was', (
      WidgetTester tester,
    ) async {
      await pumpShell(
        tester,
        FakeAppRepository(apps: apps),
        launchStats: LaunchStats(store: InMemoryLocalStore()),
      );
      await tester.pump();

      await openAddSheet(tester);

      expect(find.text(Messages.addTileMostUsed), findsNothing);
      expect(find.text(Messages.addTileOther), findsNothing);
    });
  });
  group('app icons', () {
    testWidgets('home tiles and drawer rows ask the repository for icons', (
      WidgetTester tester,
    ) async {
      final GridState gridState = _gridState();
      await gridState.pin('pkg.clock');
      final FakeAppRepository repository = FakeAppRepository(
        apps: const <AppInfo>[
          AppInfo(label: 'Clock', packageName: 'pkg.clock'),
          AppInfo(label: 'Maps', packageName: 'pkg.maps'),
        ],
      );
      await pumpShell(
        tester,
        repository,
        gridState: gridState,
        icons: repository.icon,
      );
      await tester.pump();
      expect(_onHome(find.byType(AppIcon)), findsOneWidget);
      await _swipeToDrawer(tester);

      expect(
        repository.iconsAsked,
        containsAll(<String>['pkg.clock', 'pkg.maps']),
      );
      expect(_inDrawer(find.byType(AppIcon)), findsNWidgets(2));
    });
  });
  group('the bar of keys along the top', () {
    testWidgets(
      'has SETTINGS and + ADD TILE, side by side and as wide as each other',
      (WidgetTester tester) async {
        await pumpShell(tester, FakeAppRepository());
        await tester.pump();

        final Rect settings = tester.getRect(find.byKey(settingsButtonKey));
        final Rect add = tester.getRect(find.byKey(addTileButtonKey));

        expect(find.text(Messages.settingsButton), findsOneWidget);
        expect(find.text(Messages.addTile), findsOneWidget);
        expect(settings.width, closeTo(add.width, 0.01));
        expect(settings.top, add.top);
        expect(settings.right, lessThan(add.left));
      },
    );

    testWidgets('the keys are big enough to hit, and span the width', (
      WidgetTester tester,
    ) async {
      await pumpShell(tester, FakeAppRepository());
      await tester.pump();

      final Rect settings = tester.getRect(find.byKey(settingsButtonKey));
      final Rect add = tester.getRect(find.byKey(addTileButtonKey));

      expect(settings.height, greaterThanOrEqualTo(40));
      expect(settings.left, TileMetrics.margin);
      expect(add.right, 800 - TileMetrics.margin);
    });

    testWidgets('the grid starts close beneath them', (
      WidgetTester tester,
    ) async {
      final GridState gridState = _gridState();
      await gridState.pin('pkg.clock');
      await pumpShell(
        tester,
        FakeAppRepository(
          apps: const <AppInfo>[
            AppInfo(label: 'Clock', packageName: 'pkg.clock'),
          ],
        ),
        gridState: gridState,
      );
      await tester.pump();

      final double keysBottom = tester
          .getRect(find.byKey(settingsButtonKey))
          .bottom;
      final double firstTile = tester
          .getTopLeft(_onHome(find.byType(TileView)).first)
          .dy;

      expect(firstTile - keysBottom, lessThanOrEqualTo(TileMetrics.gutter + 1));
      expect(firstTile - keysBottom, greaterThanOrEqualTo(0));
    });

    testWidgets('each opens what it says', (WidgetTester tester) async {
      await pumpShell(tester, FakeAppRepository());
      await tester.pump();

      await tester.tap(find.byKey(addTileButtonKey));
      await tester.pumpAndSettle();
      expect(find.text(displayNameOf(TileKind.clock)), findsWidgets);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(settingsButtonKey));
      await tester.pumpAndSettle();
      expect(find.byKey(settingsCloseKey), findsOneWidget);
    });
  });
}

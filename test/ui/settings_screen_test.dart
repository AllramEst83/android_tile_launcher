import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/layout_export.dart';
import 'package:android_tile_launcher/model/pinned_tile.dart';
import 'package:android_tile_launcher/model/settings.dart';
import 'package:android_tile_launcher/model/tile.dart';
import 'package:android_tile_launcher/model/wallpaper.dart';
import 'package:android_tile_launcher/services/grid_state.dart';
import 'package:android_tile_launcher/services/settings_state.dart';
import 'package:android_tile_launcher/services/wallpaper_service.dart';
import 'package:android_tile_launcher/ui/settings_screen.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_clipboard_service.dart';
import '../fakes/fake_home_role_service.dart';
import '../fakes/fake_tile_services.dart';
import '../fakes/fake_wallpaper_service.dart';
import '../fakes/in_memory_local_store.dart';

class _Rig {
  _Rig({
    FakeClipboardService? clipboard,
    FakeHomeRoleService? homeRole,
    FakeWallpaperService? wallpaper,
  }) : clipboard = clipboard ?? FakeClipboardService(),
       homeRole = homeRole ?? FakeHomeRoleService(),
       wallpaper = wallpaper ?? FakeWallpaperService() {
    settings = SettingsState(store: InMemoryLocalStore());
    grid = GridState(store: InMemoryLocalStore());
  }

  late final SettingsState settings;
  late final GridState grid;
  final FakeClipboardService clipboard;
  final FakeHomeRoleService homeRole;
  final FakeWallpaperService wallpaper;

  Future<void> open(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(400, 2400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: tileLauncherTheme(),
        home: Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () => showSettings(
              context,
              settings: settings,
              gridState: grid,
              services: fakeTileServices(
                clipboard: clipboard,
                homeRole: homeRole,
                wallpaper: wallpaper,
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }
}

String _text(WidgetTester tester, Key key) =>
    tester.widget<Text>(find.byKey(key)).data!;

Future<void> _tap(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.pump();
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() => TileColors.current = TilePalette.c64);

  group('the screen', () {
    testWidgets('has a close key, and closes', (WidgetTester tester) async {
      await _Rig().open(tester);
      expect(find.byKey(settingsCloseKey), findsOneWidget);

      await tester.tap(find.byKey(settingsCloseKey));
      await tester.pumpAndSettle();

      expect(find.byKey(settingsCloseKey), findsNothing);
    });

    testWidgets('has a section for each thing that can be set', (
      WidgetTester tester,
    ) async {
      await _Rig().open(tester);

      for (final String title in <String>[
        Messages.settingsTheme,
        Messages.settingsGrid,
        Messages.settingsGestures,
        Messages.settingsSystem,
        Messages.settingsLayout,
      ]) {
        await tester.ensureVisible(find.text(title));
        expect(find.text(title), findsOneWidget, reason: title);
      }
    });
  });

  group('theme', () {
    testWidgets('a key for each, the current one lit', (
      WidgetTester tester,
    ) async {
      await _Rig().open(tester);

      for (final ThemeVariant variant in ThemeVariant.values) {
        expect(
          find.byKey(settingsKey('theme-${variant.name}')),
          findsOneWidget,
        );
      }
    });

    testWidgets('tapping one chooses it', (WidgetTester tester) async {
      final _Rig rig = _Rig();
      await rig.open(tester);

      await _tap(tester, settingsKey('theme-oled'));
      expect(rig.settings.settings.theme, ThemeVariant.oled);

      await _tap(tester, settingsKey('theme-beige'));
      expect(rig.settings.settings.theme, ThemeVariant.beige);
    });
  });

  group('grid', () {
    testWidgets('columns', (WidgetTester tester) async {
      final _Rig rig = _Rig();
      await rig.open(tester);

      await _tap(tester, settingsKey('columns-6'));
      expect(rig.settings.settings.columns, 6);

      await _tap(tester, settingsKey('columns-4'));
      expect(rig.settings.settings.columns, 4);
    });

    testWidgets('gap', (WidgetTester tester) async {
      final _Rig rig = _Rig();
      await rig.open(tester);

      await _tap(tester, settingsKey('gap-tight'));
      expect(rig.settings.settings.gap, GridGap.tight);

      await _tap(tester, settingsKey('gap-relaxed'));
      expect(rig.settings.settings.gap, GridGap.relaxed);
    });
  });

  group('gestures', () {
    testWidgets('swipe down offers what a swipe down can do', (
      WidgetTester tester,
    ) async {
      final _Rig rig = _Rig();
      await rig.open(tester);

      await _tap(tester, settingsKey('down-notifications'));
      expect(rig.settings.settings.swipeDown, GestureAction.notifications);

      await _tap(tester, settingsKey('down-quickSettings'));
      expect(rig.settings.settings.swipeDown, GestureAction.quickSettings);

      await _tap(tester, settingsKey('down-none'));
      expect(rig.settings.settings.swipeDown, GestureAction.none);

      // Not something a swipe down offers.
      expect(find.byKey(settingsKey('down-searchApps')), findsNothing);
    });

    testWidgets('swipe up offers what a swipe up can do', (
      WidgetTester tester,
    ) async {
      final _Rig rig = _Rig();
      await rig.open(tester);

      await _tap(tester, settingsKey('up-searchApps'));
      expect(rig.settings.settings.swipeUp, GestureAction.searchApps);

      await _tap(tester, settingsKey('up-allApps'));
      expect(rig.settings.settings.swipeUp, GestureAction.allApps);

      expect(find.byKey(settingsKey('up-notifications')), findsNothing);
    });
  });

  group('haptics', () {
    testWidgets('are on to begin with, and can be switched off and on', (
      WidgetTester tester,
    ) async {
      final _Rig rig = _Rig();
      await rig.open(tester);
      expect(rig.settings.settings.haptics, isTrue);

      await _tap(tester, settingsKey('haptics-off'));
      expect(rig.settings.settings.haptics, isFalse);

      await _tap(tester, settingsKey('haptics-on'));
      expect(rig.settings.settings.haptics, isTrue);
    });
  });

  group('tile effects', () {
    testWidgets('are on to begin with, and can be switched off and on', (
      WidgetTester tester,
    ) async {
      final _Rig rig = _Rig();
      await rig.open(tester);
      expect(rig.settings.settings.effects, isTrue);

      await _tap(tester, settingsKey('effects-off'));
      expect(rig.settings.settings.effects, isFalse);

      await _tap(tester, settingsKey('effects-on'));
      expect(rig.settings.settings.effects, isTrue);
    });
  });

  group('the Home app', () {
    testWidgets('says when this launcher is it', (WidgetTester tester) async {
      await _Rig(homeRole: FakeHomeRoleService(true)).open(tester);

      expect(_text(tester, settingsHomeStatusKey), Messages.settingsHomeActive);
    });

    testWidgets('says when another app is', (WidgetTester tester) async {
      await _Rig(homeRole: FakeHomeRoleService(false)).open(tester);

      expect(_text(tester, settingsHomeStatusKey), Messages.settingsHomeNotSet);
    });

    testWidgets('says when it cannot tell', (WidgetTester tester) async {
      await _Rig(homeRole: FakeHomeRoleService(null)).open(tester);

      expect(
        _text(tester, settingsHomeStatusKey),
        Messages.settingsHomeUnknown,
      );
    });

    testWidgets('a key opens Android\'s chooser', (WidgetTester tester) async {
      final FakeHomeRoleService role = FakeHomeRoleService(false);
      await _Rig(homeRole: role).open(tester);

      await _tap(tester, settingsKey('open-home'));

      expect(role.openCalls, 1);
    });

    testWidgets('shows what was chosen when the app is back in front', (
      WidgetTester tester,
    ) async {
      final FakeHomeRoleService role = FakeHomeRoleService(false);
      await _Rig(homeRole: role).open(tester);
      expect(_text(tester, settingsHomeStatusKey), Messages.settingsHomeNotSet);

      role.isDefaultAnswer = true;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(_text(tester, settingsHomeStatusKey), Messages.settingsHomeActive);
    });
  });

  group('export', () {
    testWidgets('copies the tiles and settings, and says how many', (
      WidgetTester tester,
    ) async {
      final _Rig rig = _Rig();
      await rig.grid.pin('com.example.maps');
      await rig.grid.pinSystemTile(TileKind.clock);
      await rig.settings.update(const LauncherSettings(columns: 6));
      await rig.open(tester);

      await _tap(tester, settingsKey('export'));

      expect(_text(tester, settingsMessageKey), Messages.settingsExported(2));
      final LayoutImported copied =
          parseLayout(rig.clipboard.text) as LayoutImported;
      expect(copied.tiles.map((PinnedTile t) => t.id), <String>[
        'com.example.maps',
        'clock',
      ]);
      expect(copied.settings.columns, 6);
    });

    testWidgets('a clipboard that refuses is said so', (
      WidgetTester tester,
    ) async {
      final FakeClipboardService clipboard = FakeClipboardService()
        ..works = false;
      await _Rig(clipboard: clipboard).open(tester);

      await _tap(tester, settingsKey('export'));

      expect(
        _text(tester, settingsMessageKey),
        '${Messages.failedPrefix}${Messages.settingsClipboardRefused}',
      );
    });
  });

  group('import', () {
    String layoutOf(List<PinnedTile> tiles, LauncherSettings settings) =>
        exportLayout(tiles: tiles, settings: settings);

    testWidgets('asks first, and does nothing until YES', (
      WidgetTester tester,
    ) async {
      final _Rig rig = _Rig(
        clipboard: FakeClipboardService(
          layoutOf(<PinnedTile>[
            PinnedTile.app(packageName: 'com.example.a', index: 0),
            PinnedTile.app(packageName: 'com.example.b', index: 1),
          ], const LauncherSettings(theme: ThemeVariant.oled)),
        ),
      );
      await rig.grid.pin('com.example.old');
      await rig.open(tester);

      await _tap(tester, settingsKey('import'));

      expect(_text(tester, settingsAskKey), Messages.settingsImportAsk(2, 0));
      expect(rig.grid.pinned.map((PinnedTile t) => t.id), <String>[
        'com.example.old',
      ]);
      expect(rig.settings.settings.theme, ThemeVariant.c64);
    });

    testWidgets('YES replaces the layout and the settings', (
      WidgetTester tester,
    ) async {
      final _Rig rig = _Rig(
        clipboard: FakeClipboardService(
          layoutOf(<PinnedTile>[
            PinnedTile.app(packageName: 'com.example.a', index: 0),
          ], const LauncherSettings(theme: ThemeVariant.oled, columns: 6)),
        ),
      );
      await rig.grid.pin('com.example.old');
      await rig.open(tester);
      await _tap(tester, settingsKey('import'));

      await _tap(tester, settingsYesKey);

      expect(rig.grid.pinned.map((PinnedTile t) => t.id), <String>[
        'com.example.a',
      ]);
      expect(rig.settings.settings.theme, ThemeVariant.oled);
      expect(rig.settings.settings.columns, 6);
      expect(_text(tester, settingsMessageKey), Messages.settingsImported(1));
      expect(find.byKey(settingsAskKey), findsNothing);
    });

    testWidgets('NO leaves everything as it was', (WidgetTester tester) async {
      final _Rig rig = _Rig(
        clipboard: FakeClipboardService(
          layoutOf(<PinnedTile>[
            PinnedTile.app(packageName: 'com.example.a', index: 0),
          ], const LauncherSettings(theme: ThemeVariant.oled)),
        ),
      );
      await rig.grid.pin('com.example.old');
      await rig.open(tester);
      await _tap(tester, settingsKey('import'));

      await _tap(tester, settingsNoKey);

      expect(rig.grid.pinned.map((PinnedTile t) => t.id), <String>[
        'com.example.old',
      ]);
      expect(rig.settings.settings.theme, ThemeVariant.c64);
      expect(find.byKey(settingsAskKey), findsNothing);
    });

    testWidgets('says how many tiles could not be read', (
      WidgetTester tester,
    ) async {
      final _Rig rig = _Rig(
        clipboard: FakeClipboardService(
          '{"format": "$layoutFormat", "version": 1, "tiles": ['
          '{"id": "x", "kind": "gone", "size": "small", "colour": "red"}]}',
        ),
      );
      await rig.open(tester);

      await _tap(tester, settingsKey('import'));

      expect(_text(tester, settingsAskKey), Messages.settingsImportAsk(0, 1));
    });

    testWidgets('an empty clipboard, or something else, is said so', (
      WidgetTester tester,
    ) async {
      final FakeClipboardService clipboard = FakeClipboardService();
      final _Rig rig = _Rig(clipboard: clipboard);
      await rig.open(tester);

      await _tap(tester, settingsKey('import'));
      expect(
        _text(tester, settingsMessageKey),
        '${Messages.failedPrefix}NOTHING TO IMPORT',
      );

      clipboard.text = 'a shopping list';
      await _tap(tester, settingsKey('import'));
      expect(
        _text(tester, settingsMessageKey),
        '${Messages.failedPrefix}THAT IS NOT A LAUNCHER LAYOUT',
      );
      expect(find.byKey(settingsAskKey), findsNothing);
    });
  });

  group('clear and reset', () {
    testWidgets('CLEAR LAYOUT asks how many, and YES removes every tile', (
      WidgetTester tester,
    ) async {
      final _Rig rig = _Rig();
      await rig.grid.pin('com.example.a');
      await rig.grid.pin('com.example.b');
      await rig.open(tester);

      await _tap(tester, settingsKey('clear-layout'));
      expect(_text(tester, settingsAskKey), Messages.settingsClearAsk(2));
      expect(rig.grid.pinned, hasLength(2));

      await _tap(tester, settingsYesKey);
      expect(rig.grid.pinned, isEmpty);
    });

    testWidgets('CLEAR LAYOUT then NO keeps the tiles', (
      WidgetTester tester,
    ) async {
      final _Rig rig = _Rig();
      await rig.grid.pin('com.example.a');
      await rig.open(tester);

      await _tap(tester, settingsKey('clear-layout'));
      await _tap(tester, settingsNoKey);

      expect(rig.grid.pinned, hasLength(1));
    });

    testWidgets('RESET SETTINGS asks, and YES restores the defaults', (
      WidgetTester tester,
    ) async {
      final _Rig rig = _Rig();
      await rig.settings.update(
        const LauncherSettings(
          theme: ThemeVariant.beige,
          columns: 6,
          gap: GridGap.tight,
        ),
      );
      await rig.grid.pin('com.example.a');
      await rig.open(tester);

      await _tap(tester, settingsKey('reset-settings'));
      expect(rig.settings.settings.columns, 6);

      await _tap(tester, settingsYesKey);

      expect(rig.settings.settings, const LauncherSettings());
      // The tiles are not touched by resetting the settings.
      expect(rig.grid.pinned, hasLength(1));
    });
  });
  group('wallpaper', () {
    testWidgets(
      'starts on the picture of the current theme, for the lock screen',
      (WidgetTester tester) async {
        final _Rig rig = _Rig();
        await rig.settings.update(
          const LauncherSettings(theme: ThemeVariant.beige),
        );
        await rig.open(tester);
        await _tap(tester, settingsKey('set-wallpaper'));

        expect(
          _text(tester, settingsAskKey),
          Messages.settingsWallpaperAsk('BEIGE', 'THE LOCK SCREEN'),
        );
      },
    );

    testWidgets('shows the picture it would set', (WidgetTester tester) async {
      await _Rig().open(tester);

      final Image preview = tester.widget<Image>(
        find.descendant(
          of: find.byKey(settingsKey('paper-preview')),
          matching: find.byType(Image),
        ),
      );
      expect(
        ((preview.image as ResizeImage).imageProvider as AssetImage).assetName,
        wallpaperAssetOf(ThemeVariant.c64),
      );

      await _tap(tester, settingsKey('paper-oled'));

      final Image next = tester.widget<Image>(
        find.descendant(
          of: find.byKey(settingsKey('paper-preview')),
          matching: find.byType(Image),
        ),
      );
      expect(
        ((next.image as ResizeImage).imageProvider as AssetImage).assetName,
        wallpaperAssetOf(ThemeVariant.oled),
      );
    });

    testWidgets('sets nothing until YES', (WidgetTester tester) async {
      final _Rig rig = _Rig();
      await rig.open(tester);

      await _tap(tester, settingsKey('set-wallpaper'));
      expect(rig.wallpaper.sets, isEmpty);

      await _tap(tester, settingsNoKey);
      expect(rig.wallpaper.sets, isEmpty);
      expect(find.byKey(settingsAskKey), findsNothing);
    });

    testWidgets('YES sets the chosen picture on the chosen screen', (
      WidgetTester tester,
    ) async {
      final _Rig rig = _Rig();
      await rig.open(tester);
      await _tap(tester, settingsKey('paper-oled'));
      await _tap(tester, settingsKey('paper-on-both'));

      await _tap(tester, settingsKey('set-wallpaper'));
      expect(
        _text(tester, settingsAskKey),
        Messages.settingsWallpaperAsk('OLED', 'BOTH SCREENS'),
      );
      await _tap(tester, settingsYesKey);

      expect(rig.wallpaper.sets, hasLength(1));
      expect(rig.wallpaper.sets.single.$1, greaterThan(1000));
      expect(rig.wallpaper.sets.single.$2, WallpaperTarget.both);
      expect(_text(tester, settingsMessageKey), Messages.settingsWallpaperSet);
    });

    testWidgets('a phone that refuses, or fails, is told so', (
      WidgetTester tester,
    ) async {
      final _Rig rig = _Rig(
        wallpaper: FakeWallpaperService(WallpaperResult.refused),
      );
      await rig.open(tester);

      await _tap(tester, settingsKey('set-wallpaper'));
      await _tap(tester, settingsYesKey);
      expect(
        _text(tester, settingsMessageKey),
        '${Messages.failedPrefix}${Messages.settingsWallpaperRefused}',
      );

      rig.wallpaper.result = WallpaperResult.failed;
      await _tap(tester, settingsKey('set-wallpaper'));
      await _tap(tester, settingsYesKey);
      expect(
        _text(tester, settingsMessageKey),
        '${Messages.failedPrefix}${Messages.settingsWallpaperFailed}',
      );
    });

    testWidgets('DEFAULT WALLPAPER asks, then puts the phone\'s own back', (
      WidgetTester tester,
    ) async {
      final _Rig rig = _Rig();
      await rig.open(tester);
      await _tap(tester, settingsKey('paper-on-home'));

      await _tap(tester, settingsKey('default-wallpaper'));
      expect(
        _text(tester, settingsAskKey),
        Messages.settingsWallpaperClearAsk('THE HOME SCREEN'),
      );
      expect(rig.wallpaper.clears, isEmpty);

      await _tap(tester, settingsYesKey);
      expect(rig.wallpaper.clears, <WallpaperTarget>[WallpaperTarget.home]);
      expect(
        _text(tester, settingsMessageKey),
        Messages.settingsWallpaperCleared,
      );
    });

    testWidgets(
      'its question and answer sit under its own keys, not the layout ones',
      (WidgetTester tester) async {
        final _Rig rig = _Rig();
        await rig.grid.pin('com.example.a');
        await rig.open(tester);

        await _tap(tester, settingsKey('set-wallpaper'));
        final double wallpaperAsk = tester
            .getTopLeft(find.byKey(settingsAskKey))
            .dy;
        final double layoutKeys = tester
            .getTopLeft(find.byKey(settingsKey('export')))
            .dy;
        final double wallpaperKeys = tester
            .getTopLeft(find.byKey(settingsKey('set-wallpaper')))
            .dy;

        expect(wallpaperAsk, greaterThan(wallpaperKeys));
        expect(wallpaperAsk, lessThan(layoutKeys));

        // And a layout question shows under the layout keys instead.
        await _tap(tester, settingsNoKey);
        await _tap(tester, settingsKey('clear-layout'));
        expect(
          tester.getTopLeft(find.byKey(settingsAskKey)).dy,
          greaterThan(
            tester.getTopLeft(find.byKey(settingsKey('clear-layout'))).dy,
          ),
        );
      },
    );
  });
}

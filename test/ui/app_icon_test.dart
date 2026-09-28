import 'dart:async';
import 'dart:typed_data';

import 'package:android_tile_launcher/model/settings.dart';
import 'package:android_tile_launcher/services/app_repository.dart';
import 'package:android_tile_launcher/services/settings_state.dart';
import 'package:android_tile_launcher/ui/app_icon.dart';
import 'package:android_tile_launcher/ui/settings_scope.dart';
import 'package:android_tile_launcher/ui/tile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/in_memory_local_store.dart';

/// A 1x1 PNG: enough to be an image.
final Uint8List _png = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0xF8, 0xCF, 0xC0, 0xF0,
  0x1F, 0x00, 0x05, 0x00, 0x01, 0xFF, 0x89, 0x99, 0x3D, 0x1D, 0x00, 0x00,
  0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

const Key _fallback = Key('fallback');

Future<void> _pump(
  WidgetTester tester,
  AppIconLoader loader, {
  String package = 'pkg.a',
  bool appIcons = true,
  Key? key,
}) async {
  final SettingsState settings = SettingsState(store: InMemoryLocalStore());
  await settings.update(LauncherSettings(appIcons: appIcons));
  await tester.pumpWidget(
    SettingsScope(
      state: settings,
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: AppIcon(
              key: key,
              packageName: package,
              loader: loader,
              size: 40,
              fallback: const SizedBox(key: _fallback),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows the fallback while it loads, then the icon', (
    WidgetTester tester,
  ) async {
    final Completer<Uint8List?> answer = Completer<Uint8List?>();
    await _pump(tester, (String _) => answer.future);

    expect(find.byKey(_fallback), findsOneWidget);
    expect(find.byType(Image), findsNothing);

    answer.complete(_png);
    await tester.pump();

    expect(find.byType(Image), findsOneWidget);
    expect(find.byKey(_fallback), findsNothing);
  });

  testWidgets('is the size it was given, and takes no touches', (
    WidgetTester tester,
  ) async {
    await _pump(tester, (String _) async => _png);
    await tester.pump();

    expect(tester.getSize(find.byType(AppIcon)), const Size(40, 40));
    expect(
      find.descendant(
        of: find.byType(AppIcon),
        matching: find.byType(IgnorePointer),
      ),
      findsWidgets,
    );
  });

  testWidgets('an app with no icon keeps the fallback', (
    WidgetTester tester,
  ) async {
    await _pump(tester, (String _) async => null);
    await tester.pump();

    expect(find.byKey(_fallback), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('an empty answer, or a loader that throws, keeps the fallback', (
    WidgetTester tester,
  ) async {
    await _pump(tester, (String _) async => Uint8List(0));
    await tester.pump();
    expect(find.byKey(_fallback), findsOneWidget);

    await _pump(tester, (String _) async => throw StateError('no'));
    await tester.pump();
    expect(find.byKey(_fallback), findsOneWidget);
  });

  testWidgets('pictures that cannot be read fall back too', (
    WidgetTester tester,
  ) async {
    await _pump(tester, (String _) async => Uint8List.fromList(<int>[1, 2, 3]));
    await tester.pump();

    // The image widget is there, but on failing to decode it shows the
    // fallback in its place.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    expect(find.byKey(_fallback), findsOneWidget);
  });

  testWidgets('with APP ICONS off it stays the fallback', (
    WidgetTester tester,
  ) async {
    await _pump(tester, (String _) async => _png, appIcons: false);
    await tester.pump();

    expect(find.byKey(_fallback), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('another app in the same place asks again', (
    WidgetTester tester,
  ) async {
    final List<String> asked = <String>[];
    Future<Uint8List?> loader(String package) async {
      asked.add(package);
      return package == 'pkg.a' ? _png : null;
    }

    await _pump(tester, loader, package: 'pkg.a');
    await tester.pump();
    expect(find.byType(Image), findsOneWidget);

    await _pump(tester, loader, package: 'pkg.b');
    await tester.pump();

    expect(asked, <String>['pkg.a', 'pkg.b']);
    expect(find.byKey(_fallback), findsOneWidget);
  });

  testWidgets('an answer that arrives after it has gone is ignored', (
    WidgetTester tester,
  ) async {
    final Completer<Uint8List?> answer = Completer<Uint8List?>();
    await _pump(tester, (String _) => answer.future);
    await tester.pumpWidget(const SizedBox());

    answer.complete(_png);
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  group('on an app tile', () {
    Future<void> pumpTile(
      WidgetTester tester, {
      AppIconLoader? loader,
      bool appIcons = true,
    }) async {
      final SettingsState settings = SettingsState(store: InMemoryLocalStore());
      await settings.update(LauncherSettings(appIcons: appIcons));
      await tester.pumpWidget(
        SettingsScope(
          state: settings,
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 90,
                height: 90,
                child: AppTileContent(
                  label: 'Clock',
                  ink: Colors.white,
                  packageName: loader == null ? null : 'pkg.clock',
                  iconOf: loader,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('the icon takes the place of the letter, above the label', (
      WidgetTester tester,
    ) async {
      await pumpTile(tester, loader: (String _) async => _png);

      expect(find.byType(AppIcon), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(find.text('C'), findsNothing);
      expect(find.text('CLOCK'), findsOneWidget);
      expect(
        tester.getBottomLeft(find.byType(AppIcon)).dy,
        lessThanOrEqualTo(tester.getTopLeft(find.text('CLOCK')).dy),
      );
    });

    testWidgets('is never bigger than its limit, or the room there is', (
      WidgetTester tester,
    ) async {
      await pumpTile(tester, loader: (String _) async => _png);

      final double side = tester.getSize(find.byType(AppIcon)).width;
      expect(side, lessThanOrEqualTo(AppTileContent.maxIcon));
      expect(side, lessThanOrEqualTo(90 - AppTileContent.labelSpace));
    });

    testWidgets('the letter shows while there is no icon', (
      WidgetTester tester,
    ) async {
      await pumpTile(tester, loader: (String _) async => null);

      expect(find.text('C'), findsOneWidget);
    });

    testWidgets('the letter shows with APP ICONS off', (
      WidgetTester tester,
    ) async {
      await pumpTile(tester, loader: (String _) async => _png, appIcons: false);

      expect(find.text('C'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('a tile with no loader (a contact) is just the letter', (
      WidgetTester tester,
    ) async {
      await pumpTile(tester);

      expect(find.byType(AppIcon), findsNothing);
      expect(find.text('C'), findsOneWidget);
    });
  });
}

import 'package:android_tile_launcher/model/tile.dart';
import 'package:android_tile_launcher/services/grid_state.dart';
import 'package:android_tile_launcher/ui/add_tile_sheet.dart';
import 'package:android_tile_launcher/ui/contact_picker.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_contacts.dart';
import '../fakes/in_memory_local_store.dart';

GridState _gridState() => GridState(store: InMemoryLocalStore());

Future<void> _open(WidgetTester tester, GridState gridState) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: tileLauncherTheme(),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showAddTileSheet(
              context,
              gridState: gridState,
              contacts: FakeContactsRepository(),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lists every system kind not already pinned', (
    WidgetTester tester,
  ) async {
    final GridState gridState = _gridState();

    await _open(tester, gridState);

    expect(find.text('CLOCK'), findsOneWidget);
    expect(find.text('DEVICE'), findsOneWidget);
    expect(find.text('WEATHER'), findsOneWidget);
    expect(find.text('SOUND'), findsOneWidget);
    expect(find.text('FLASHLIGHT'), findsOneWidget);
  });

  testWidgets('tapping a kind pins it and closes the sheet', (
    WidgetTester tester,
  ) async {
    final GridState gridState = _gridState();

    await _open(tester, gridState);
    await tester.tap(find.text('CLOCK'));
    await tester.pumpAndSettle();

    expect(gridState.isPinned('clock'), isTrue);
    expect(find.text('CLOCK'), findsNothing);
  });

  testWidgets('an already-pinned kind is not offered again', (
    WidgetTester tester,
  ) async {
    final GridState gridState = _gridState();
    for (final TileKind kind in TileKind.values) {
      if (kind != TileKind.app && kind != TileKind.contact) {
        await gridState.pinSystemTile(kind);
      }
    }

    await _open(tester, gridState);

    // Every system tile is pinned; only CONTACT is still on offer.
    expect(find.text('CLOCK'), findsNothing);
    expect(find.text('SOUND'), findsNothing);
    expect(find.text('CONTACT'), findsOneWidget);
  });

  testWidgets('CONTACT is always offered, and opens the picker', (
    WidgetTester tester,
  ) async {
    final GridState gridState = _gridState();
    await gridState.pinContact(key: 'k0', name: 'Someone Else');

    await _open(tester, gridState);
    expect(find.text('CONTACT'), findsOneWidget);
    await tester.tap(find.text('CONTACT'));
    await tester.pumpAndSettle();

    expect(find.byKey(contactSearchKey), findsOneWidget);
    // Nothing was pinned by choosing the kind itself.
    expect(gridState.pinned, hasLength(1));
  });
}

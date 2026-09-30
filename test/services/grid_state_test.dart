import 'package:android_tile_launcher/model/c64_colour.dart';
import 'package:android_tile_launcher/model/pinned_tile.dart';
import 'package:android_tile_launcher/model/tile.dart';
import 'package:android_tile_launcher/model/tile_size.dart';
import 'package:android_tile_launcher/services/grid_state.dart';
import 'package:android_tile_launcher/services/local_store_exception.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/in_memory_local_store.dart';

GridState _state(InMemoryLocalStore store) => GridState(store: store);

const PinnedTile _clock = PinnedTile(
  id: 'pkg.clock',
  size: TileSize.small,
  colour: C64Colour.red,
);
const PinnedTile _maps = PinnedTile(
  id: 'pkg.maps',
  size: TileSize.medium,
  colour: C64Colour.cyan,
);

void main() {
  test('starts with nothing pinned', () {
    expect(_state(InMemoryLocalStore()).pinned, isEmpty);
  });

  test('pin adds a small tile with a cycled colour, and saves', () async {
    final InMemoryLocalStore store = InMemoryLocalStore();
    final GridState state = _state(store);

    await state.pin('pkg.clock');
    await state.pin('pkg.maps');

    expect(state.pinned.map((p) => p.id), ['pkg.clock', 'pkg.maps']);
    expect(state.pinned[0].size, TileSize.small);
    expect(state.pinned[0].colour, isNot(state.pinned[1].colour));
    expect(state.isPinned('pkg.clock'), isTrue);
    expect(state.isPinned('pkg.other'), isFalse);
    expect(store.writes, 2);
  });

  test('pinning an already-pinned package is a no-op', () async {
    final InMemoryLocalStore store = InMemoryLocalStore();
    final GridState state = _state(store);
    int notifications = 0;
    state.addListener(() => notifications++);

    await state.pin('pkg.clock');
    await state.pin('pkg.clock');

    expect(state.pinned, hasLength(1));
    expect(notifications, 1);
    expect(store.writes, 1);
  });

  test('unpin removes a tile and saves', () async {
    final InMemoryLocalStore store = InMemoryLocalStore();
    final GridState state = _state(store);
    await state.pin('pkg.clock');

    await state.unpin('pkg.clock');

    expect(state.pinned, isEmpty);
    expect(state.isPinned('pkg.clock'), isFalse);
  });

  test('unpinning something not pinned does not notify or save', () async {
    final InMemoryLocalStore store = InMemoryLocalStore();
    final GridState state = _state(store);
    int notifications = 0;
    state.addListener(() => notifications++);

    await state.unpin('pkg.clock');

    expect(notifications, 0);
    expect(store.writes, 0);
  });

  test('toggle flips membership', () async {
    final GridState state = _state(InMemoryLocalStore());

    await state.toggle('pkg.clock');
    expect(state.isPinned('pkg.clock'), isTrue);

    await state.toggle('pkg.clock');
    expect(state.isPinned('pkg.clock'), isFalse);
  });

  test('pinned is unmodifiable', () async {
    final GridState state = _state(InMemoryLocalStore());
    await state.pin('pkg.clock');

    expect(() => state.pinned.add(_maps), throwsUnsupportedError);
  });

  test('a failed save still pins, then throws', () async {
    final GridState state = _state(
      InMemoryLocalStore(failure: const LocalStoreException('disk full')),
    );

    await expectLater(
      state.pin('pkg.clock'),
      throwsA(isA<LocalStoreException>()),
    );

    expect(state.isPinned('pkg.clock'), isTrue);
  });

  group('replaceAll', () {
    test('replaces the whole list and saves', () async {
      final InMemoryLocalStore store = InMemoryLocalStore();
      final GridState state = _state(store);
      await state.pin('pkg.clock');

      await state.replaceAll([_maps]);

      expect(state.pinned, [_maps]);
      expect(await store.read(GridState.storeKey), [_maps.toJson()]);
    });

    test('notifies even to an empty list', () async {
      final InMemoryLocalStore store = InMemoryLocalStore();
      final GridState state = _state(store);
      await state.pin('pkg.clock');
      int notifications = 0;
      state.addListener(() => notifications++);

      await state.replaceAll(const []);

      expect(state.pinned, isEmpty);
      expect(notifications, 1);
    });
  });

  group('load', () {
    test('applies a saved pinned list', () async {
      final InMemoryLocalStore store = InMemoryLocalStore();
      await store.write(GridState.storeKey, [_clock.toJson(), _maps.toJson()]);
      final GridState state = _state(store);

      await state.load();

      expect(state.pinned, [_clock, _maps]);
    });

    test('stays empty when nothing is saved', () async {
      final GridState state = _state(InMemoryLocalStore());

      await state.load();

      expect(state.pinned, isEmpty);
    });

    test('ignores malformed saved data', () async {
      final InMemoryLocalStore store = InMemoryLocalStore();
      await store.write(GridState.storeKey, 'not a list');
      final GridState state = _state(store);

      await state.load();

      expect(state.pinned, isEmpty);
    });

    test('skips malformed entries in a saved list', () async {
      final InMemoryLocalStore store = InMemoryLocalStore();
      await store.write(GridState.storeKey, [
        _clock.toJson(),
        {'id': 'pkg.bad'}, // missing kind/size/colour
        42,
        null,
      ]);
      final GridState state = _state(store);

      await state.load();

      expect(state.pinned, [_clock]);
    });

    test('stays empty when the store cannot be read', () async {
      final GridState state = _state(
        InMemoryLocalStore(failure: const LocalStoreException('unreadable')),
      );

      await state.load();

      expect(state.pinned, isEmpty);
    });

    test('notifies when the saved list is applied', () async {
      final InMemoryLocalStore store = InMemoryLocalStore();
      await store.write(GridState.storeKey, [_clock.toJson()]);
      final GridState state = _state(store);
      int notifications = 0;
      state.addListener(() => notifications++);

      await state.load();

      expect(notifications, 1);
    });

    test('a pinned grid survives a restart', () async {
      final InMemoryLocalStore store = InMemoryLocalStore();
      await _state(store).pin('pkg.clock');

      final GridState restarted = _state(store);
      await restarted.load();

      expect(restarted.pinned.map((p) => p.id), ['pkg.clock']);
    });
  });

  group('pinSystemTile', () {
    test('adds a wide tile keyed by the kind\'s own name, and saves', () async {
      final InMemoryLocalStore store = InMemoryLocalStore();
      final GridState state = _state(store);

      await state.pinSystemTile(TileKind.clock);

      expect(state.pinned, hasLength(1));
      expect(state.pinned.single.id, 'clock');
      expect(state.pinned.single.kind, TileKind.clock);
      expect(state.pinned.single.size, TileSize.wide);
      expect(state.isPinned('clock'), isTrue);
      expect(store.writes, 1);
    });

    test('pinning the same system kind twice is a no-op', () async {
      final GridState state = _state(InMemoryLocalStore());

      await state.pinSystemTile(TileKind.clock);
      await state.pinSystemTile(TileKind.clock);

      expect(state.pinned, hasLength(1));
    });

    test('an app tile and a system tile can coexist', () async {
      final GridState state = _state(InMemoryLocalStore());

      await state.pin('pkg.clock');
      await state.pinSystemTile(TileKind.clock);

      expect(state.pinned.map((p) => p.id), ['pkg.clock', 'clock']);
    });
  });

  group('pinContact', () {
    test(
      'adds a small tile per person, carrying the name, and saves',
      () async {
        final InMemoryLocalStore store = InMemoryLocalStore();
        final GridState state = _state(store);

        await state.pinContact(key: 'k1', name: 'Anna');

        final PinnedTile tile = state.pinned.single;
        expect(tile.kind, TileKind.contact);
        expect(tile.id, contactTileId('k1'));
        expect(tile.size, TileSize.small);
        expect(tile.label, 'Anna');
        expect(state.isPinned(contactTileId('k1')), isTrue);
        expect(store.writes, 1);
      },
    );

    test('two people are two tiles; the same person twice is one', () async {
      final GridState state = _state(InMemoryLocalStore());

      await state.pinContact(key: 'k1', name: 'Anna');
      await state.pinContact(key: 'k2', name: 'Bo');
      await state.pinContact(key: 'k1', name: 'Anna');

      expect(state.pinned.map((p) => p.label), <String?>['Anna', 'Bo']);
    });

    test('the name survives a restart', () async {
      final InMemoryLocalStore store = InMemoryLocalStore();
      await _state(store).pinContact(key: 'k1', name: 'Anna');

      final GridState restarted = _state(store);
      await restarted.load();

      expect(restarted.pinned.single.label, 'Anna');
      expect(restarted.pinned.single.id, contactTileId('k1'));
    });
  });

  group('pinGame', () {
    test(
      'adds a wide tile per game module, carrying the label, and saves',
      () async {
        final InMemoryLocalStore store = InMemoryLocalStore();
        final GridState state = _state(store);

        await state.pinGame(moduleId: 'tetris', label: 'TETRIS');

        final PinnedTile tile = state.pinned.single;
        expect(tile.kind, TileKind.game);
        expect(tile.id, gameTileId('tetris'));
        expect(tile.size, TileSize.wide);
        expect(tile.label, 'TETRIS');
        expect(state.isPinned(gameTileId('tetris')), isTrue);
        expect(store.writes, 1);
      },
    );

    test('pinning the same game twice changes nothing', () async {
      final GridState state = _state(InMemoryLocalStore());

      await state.pinGame(moduleId: 'tetris', label: 'TETRIS');
      await state.pinGame(moduleId: 'tetris', label: 'TETRIS');

      expect(state.pinned, hasLength(1));
    });
  });
}

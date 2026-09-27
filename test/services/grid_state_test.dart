import 'package:android_tile_launcher/services/grid_state.dart';
import 'package:android_tile_launcher/services/local_store_exception.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/in_memory_local_store.dart';

GridState _state(InMemoryLocalStore store) => GridState(store: store);

void main() {
  test('starts with nothing pinned', () {
    expect(_state(InMemoryLocalStore()).pinned, isEmpty);
  });

  test('pin adds a package, in pin order, and saves it', () async {
    final InMemoryLocalStore store = InMemoryLocalStore();
    final GridState state = _state(store);

    await state.pin('pkg.clock');
    await state.pin('pkg.maps');

    expect(state.pinned, ['pkg.clock', 'pkg.maps']);
    expect(state.isPinned('pkg.clock'), isTrue);
    expect(state.isPinned('pkg.other'), isFalse);
    expect(await store.read(GridState.storeKey), ['pkg.clock', 'pkg.maps']);
  });

  test('pinning an already-pinned package is a no-op', () async {
    final InMemoryLocalStore store = InMemoryLocalStore();
    final GridState state = _state(store);
    int notifications = 0;
    state.addListener(() => notifications++);

    await state.pin('pkg.clock');
    await state.pin('pkg.clock');

    expect(state.pinned, ['pkg.clock']);
    expect(notifications, 1);
    expect(store.writes, 1);
  });

  test('unpin removes a package and saves it', () async {
    final InMemoryLocalStore store = InMemoryLocalStore();
    final GridState state = _state(store);
    await state.pin('pkg.clock');

    await state.unpin('pkg.clock');

    expect(state.pinned, isEmpty);
    expect(state.isPinned('pkg.clock'), isFalse);
    expect(await store.read(GridState.storeKey), isEmpty);
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

    expect(() => state.pinned.add('pkg.maps'), throwsUnsupportedError);
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

  group('load', () {
    test('applies a saved pinned list', () async {
      final InMemoryLocalStore store = InMemoryLocalStore();
      await store.write(GridState.storeKey, ['pkg.clock', 'pkg.maps']);
      final GridState state = _state(store);

      await state.load();

      expect(state.pinned, ['pkg.clock', 'pkg.maps']);
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

    test('skips non-string entries in a saved list', () async {
      final InMemoryLocalStore store = InMemoryLocalStore();
      await store.write(GridState.storeKey, ['pkg.clock', 42, null]);
      final GridState state = _state(store);

      await state.load();

      expect(state.pinned, ['pkg.clock']);
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
      await store.write(GridState.storeKey, ['pkg.clock']);
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

      expect(restarted.pinned, ['pkg.clock']);
    });
  });
}

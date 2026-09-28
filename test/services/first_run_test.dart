import 'package:android_tile_launcher/services/first_run.dart';
import 'package:android_tile_launcher/services/local_store_exception.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/in_memory_local_store.dart';

void main() {
  test('a phone that has never run the launcher is on its first run', () async {
    final FirstRun firstRun = FirstRun(store: InMemoryLocalStore());

    await firstRun.load();

    expect(firstRun.isFirstRun, isTrue);
  });

  test('before load it is not the first run: nothing plays by accident', () {
    expect(FirstRun(store: InMemoryLocalStore()).isFirstRun, isFalse);
  });

  test('once seen it is remembered across a restart', () async {
    final InMemoryLocalStore store = InMemoryLocalStore();
    final FirstRun first = FirstRun(store: store);
    await first.load();

    await first.markSeen();
    expect(first.isFirstRun, isFalse);

    final FirstRun afterRestart = FirstRun(store: store);
    await afterRestart.load();
    expect(afterRestart.isFirstRun, isFalse);
  });

  test('a store that cannot be read counts as seen', () async {
    final FirstRun firstRun = FirstRun(
      store: InMemoryLocalStore(
        failure: const LocalStoreException('unreadable'),
      ),
    );

    await firstRun.load();

    expect(firstRun.isFirstRun, isFalse);
  });

  test('a store that cannot be written does not throw', () async {
    final InMemoryLocalStore store = InMemoryLocalStore();
    final FirstRun firstRun = FirstRun(store: store);
    await firstRun.load();
    store.failure = const LocalStoreException('disk full');

    await firstRun.markSeen();

    expect(firstRun.isFirstRun, isFalse);
  });

  test('anything but true stored is still a first run', () async {
    final InMemoryLocalStore store = InMemoryLocalStore();
    await store.write(FirstRun.storeKey, 'yes');
    final FirstRun firstRun = FirstRun(store: store);

    await firstRun.load();

    expect(firstRun.isFirstRun, isTrue);
  });
}

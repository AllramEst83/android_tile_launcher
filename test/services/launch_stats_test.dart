import 'package:android_tile_launcher/services/launch_stats.dart';
import 'package:android_tile_launcher/services/local_store_exception.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/in_memory_local_store.dart';

Future<void> _launch(LaunchStats stats, String app, int times) async {
  for (int i = 0; i < times; i++) {
    await stats.record(app);
  }
}

void main() {
  test('counts each launch of each app', () async {
    final LaunchStats stats = LaunchStats(store: InMemoryLocalStore());

    await _launch(stats, 'a', 3);
    await _launch(stats, 'b', 1);

    expect(stats.countOf('a'), 3);
    expect(stats.countOf('b'), 1);
    expect(stats.countOf('never'), 0);
  });

  test('the most used come first, ties in package order', () async {
    final LaunchStats stats = LaunchStats(store: InMemoryLocalStore());
    await _launch(stats, 'c', 5);
    await _launch(stats, 'b', 3);
    await _launch(stats, 'a', 3);
    await _launch(stats, 'd', 9);

    expect(stats.mostUsed(), <String>['d', 'c', 'a', 'b']);
  });

  test('an app opened once is not yet a habit', () async {
    final LaunchStats stats = LaunchStats(store: InMemoryLocalStore());
    await _launch(stats, 'once', 1);
    await _launch(stats, 'twice', LaunchStats.minLaunches);

    expect(stats.mostUsed(), <String>['twice']);
  });

  test('at most the limit, and never an excluded app', () async {
    final LaunchStats stats = LaunchStats(store: InMemoryLocalStore());
    await _launch(stats, 'a', 9);
    await _launch(stats, 'b', 8);
    await _launch(stats, 'c', 7);

    expect(stats.mostUsed(limit: 2), <String>['a', 'b']);
    expect(stats.mostUsed(limit: 2, excluding: <String>{'a'}), <String>[
      'b',
      'c',
    ]);
  });

  test('counts survive a restart', () async {
    final InMemoryLocalStore store = InMemoryLocalStore();
    await _launch(LaunchStats(store: store), 'a', 4);

    final LaunchStats afterRestart = LaunchStats(store: store);
    await afterRestart.load();

    expect(afterRestart.countOf('a'), 4);
    await afterRestart.record('a');
    expect(afterRestart.countOf('a'), 5);
  });

  test('damaged saved counts are skipped, not fatal', () async {
    final InMemoryLocalStore store = InMemoryLocalStore();
    await store.write(LaunchStats.storeKey, <String, Object?>{
      'good': 3,
      'zero': 0,
      'negative': -2,
      'text': 'many',
    });
    final LaunchStats stats = LaunchStats(store: store);

    await stats.load();

    expect(stats.countOf('good'), 3);
    expect(stats.countOf('zero') + stats.countOf('negative'), 0);
    expect(stats.countOf('text'), 0);
  });

  test('something that is not a map is ignored', () async {
    final InMemoryLocalStore store = InMemoryLocalStore();
    await store.write(LaunchStats.storeKey, <int>[1, 2]);
    final LaunchStats stats = LaunchStats(store: store);

    await stats.load();

    expect(stats.mostUsed(), isEmpty);
  });

  test('a store that cannot be read starts empty and still counts', () async {
    final InMemoryLocalStore store = InMemoryLocalStore(
      failure: const LocalStoreException('broken'),
    );
    final LaunchStats stats = LaunchStats(store: store);

    await stats.load();
    await _launch(stats, 'a', 2);

    expect(stats.mostUsed(), <String>['a']);
  });

  test('the least used are forgotten past the limit', () async {
    final LaunchStats stats = LaunchStats(store: InMemoryLocalStore());
    await _launch(stats, 'favourite', 5);
    for (int i = 0; i < LaunchStats.maxTracked; i++) {
      await stats.record('app$i');
    }

    expect(stats.countOf('favourite'), 5);
    int kept = 1;
    for (int i = 0; i < LaunchStats.maxTracked; i++) {
      if (stats.countOf('app$i') > 0) kept++;
    }
    expect(kept, LaunchStats.maxTracked);
  });
}

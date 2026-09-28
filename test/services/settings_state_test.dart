import 'package:android_tile_launcher/model/settings.dart';
import 'package:android_tile_launcher/services/local_store_exception.dart';
import 'package:android_tile_launcher/services/settings_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/in_memory_local_store.dart';

SettingsState _state(InMemoryLocalStore store) => SettingsState(store: store);

void main() {
  group('load', () {
    test('with nothing saved, the defaults, and nothing announced', () async {
      final SettingsState state = _state(InMemoryLocalStore());
      int notified = 0;
      state.addListener(() => notified++);

      await state.load();

      expect(state.settings, const LauncherSettings());
      expect(notified, 0);
    });

    test('applies what was last saved, and announces it', () async {
      final InMemoryLocalStore store = InMemoryLocalStore();
      await _state(store)
          .update(const LauncherSettings(theme: ThemeVariant.oled, columns: 6));
      final SettingsState restarted = _state(store);
      int notified = 0;
      restarted.addListener(() => notified++);

      await restarted.load();

      expect(restarted.settings.theme, ThemeVariant.oled);
      expect(restarted.settings.columns, 6);
      expect(notified, 1);
    });

    test('a damaged value keeps the defaults', () async {
      final InMemoryLocalStore store = InMemoryLocalStore();
      await store.write(SettingsState.storeKey, 'garbage');
      final SettingsState state = _state(store);

      await state.load();

      expect(state.settings, const LauncherSettings());
    });

    test('an unreadable store is not fatal', () async {
      final SettingsState state = _state(
        InMemoryLocalStore(failure: const LocalStoreException('unreadable')),
      );

      await state.load();

      expect(state.settings, const LauncherSettings());
    });
  });

  group('update', () {
    test('is in effect at once, announces, and saves', () async {
      final InMemoryLocalStore store = InMemoryLocalStore();
      final SettingsState state = _state(store);
      int notified = 0;
      state.addListener(() => notified++);

      await state.update(const LauncherSettings(gap: GridGap.relaxed));

      expect(state.settings.gap, GridGap.relaxed);
      expect(notified, 1);
      expect(store.writes, 1);
    });

    test('the same settings again change and save nothing', () async {
      final InMemoryLocalStore store = InMemoryLocalStore();
      final SettingsState state = _state(store);
      int notified = 0;
      state.addListener(() => notified++);

      await state.update(const LauncherSettings());

      expect(notified, 0);
      expect(store.writes, 0);
    });

    test('a failed save still leaves the change in effect', () async {
      final SettingsState state = _state(
        InMemoryLocalStore(failure: const LocalStoreException('full')),
      );

      await expectLater(
        state.update(const LauncherSettings(columns: 6)),
        throwsA(isA<LocalStoreException>()),
      );

      expect(state.settings.columns, 6);
    });
  });

  test('reset puts every setting back to its default', () async {
    final SettingsState state = _state(InMemoryLocalStore());
    await state.update(
      const LauncherSettings(
        theme: ThemeVariant.beige,
        columns: 6,
        gap: GridGap.tight,
      ),
    );

    await state.reset();

    expect(state.settings, const LauncherSettings());
  });
}

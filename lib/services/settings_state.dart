import 'package:android_tile_launcher/model/settings.dart';
import 'package:android_tile_launcher/services/local_store.dart';
import 'package:android_tile_launcher/services/local_store_exception.dart';
import 'package:flutter/foundation.dart';

/// The launcher's settings, kept in a [LocalStore] so they survive a restart;
/// [load] applies whatever was last saved. Like `GridState`, a change is in
/// effect at once and notifies, then saves; a failed save still leaves the
/// change in effect for this run.
class SettingsState extends ChangeNotifier {
  // Not `this._store`: that would make the parameter name the private
  // `_store`, which a test in another file could not pass by name.
  SettingsState({
    required LocalStore store,
    // ignore: prefer_initializing_formals
  }) : _store = store;

  static const String storeKey = 'settings';

  final LocalStore _store;
  LauncherSettings _settings = const LauncherSettings();

  LauncherSettings get settings => _settings;

  /// Applies whatever was last saved. A missing, unreadable or malformed value
  /// keeps the defaults: losing a setting is never worth failing startup over.
  Future<void> load() async {
    final Object? saved;
    try {
      saved = await _store.read(storeKey);
    } on LocalStoreException {
      return;
    }
    if (saved == null) return;
    _settings = LauncherSettings.fromJson(saved);
    notifyListeners();
  }

  /// Makes [settings] the settings, and saves them. Already in effect even if
  /// the returned future throws `LocalStoreException`: only the save failed.
  Future<void> update(LauncherSettings settings) {
    if (settings == _settings) return Future<void>.value();
    _settings = settings;
    notifyListeners();
    return _store.write(storeKey, settings.toJson());
  }

  /// Every setting back to its default.
  Future<void> reset() => update(const LauncherSettings());
}

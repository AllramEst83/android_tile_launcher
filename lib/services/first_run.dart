import 'package:android_tile_launcher/services/local_store.dart';
import 'package:android_tile_launcher/services/local_store_exception.dart';

/// Whether this is the first time the launcher has started on this phone, so
/// the boot screen can play its whole show once and stay short afterwards.
///
/// Kept in a [LocalStore]. Anything unreadable counts as "seen already": a
/// launcher that cannot remember must not replay a slow animation every time
/// it starts.
class FirstRun {
  // Not `this._store`: see `GridState`.
  FirstRun({
    required LocalStore store,
    // ignore: prefer_initializing_formals
  }) : _store = store;

  static const String storeKey = 'boot_seen';

  final LocalStore _store;
  bool _isFirstRun = false;

  /// True from [load] until the boot animation has played and [markSeen] ran.
  bool get isFirstRun => _isFirstRun;

  /// Reads whether the boot animation has been seen. Never throws.
  Future<void> load() async {
    try {
      _isFirstRun = await _store.read(storeKey) != true;
    } on LocalStoreException {
      _isFirstRun = false;
    }
  }

  /// Remembers that the boot animation was seen. Never throws: a failed save
  /// only means it may play once more.
  Future<void> markSeen() async {
    _isFirstRun = false;
    try {
      await _store.write(storeKey, true);
    } on LocalStoreException {
      // Nothing to do; see above.
    }
  }
}

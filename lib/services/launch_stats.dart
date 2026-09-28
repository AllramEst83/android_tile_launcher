import 'package:android_tile_launcher/services/local_store.dart';
import 'package:android_tile_launcher/services/local_store_exception.dart';

/// How often each app has been opened from the launcher (a home tile or the
/// drawer), so "+ ADD TILE" can suggest the ones used most. Only counts kept
/// on this phone, in a [LocalStore]; nothing is sent anywhere.
///
/// Never throws: statistics are never worth failing a launch or startup over,
/// so an unreadable store starts empty and a failed save is dropped.
class LaunchStats {
  // Not `this._store`: see `GridState`.
  LaunchStats({
    required LocalStore store,
    // ignore: prefer_initializing_formals
  }) : _store = store;

  static const String storeKey = 'launch_counts';

  /// When more apps than this are counted, the least used are forgotten, so
  /// the saved map cannot grow for ever.
  static const int maxTracked = 200;

  /// An app must have been opened at least this often to be suggested: one
  /// launch is not a habit.
  static const int minLaunches = 2;

  final LocalStore _store;
  final Map<String, int> _counts = <String, int>{};

  /// Reads the saved counts. Anything unreadable or malformed is skipped.
  Future<void> load() async {
    final Object? saved;
    try {
      saved = await _store.read(storeKey);
    } on LocalStoreException {
      return;
    }
    if (saved is! Map) return;
    _counts.clear();
    saved.forEach((Object? key, Object? value) {
      if (key is String && value is int && value > 0) _counts[key] = value;
    });
  }

  /// Counts one launch of [packageName], and saves. Counted at once, even if
  /// the save then fails.
  Future<void> record(String packageName) async {
    _counts[packageName] = (_counts[packageName] ?? 0) + 1;
    if (_counts.length > maxTracked) _forgetLeastUsed();
    try {
      await _store.write(storeKey, Map<String, int>.of(_counts));
    } on LocalStoreException {
      // Nothing to do; see above.
    }
  }

  int countOf(String packageName) => _counts[packageName] ?? 0;

  /// The apps opened most, most first (ties in package-name order), at most
  /// [limit], leaving out any in [excluding] and any opened fewer than
  /// [minLaunches] times.
  List<String> mostUsed({int limit = 4, Set<String> excluding = const {}}) {
    final List<MapEntry<String, int>> ranked =
        <MapEntry<String, int>>[
          for (final MapEntry<String, int> e in _counts.entries)
            if (e.value >= minLaunches && !excluding.contains(e.key)) e,
        ]..sort((MapEntry<String, int> a, MapEntry<String, int> b) {
          final int byCount = b.value.compareTo(a.value);
          return byCount != 0 ? byCount : a.key.compareTo(b.key);
        });
    return <String>[
      for (final MapEntry<String, int> e in ranked.take(limit)) e.key,
    ];
  }

  void _forgetLeastUsed() {
    final List<MapEntry<String, int>> ranked = _counts.entries.toList()
      ..sort((MapEntry<String, int> a, MapEntry<String, int> b) {
        final int byCount = a.value.compareTo(b.value);
        return byCount != 0 ? byCount : b.key.compareTo(a.key);
      });
    for (final MapEntry<String, int> e in ranked.take(
      _counts.length - maxTracked,
    )) {
      _counts.remove(e.key);
    }
  }
}

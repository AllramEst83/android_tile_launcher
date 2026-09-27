import 'package:android_tile_launcher/services/local_store.dart';
import 'package:android_tile_launcher/services/local_store_exception.dart';
import 'package:flutter/foundation.dart';

/// Which apps are on the home mosaic, in pin order. Kept in a [LocalStore] so
/// it survives a restart; [load] applies whatever was last saved. Phase 6
/// lets the grid editor change a tile's size and colour, not just whether
/// it's on the grid at all.
class GridState extends ChangeNotifier {
  // Not `this._store`: that would make the parameter name the private
  // `_store`, which a test in another file could not pass by name.
  GridState({
    required LocalStore store,
    // ignore: prefer_initializing_formals
  }) : _store = store;

  static const String storeKey = 'pinned_tiles';

  final LocalStore _store;
  final List<String> _pinned = <String>[];

  /// Pinned package names, in the order they were pinned.
  List<String> get pinned => List.unmodifiable(_pinned);

  bool isPinned(String packageName) => _pinned.contains(packageName);

  /// Applies whatever was last saved. A missing, unreadable or malformed
  /// value keeps the grid empty: losing a pinned layout is never worth
  /// failing startup over.
  Future<void> load() async {
    final Object? saved;
    try {
      saved = await _store.read(storeKey);
    } on LocalStoreException {
      return;
    }
    if (saved is! List) return;
    final List<String> packages = <String>[
      for (final Object? entry in saved)
        if (entry is String) entry,
    ];
    if (packages.isEmpty) return;
    _pinned
      ..clear()
      ..addAll(packages);
    notifyListeners();
  }

  /// Pins [packageName] and saves. Already in effect for this run even if
  /// the returned future throws `LocalStoreException` — only the save
  /// failed, not the pin.
  Future<void> pin(String packageName) {
    if (_pinned.contains(packageName)) return Future<void>.value();
    _pinned.add(packageName);
    notifyListeners();
    return _persist();
  }

  /// Unpins [packageName] and saves. Same failure contract as [pin].
  Future<void> unpin(String packageName) {
    if (!_pinned.remove(packageName)) return Future<void>.value();
    notifyListeners();
    return _persist();
  }

  Future<void> toggle(String packageName) =>
      isPinned(packageName) ? unpin(packageName) : pin(packageName);

  Future<void> _persist() => _store.write(storeKey, _pinned);
}

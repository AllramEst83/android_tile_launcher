import 'package:android_tile_launcher/model/pinned_tile.dart';
import 'package:android_tile_launcher/services/local_store.dart';
import 'package:android_tile_launcher/services/local_store_exception.dart';
import 'package:flutter/foundation.dart';

/// Which apps are on the home mosaic, each tile's size and colour, and the
/// order they're pinned in. Kept in a [LocalStore] so it survives a restart;
/// [load] applies whatever was last saved.
class GridState extends ChangeNotifier {
  // Not `this._store`: that would make the parameter name the private
  // `_store`, which a test in another file could not pass by name.
  GridState({
    required LocalStore store,
    // ignore: prefer_initializing_formals
  }) : _store = store;

  static const String storeKey = 'pinned_tiles';

  final LocalStore _store;
  final List<PinnedTile> _pinned = <PinnedTile>[];

  /// Pinned tiles, in pin order.
  List<PinnedTile> get pinned => List.unmodifiable(_pinned);

  bool isPinned(String packageName) =>
      _pinned.any((PinnedTile p) => p.packageName == packageName);

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
    final List<PinnedTile> tiles = <PinnedTile>[
      for (final Object? entry in saved)
        if (PinnedTile.fromJson(entry) case final PinnedTile tile) tile,
    ];
    if (tiles.isEmpty) return;
    _pinned
      ..clear()
      ..addAll(tiles);
    notifyListeners();
  }

  /// Pins [packageName] with its default size and colour, and saves. Already
  /// in effect for this run even if the returned future throws
  /// `LocalStoreException` — only the save failed, not the pin.
  Future<void> pin(String packageName) {
    if (isPinned(packageName)) return Future<void>.value();
    _pinned.add(
      PinnedTile.withDefaults(packageName: packageName, index: _pinned.length),
    );
    notifyListeners();
    return _persist();
  }

  /// Unpins [packageName] and saves. Same failure contract as [pin].
  Future<void> unpin(String packageName) {
    final int before = _pinned.length;
    _pinned.removeWhere((PinnedTile p) => p.packageName == packageName);
    if (_pinned.length == before) return Future<void>.value();
    notifyListeners();
    return _persist();
  }

  Future<void> toggle(String packageName) =>
      isPinned(packageName) ? unpin(packageName) : pin(packageName);

  /// Replaces the whole pinned list at once — what the grid editor's "Apply"
  /// commits after staging reorder/resize/recolour/delete changes locally.
  Future<void> replaceAll(List<PinnedTile> tiles) {
    _pinned
      ..clear()
      ..addAll(tiles);
    notifyListeners();
    return _persist();
  }

  Future<void> _persist() =>
      _store.write(storeKey, [for (final PinnedTile p in _pinned) p.toJson()]);
}

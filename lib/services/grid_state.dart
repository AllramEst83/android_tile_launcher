import 'package:android_tile_launcher/model/pinned_tile.dart';
import 'package:android_tile_launcher/model/tile.dart';
import 'package:android_tile_launcher/services/local_store.dart';
import 'package:android_tile_launcher/services/local_store_exception.dart';
import 'package:flutter/foundation.dart';

/// Which tiles are on the home mosaic, each one's size and colour, and the
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

  bool isPinned(String id) => _pinned.any((PinnedTile p) => p.id == id);

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

  /// Pins the app [packageName] with its default size and colour, and saves.
  /// Already in effect for this run even if the returned future throws
  /// `LocalStoreException` — only the save failed, not the pin.
  Future<void> pin(String packageName) => _add(
    () => PinnedTile.app(packageName: packageName, index: _pinned.length),
  );

  /// Pins a system tile (anything but [TileKind.app] — there is at most one
  /// of each) and saves. Same failure contract as [pin].
  Future<void> pinSystemTile(TileKind kind) =>
      _add(() => PinnedTile.system(kind: kind, index: _pinned.length));

  /// Pins the contact with lookup [key], remembering [name] to draw it with,
  /// and saves. One tile per person; pinning one already pinned changes
  /// nothing. Same failure contract as [pin].
  Future<void> pinContact({required String key, required String name}) => _add(
    () => PinnedTile.contact(key: key, name: name, index: _pinned.length),
  );

  Future<void> _add(PinnedTile Function() tile) {
    final PinnedTile next = tile();
    if (isPinned(next.id)) return Future<void>.value();
    _pinned.add(next);
    notifyListeners();
    return _persist();
  }

  /// Unpins the tile with this [id] (a package name, or a system kind's
  /// name) and saves. Same failure contract as [pin].
  Future<void> unpin(String id) {
    final int before = _pinned.length;
    _pinned.removeWhere((PinnedTile p) => p.id == id);
    if (_pinned.length == before) return Future<void>.value();
    notifyListeners();
    return _persist();
  }

  /// Pins or unpins the app [packageName]. Used by the drawer's quick
  /// actions; system tiles are only ever added from the add-tile sheet.
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

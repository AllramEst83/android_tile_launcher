import 'package:android_tile_launcher/model/list_reorder.dart';
import 'package:android_tile_launcher/model/todo_item.dart';
import 'package:android_tile_launcher/services/local_store.dart';
import 'package:android_tile_launcher/services/local_store_exception.dart';
import 'package:flutter/foundation.dart';

/// The to-do list, kept on this phone in a [LocalStore]. Changes apply at once
/// and are then saved; a failed save is dropped (the list still holds for this
/// run) rather than thrown, since a to-do is not worth an error dialog.
class TodoList extends ChangeNotifier {
  // Not `this._store`: see `GridState`.
  TodoList({
    required LocalStore store,
    // ignore: prefer_initializing_formals
  }) : _store = store;

  static const String storeKey = 'todos';

  final LocalStore _store;
  final List<TodoItem> _items = <TodoItem>[];
  int _nextId = 1;

  List<TodoItem> get items => List<TodoItem>.unmodifiable(_items);

  /// Reads the saved list. Anything unreadable or malformed is skipped.
  Future<void> load() async {
    final Object? saved;
    try {
      saved = await _store.read(storeKey);
    } on LocalStoreException {
      return;
    }
    if (saved is! List) return;
    _items
      ..clear()
      ..addAll(<TodoItem>[
        for (final Object? entry in saved) ?TodoItem.fromJson(entry),
      ]);
    _nextId =
        _items.fold<int>(0, (int m, TodoItem i) => i.id > m ? i.id : m) + 1;
    notifyListeners();
  }

  Future<void> add(String title) async {
    final String clean = title.trim();
    if (clean.isEmpty) return;
    _items.add(TodoItem(id: _nextId++, title: clean));
    await _changed();
  }

  Future<void> setDone(int id, bool done) =>
      _replace(id, (TodoItem i) => i.copyWith(done: done));

  Future<void> rename(int id, String title) async {
    final String clean = title.trim();
    if (clean.isEmpty) return;
    await _replace(id, (TodoItem i) => i.copyWith(title: clean));
  }

  Future<void> remove(Iterable<int> ids) async {
    final Set<int> gone = ids.toSet();
    final int before = _items.length;
    _items.removeWhere((TodoItem i) => gone.contains(i.id));
    if (_items.length != before) await _changed();
  }

  /// Moves the item at [from] to just before the one at [target], or just
  /// after it if [after].
  Future<void> move(int from, int target, {required bool after}) async {
    final List<TodoItem> next = moveBeside<TodoItem>(
      _items,
      from: from,
      target: target,
      after: after,
    );
    if (identical(next, _items)) return;
    _items
      ..clear()
      ..addAll(next);
    await _changed();
  }

  Future<void> _replace(int id, TodoItem Function(TodoItem) change) async {
    final int i = _items.indexWhere((TodoItem t) => t.id == id);
    if (i < 0) return;
    _items[i] = change(_items[i]);
    await _changed();
  }

  Future<void> _changed() async {
    notifyListeners();
    try {
      await _store.write(storeKey, <Object>[
        for (final TodoItem i in _items) i.toJson(),
      ]);
    } on LocalStoreException {
      // Held for this run; see above.
    }
  }
}

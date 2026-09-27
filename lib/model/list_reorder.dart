/// Moves the item at [from] to sit where the item at [to] was, shifting
/// everything between them — the same adjustment `ReorderableListView` uses:
/// moving forward, the target keeps its own final slot and the moved item
/// lands just before it; moving backward, the moved item takes the target's
/// old slot outright. Pure; out-of-range or equal indices return [items]
/// unchanged. Used by the grid editor's drag-to-reorder.
List<T> moveItem<T>(List<T> items, {required int from, required int to}) {
  if (from == to ||
      from < 0 ||
      from >= items.length ||
      to < 0 ||
      to >= items.length) {
    return items;
  }
  final List<T> next = List<T>.of(items);
  final T item = next.removeAt(from);
  final int insertAt = from < to ? to - 1 : to;
  next.insert(insertAt, item);
  return next;
}

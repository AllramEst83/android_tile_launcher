/// Moves the item at [from] into the slot of the item at [to]: the moved item
/// ends up at index [to] and everything between the two shifts one place
/// towards the slot it left. Dropping a tile on its neighbour therefore always
/// swaps their places, in either direction (the `ReorderableListView` rule,
/// where moving forward lands the item *before* the target, makes that a
/// no-op and cannot put a tile last by dropping on the one that is). Pure;
/// out-of-range or equal indices return [items] unchanged. Used by the grid
/// editor's drag-to-reorder.
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
  next.insert(to, item);
  return next;
}

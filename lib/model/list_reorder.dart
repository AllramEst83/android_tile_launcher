/// Moves the item at [from] to sit right beside the item at [target]: just
/// before it, or just after it if [after]. The order of everything else is
/// kept. Dropping a tile on the far side of its neighbour and on the near side
/// of the one beyond are the same move, which is what the grid editor's
/// insertion line shows. Pure; out-of-range indices, or [from] equal to
/// [target], return [items] unchanged.
List<T> moveBeside<T>(
  List<T> items, {
  required int from,
  required int target,
  required bool after,
}) {
  if (from == target ||
      from < 0 ||
      from >= items.length ||
      target < 0 ||
      target >= items.length) {
    return items;
  }
  final List<T> next = List<T>.of(items);
  final T item = next.removeAt(from);
  // Taking the item out shifts everything after it one place back.
  final int targetNow = target > from ? target - 1 : target;
  next.insert(after ? targetNow + 1 : targetNow, item);
  return next;
}

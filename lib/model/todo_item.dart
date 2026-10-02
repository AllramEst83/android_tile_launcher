/// One entry on the to-do list: just a title and whether it is done.
class TodoItem {
  const TodoItem({required this.id, required this.title, this.done = false});

  /// Stable for the item's lifetime, so a drag or an edit can name it.
  final int id;
  final String title;
  final bool done;

  TodoItem copyWith({String? title, bool? done}) =>
      TodoItem(id: id, title: title ?? this.title, done: done ?? this.done);

  Map<String, Object> toJson() => <String, Object>{
    'id': id,
    'title': title,
    'done': done,
  };

  /// The item [json] describes, or null if it is not the shape [toJson] makes.
  static TodoItem? fromJson(Object? json) {
    if (json is! Map) return null;
    final Object? id = json['id'];
    final Object? title = json['title'];
    final Object? done = json['done'];
    if (id is! int || title is! String || title.trim().isEmpty) return null;
    return TodoItem(id: id, title: title, done: done == true);
  }
}

/// How many of [items] a tile with room for [lines] lines lists, and how many
/// are left over for its `+N` label. When some do not fit, the last line is
/// given up to the `+N`, so the label never needs a line of its own.
({int shown, int hidden}) todoFit(int items, int lines) {
  final int room = lines < 1 ? 1 : lines;
  if (items <= room) return (shown: items, hidden: 0);
  final int shown = room - 1;
  return (shown: shown, hidden: items - shown);
}

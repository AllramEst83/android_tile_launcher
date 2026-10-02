import 'package:android_tile_launcher/services/todo_list.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/in_memory_local_store.dart';

void main() {
  late InMemoryLocalStore store;
  late TodoList todos;

  setUp(() {
    store = InMemoryLocalStore();
    todos = TodoList(store: store);
  });

  List<String> titles() => todos.items.map((i) => i.title).toList();

  test('add trims, ignores blanks and persists', () async {
    await todos.add('  Milk ');
    await todos.add('   ');
    expect(titles(), <String>['Milk']);

    final TodoList again = TodoList(store: store);
    await again.load();
    expect(again.items.map((i) => i.title), <String>['Milk']);
  });

  test('check, uncheck and rename', () async {
    await todos.add('Milk');
    final int id = todos.items.single.id;
    await todos.setDone(id, true);
    expect(todos.items.single.done, isTrue);
    await todos.setDone(id, false);
    expect(todos.items.single.done, isFalse);
    await todos.rename(id, 'Oat milk');
    await todos.rename(id, '');
    expect(titles(), <String>['Oat milk']);
  });

  test('remove deletes many at once', () async {
    for (final String t in <String>['a', 'b', 'c']) {
      await todos.add(t);
    }
    await todos.remove(<int>[todos.items[0].id, todos.items[2].id]);
    expect(titles(), <String>['b']);
  });

  test('move reorders', () async {
    for (final String t in <String>['a', 'b', 'c']) {
      await todos.add(t);
    }
    await todos.move(0, 2, after: true);
    expect(titles(), <String>['b', 'c', 'a']);
    await todos.move(2, 0, after: false);
    expect(titles(), <String>['a', 'b', 'c']);
  });

  test('ids stay unique after a reload', () async {
    await todos.add('a');
    await todos.add('b');
    final TodoList again = TodoList(store: store);
    await again.load();
    await again.add('c');
    expect(again.items.map((i) => i.id).toSet().length, 3);
  });

  test('notifies listeners', () async {
    int calls = 0;
    todos.addListener(() => calls++);
    await todos.add('a');
    expect(calls, 1);
  });
}

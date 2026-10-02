import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/services/todo_list.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:android_tile_launcher/ui/todo_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/in_memory_local_store.dart';

Future<TodoList> _open(
  WidgetTester tester, [
  List<String> seed = const <String>[],
]) async {
  final TodoList todos = TodoList(store: InMemoryLocalStore());
  for (final String t in seed) {
    await todos.add(t);
  }
  await tester.pumpWidget(
    MaterialApp(
      theme: tileLauncherTheme(),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showTodoSheet(context, todos: todos),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return todos;
}

void main() {
  testWidgets('adds a to-do', (WidgetTester tester) async {
    final TodoList todos = await _open(tester);
    await tester.enterText(find.byKey(todoFieldKey), 'Milk');
    await tester.tap(find.byKey(todoAddKey));
    await tester.pumpAndSettle();

    expect(todos.items.single.title, 'Milk');
    expect(find.text('MILK'), findsOneWidget);
  });

  testWidgets('checks and unchecks', (WidgetTester tester) async {
    final TodoList todos = await _open(tester, <String>['Milk']);
    final int id = todos.items.single.id;

    await tester.tap(find.byKey(todoCheckKey(id)));
    await tester.pumpAndSettle();
    expect(todos.items.single.done, isTrue);

    await tester.tap(find.byKey(todoCheckKey(id)));
    await tester.pumpAndSettle();
    expect(todos.items.single.done, isFalse);
  });

  testWidgets('edits a title', (WidgetTester tester) async {
    final TodoList todos = await _open(tester, <String>['Milk']);
    await tester.tap(find.byKey(todoTitleKey(todos.items.single.id)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(todoEditFieldKey), 'Oat milk');
    await tester.tap(find.byKey(todoSaveKey));
    await tester.pumpAndSettle();

    expect(todos.items.single.title, 'Oat milk');
  });

  testWidgets('bulk delete asks first', (WidgetTester tester) async {
    final TodoList todos = await _open(tester, <String>['a', 'b', 'c']);
    final List<int> ids = todos.items.map((i) => i.id).toList();
    await tester.tap(find.byKey(todoSelectKey));
    await tester.pump();
    await tester.tap(find.byKey(todoCheckKey(ids[0])));
    await tester.tap(find.byKey(todoTitleKey(ids[2])));
    await tester.pump();

    await tester.tap(find.byKey(todoDeleteKey));
    await tester.pump();
    expect(find.text(Messages.todoDeleteAsk(2)), findsOneWidget);
    expect(todos.items.length, 3);

    await tester.tap(find.byKey(todoYesKey));
    await tester.pumpAndSettle();
    expect(todos.items.map((i) => i.title), <String>['b']);
  });

  testWidgets('MOVE lets a to-do be dragged', (WidgetTester tester) async {
    final TodoList todos = await _open(tester, <String>['a', 'b', 'c']);
    final List<int> ids = todos.items.map((i) => i.id).toList();
    await tester.tap(find.byKey(todoMoveKey));
    await tester.pumpAndSettle();

    final Offset from = tester.getCenter(find.byKey(todoHandleKey(ids[0])));
    final TestGesture g = await tester.startGesture(from);
    await tester.pump(const Duration(milliseconds: 100));
    await g.moveBy(const Offset(0, 140));
    await tester.pump();
    await g.up();
    await tester.pumpAndSettle();

    expect(todos.items.first.title, isNot('a'));
    expect(todos.items.map((i) => i.title).toSet(), <String>{'a', 'b', 'c'});
  });
}

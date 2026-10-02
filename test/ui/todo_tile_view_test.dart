import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/todo_item.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:android_tile_launcher/ui/todo_tile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester,
  List<TodoItem> items, {
  double width = 200,
  double height = 120,
  VoidCallback? onTap,
}) => tester.pumpWidget(
  MaterialApp(
    theme: tileLauncherTheme(),
    home: Scaffold(
      body: SizedBox(
        width: width,
        height: height,
        child: TodoTileContentView(
          items: items,
          ink: Colors.white,
          onTap: onTap,
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('shows to-dos, a done one struck through and checked', (
    WidgetTester tester,
  ) async {
    await _pump(tester, const <TodoItem>[
      TodoItem(id: 1, title: 'Milk'),
      TodoItem(id: 2, title: 'Bread', done: true),
    ]);

    expect(find.text('MILK'), findsOneWidget);
    expect(find.text('[ ] '), findsOneWidget);
    expect(find.text('[X] '), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('BREAD')).style?.decoration,
      TextDecoration.lineThrough,
    );
    expect(tester.widget<Text>(find.text('MILK')).style?.decoration, isNull);
  });

  testWidgets('counts what does not fit as +N', (WidgetTester tester) async {
    await _pump(tester, <TodoItem>[
      for (int i = 1; i <= 9; i++) TodoItem(id: i, title: 'Item $i'),
    ]);

    expect(find.byKey(todoMoreKey), findsOneWidget);
    expect(find.text('ITEM 9'), findsNothing);
    final int shown = find.textContaining('ITEM').evaluate().length;
    expect(find.text(Messages.todoMore(9 - shown)), findsOneWidget);
  });

  testWidgets('empty list says so', (WidgetTester tester) async {
    await _pump(tester, const <TodoItem>[]);
    expect(find.text(Messages.todoEmpty), findsOneWidget);
  });

  testWidgets('a tap calls onTap', (WidgetTester tester) async {
    int taps = 0;
    await _pump(tester, const <TodoItem>[], onTap: () => taps++);
    await tester.tap(find.byType(TodoTileContentView));
    expect(taps, 1);
  });
}

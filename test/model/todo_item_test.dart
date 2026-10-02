import 'package:android_tile_launcher/model/todo_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('round-trips through JSON', () {
    const TodoItem item = TodoItem(id: 3, title: 'Milk', done: true);
    final TodoItem? back = TodoItem.fromJson(item.toJson());
    expect(back?.id, 3);
    expect(back?.title, 'Milk');
    expect(back?.done, isTrue);
  });

  test('malformed JSON is skipped', () {
    expect(TodoItem.fromJson('x'), isNull);
    expect(TodoItem.fromJson(<String, Object>{'id': 1, 'title': ' '}), isNull);
    expect(TodoItem.fromJson(<String, Object>{'title': 'a'}), isNull);
  });

  group('todoFit', () {
    test('everything fits', () {
      expect(todoFit(3, 3), (shown: 3, hidden: 0));
    });
    test('gives the last line to +N', () {
      expect(todoFit(8, 3), (shown: 2, hidden: 6));
    });
    test('one line shows only the count', () {
      expect(todoFit(4, 1), (shown: 0, hidden: 4));
    });
  });
}

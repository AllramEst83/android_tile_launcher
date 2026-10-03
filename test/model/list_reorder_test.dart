import 'package:android_tile_launcher/model/list_reorder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('moveBeside', () {
    List<String> move(int from, int target, {required bool after}) =>
        moveBeside(
          ['A', 'B', 'C', 'D'],
          from: from,
          target: target,
          after: after,
        );

    test('before a later item', () {
      expect(move(0, 2, after: false), ['B', 'A', 'C', 'D']);
    });

    test('after a later item', () {
      expect(move(0, 2, after: true), ['B', 'C', 'A', 'D']);
    });

    test('before an earlier item', () {
      expect(move(3, 1, after: false), ['A', 'D', 'B', 'C']);
    });

    test('after an earlier item', () {
      expect(move(3, 1, after: true), ['A', 'B', 'D', 'C']);
    });

    test('after the last item puts it last', () {
      expect(move(0, 3, after: true), ['B', 'C', 'D', 'A']);
    });

    test('before the first item puts it first', () {
      expect(move(3, 0, after: false), ['D', 'A', 'B', 'C']);
    });

    test('the far side of a neighbour is the near side of the next', () {
      expect(move(0, 1, after: true), move(0, 2, after: false));
      expect(move(3, 2, after: false), move(3, 1, after: true));
    });

    test(
      'beside its own neighbour on the side it already is changes nothing',
      () {
        expect(move(1, 2, after: false), ['A', 'B', 'C', 'D']);
        expect(move(1, 0, after: true), ['A', 'B', 'C', 'D']);
      },
    );

    test('onto itself changes nothing', () {
      final items = ['A', 'B', 'C'];

      expect(
        identical(moveBeside(items, from: 1, target: 1, after: true), items),
        isTrue,
      );
    });

    test('an out-of-range index changes nothing', () {
      final items = ['A', 'B', 'C'];

      expect(moveBeside(items, from: -1, target: 1, after: false), items);
      expect(moveBeside(items, from: 0, target: 5, after: true), items);
    });

    test('does not mutate the input list', () {
      final items = ['A', 'B', 'C'];

      moveBeside(items, from: 0, target: 2, after: true);

      expect(items, ['A', 'B', 'C']);
    });
  });

  group('moveBlockBeside', () {
    List<String> block(Set<String> moving, int target, {required bool after}) =>
        moveBlockBeside(
          ['A', 'B', 'C', 'D', 'E'],
          moving: moving.contains,
          target: target,
          after: after,
        );

    test('the block lands together before the target, in its own order', () {
      expect(block({'A', 'C'}, 3, after: false), ['B', 'A', 'C', 'D', 'E']);
    });

    test('the block lands together after the target', () {
      expect(block({'A', 'C'}, 4, after: true), ['B', 'D', 'E', 'A', 'C']);
    });

    test('a block from the back moves to the front', () {
      expect(block({'D', 'E'}, 0, after: false), ['D', 'E', 'A', 'B', 'C']);
    });

    test('a target inside the block, or out of range, changes nothing', () {
      final items = ['A', 'B', 'C'];
      expect(
        moveBlockBeside(items, moving: {'A'}.contains, target: 0, after: true),
        same(items),
      );
      expect(
        moveBlockBeside(items, moving: {'A'}.contains, target: 9, after: true),
        same(items),
      );
      expect(
        moveBlockBeside(items, moving: (_) => false, target: 1, after: true),
        same(items),
      );
    });
  });
}

import 'package:android_tile_launcher/model/list_reorder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('moveItem', () {
    test('moving forward: the item takes the target\'s slot', () {
      final result = moveItem(['A', 'B', 'C', 'D'], from: 0, to: 2);

      expect(result, ['B', 'C', 'A', 'D']);
    });

    test('moving backward: the item takes the target\'s slot', () {
      final result = moveItem(['A', 'B', 'C', 'D'], from: 3, to: 1);

      expect(result, ['A', 'D', 'B', 'C']);
    });

    test('dropping on the next neighbour swaps the two', () {
      expect(moveItem(['A', 'B', 'C'], from: 0, to: 1), ['B', 'A', 'C']);
      expect(moveItem(['A', 'B', 'C'], from: 1, to: 0), ['B', 'A', 'C']);
    });

    test('dropping on the last item puts the moved one last', () {
      expect(moveItem(['A', 'B', 'C'], from: 0, to: 2), ['B', 'C', 'A']);
    });

    test('moving to the same index changes nothing', () {
      final items = ['A', 'B', 'C'];

      expect(identical(moveItem(items, from: 1, to: 1), items), isTrue);
    });

    test('an out-of-range index changes nothing', () {
      final items = ['A', 'B', 'C'];

      expect(moveItem(items, from: -1, to: 1), items);
      expect(moveItem(items, from: 0, to: 5), items);
    });

    test('does not mutate the input list', () {
      final items = ['A', 'B', 'C'];

      moveItem(items, from: 0, to: 2);

      expect(items, ['A', 'B', 'C']);
    });
  });
}

import 'package:android_tile_launcher/model/alpha_grouping.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('groupByInitial', () {
    test('buckets by first letter, A to Z', () {
      final groups = groupByInitial(['Banana', 'Apple', 'Avocado'], (s) => s);

      expect(groups.map((g) => g.initial), ['A', 'B']);
      expect(groups[0].items, ['Apple', 'Avocado']);
      expect(groups[1].items, ['Banana']);
    });

    test('keeps original order for items with the same key', () {
      final groups = groupByInitial(['Apple', 'apple', 'APPLE'], (s) => s);

      expect(groups, hasLength(1));
      expect(groups.single.items, ['Apple', 'apple', 'APPLE']);
    });

    test('files Å, Ä, Ö after Z, not with A and O', () {
      final groups = groupByInitial(['Örn', 'Zebra', 'Äpple', 'Åsa'], (s) => s);

      expect(groups.map((g) => g.initial), ['Z', 'Å', 'Ä', 'Ö']);
    });

    test('folds an accented letter under its plain one', () {
      final groups = groupByInitial(['Émile', 'Erik'], (s) => s);

      expect(groups.map((g) => g.initial), ['E']);
      expect(groups.single.items, ['Émile', 'Erik']); // alphabetical, not equal
    });

    test('files a digit, a symbol, or an empty label under #, last', () {
      final groups = groupByInitial([
        '1Password',
        '!Bang',
        'Zebra',
        '',
      ], (s) => s);

      expect(groups.map((g) => g.initial), ['Z', '#']);
      // Within '#', order follows the sort key (raw string comparison), not
      // the original list order -- there's no letter to group by ties on.
      expect(groups.last.items, ['', '!Bang', '1Password']);
    });

    test('an empty list groups to nothing', () {
      expect(groupByInitial(<String>[], (s) => s), isEmpty);
    });
  });
}

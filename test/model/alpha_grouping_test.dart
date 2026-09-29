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

  group('jumpFraction', () {
    test('an empty list is 0, whatever the index', () {
      expect(jumpFraction(<InitialGroup<String>>[], 0), 0);
      expect(jumpFraction(<InitialGroup<String>>[], 5), 0);
    });

    test('the first group is always 0', () {
      final groups = groupByInitial(['Apple', 'Banana'], (s) => s);

      expect(jumpFraction(groups, 0), 0);
    });

    test(
      'equal-sized groups split evenly, like the old proportional guess',
      () {
        final groups = groupByInitial(['A1', 'B1', 'C1'], (s) => s);

        expect(jumpFraction(groups, 1), closeTo(1 / 3, 1e-9));
        expect(jumpFraction(groups, 2), closeTo(2 / 3, 1e-9));
      },
    );

    test('a heavy group pulls the next letter further down', () {
      // A: fifty names, B: one. Pure letter-count (the old bug) would put B
      // at 1/2; the weight of A's fifty rows must push it much further.
      final groups = groupByInitial([
        for (var i = 0; i < 50; i++) 'A$i',
        'B1',
      ], (s) => s);

      final double fraction = jumpFraction(groups, 1);

      expect(fraction, greaterThan(0.9));
    });

    test('a lone heavy group at the end barely moves the ones before it', () {
      final groups = groupByInitial([
        'A1',
        'B1',
        for (var i = 0; i < 50; i++) 'C$i',
      ], (s) => s);

      // A and B are two light groups out of 54 weighted rows (plus headers);
      // B should sit just a little past the very top, not at 1/3.
      expect(jumpFraction(groups, 1), lessThan(0.1));
    });

    test('an out-of-range index is clamped, not thrown', () {
      final groups = groupByInitial(['Apple', 'Banana'], (s) => s);

      expect(jumpFraction(groups, 99), jumpFraction(groups, 1));
      expect(jumpFraction(groups, -1), jumpFraction(groups, 0));
    });
  });
}

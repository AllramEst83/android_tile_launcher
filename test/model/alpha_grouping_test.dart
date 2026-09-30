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

    test(
      'a different header weight changes the fraction for unequal groups',
      () {
        // A ten-item group followed by a one-item one: how much of the whole
        // A's header is worth relative to its own ten rows changes where B
        // actually starts, once a header is not simply "as tall as a row".
        final groups = groupByInitial([
          for (var i = 0; i < 10; i++) 'A$i',
          'B1',
        ], (s) => s);

        final double evenWeighted = jumpFraction(groups, 1);
        final double headerHeavy = jumpFraction(
          groups,
          1,
          headerWeight: 3,
          itemWeight: 1,
        );

        expect(headerHeavy, isNot(closeTo(evenWeighted, 1e-9)));
      },
    );
  });

  group('groupIndexForFraction', () {
    test('an empty list is always group 0', () {
      expect(groupIndexForFraction(<InitialGroup<String>>[], 0), 0);
      expect(groupIndexForFraction(<InitialGroup<String>>[], 0.5), 0);
    });

    test('0 is always the first group', () {
      final groups = groupByInitial(['Apple', 'Banana'], (s) => s);

      expect(groupIndexForFraction(groups, 0), 0);
    });

    test('is the exact inverse of jumpFraction, for equal-sized groups', () {
      final groups = groupByInitial(['A1', 'B1', 'C1'], (s) => s);

      for (var i = 0; i < groups.length; i++) {
        expect(groupIndexForFraction(groups, jumpFraction(groups, i)), i);
      }
    });

    test('a heavy group is found throughout its own weighted range', () {
      // A: fifty names (weight 51 of 55), B: one (weight 2), C: one (weight 2).
      final groups = groupByInitial([
        for (var i = 0; i < 50; i++) 'A$i',
        'B1',
        'C1',
      ], (s) => s);

      expect(groupIndexForFraction(groups, 0.0), 0);
      expect(groupIndexForFraction(groups, 0.5), 0);
      // A's own weighted range ends at 51/55 ≈ 0.927.
      expect(groupIndexForFraction(groups, 0.9), 0);
      expect(groupIndexForFraction(groups, 0.95), 1);
      expect(groupIndexForFraction(groups, 0.99), 2);
    });

    test('a fraction past the end is clamped to the last group', () {
      final groups = groupByInitial(['Apple', 'Banana'], (s) => s);

      expect(groupIndexForFraction(groups, 1.0), 1);
      expect(groupIndexForFraction(groups, 5.0), 1);
      expect(groupIndexForFraction(groups, -1.0), 0);
    });

    test('stays the exact inverse of jumpFraction with a heavier header', () {
      final groups = groupByInitial(['A1', 'B1', 'C1'], (s) => s);

      for (var i = 0; i < groups.length; i++) {
        final double fraction = jumpFraction(
          groups,
          i,
          headerWeight: 3.5,
          itemWeight: 1,
        );
        expect(
          groupIndexForFraction(
            groups,
            fraction,
            headerWeight: 3.5,
            itemWeight: 1,
          ),
          i,
        );
      }
    });
  });
}

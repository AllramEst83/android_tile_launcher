import 'package:android_tile_launcher/model/mail.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MailOlderThan.before', () {
    final DateTime now = DateTime(2026, 9, 30);

    test('days', () {
      expect(
        const MailOlderThan(3, MailAgeUnit.days).before(now),
        DateTime(2026, 9, 27),
      );
    });

    test('weeks', () {
      expect(
        const MailOlderThan(2, MailAgeUnit.weeks).before(now),
        DateTime(2026, 9, 16),
      );
    });

    test('months', () {
      expect(
        const MailOlderThan(2, MailAgeUnit.months).before(now),
        DateTime(2026, 7, 30),
      );
    });

    test('years', () {
      expect(
        const MailOlderThan(1, MailAgeUnit.years).before(now),
        DateTime(2025, 9, 30),
      );
    });
  });

  group('MailFilter', () {
    test('empty with nothing set', () {
      expect(const MailFilter().isEmpty, isTrue);
    });

    test('not empty once any field is set', () {
      expect(const MailFilter(text: 'x').isEmpty, isFalse);
      expect(const MailFilter(from: 'x').isEmpty, isFalse);
      expect(const MailFilter(to: 'x').isEmpty, isFalse);
      expect(
        const MailFilter(olderThan: MailOlderThan(1, MailAgeUnit.days)).isEmpty,
        isFalse,
      );
    });

    test('withoutX drops only that one field', () {
      const MailFilter filter = MailFilter(
        text: 'hi',
        from: 'a@b.com',
        to: 'c@d.com',
        olderThan: MailOlderThan(1, MailAgeUnit.weeks),
      );

      expect(
        filter.withoutText(),
        const MailFilter(
          from: 'a@b.com',
          to: 'c@d.com',
          olderThan: MailOlderThan(1, MailAgeUnit.weeks),
        ),
      );
      expect(
        filter.withoutFrom(),
        const MailFilter(
          text: 'hi',
          to: 'c@d.com',
          olderThan: MailOlderThan(1, MailAgeUnit.weeks),
        ),
      );
      expect(
        filter.withoutTo(),
        const MailFilter(
          text: 'hi',
          from: 'a@b.com',
          olderThan: MailOlderThan(1, MailAgeUnit.weeks),
        ),
      );
      expect(
        filter.withoutOlderThan(),
        const MailFilter(text: 'hi', from: 'a@b.com', to: 'c@d.com'),
      );
    });

    test('equality is by value', () {
      expect(const MailFilter(text: 'a'), const MailFilter(text: 'a'));
      expect(
        const MailFilter(text: 'a') == const MailFilter(text: 'b'),
        isFalse,
      );
    });
  });
}

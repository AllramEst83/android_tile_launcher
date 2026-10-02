import 'package:android_tile_launcher/model/mail.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  _starTests();
  group('MailAgeFilter.cutoff', () {
    final DateTime now = DateTime(2026, 9, 30);

    test('days', () {
      expect(
        const MailAgeFilter(
          3,
          MailAgeUnit.days,
          MailAgeDirection.older,
        ).cutoff(now),
        DateTime(2026, 9, 27),
      );
    });

    test('weeks', () {
      expect(
        const MailAgeFilter(
          2,
          MailAgeUnit.weeks,
          MailAgeDirection.older,
        ).cutoff(now),
        DateTime(2026, 9, 16),
      );
    });

    test('months', () {
      expect(
        const MailAgeFilter(
          2,
          MailAgeUnit.months,
          MailAgeDirection.older,
        ).cutoff(now),
        DateTime(2026, 7, 30),
      );
    });

    test('years', () {
      expect(
        const MailAgeFilter(
          1,
          MailAgeUnit.years,
          MailAgeDirection.older,
        ).cutoff(now),
        DateTime(2025, 9, 30),
      );
    });

    test('the cutoff math does not depend on direction', () {
      expect(
        const MailAgeFilter(
          3,
          MailAgeUnit.days,
          MailAgeDirection.newer,
        ).cutoff(now),
        DateTime(2026, 9, 27),
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
        const MailFilter(
          age: MailAgeFilter(1, MailAgeUnit.days, MailAgeDirection.older),
        ).isEmpty,
        isFalse,
      );
    });

    test('withoutX drops only that one field', () {
      const MailFilter filter = MailFilter(
        text: 'hi',
        from: 'a@b.com',
        to: 'c@d.com',
        age: MailAgeFilter(1, MailAgeUnit.weeks, MailAgeDirection.older),
      );

      expect(
        filter.withoutText(),
        const MailFilter(
          from: 'a@b.com',
          to: 'c@d.com',
          age: MailAgeFilter(1, MailAgeUnit.weeks, MailAgeDirection.older),
        ),
      );
      expect(
        filter.withoutFrom(),
        const MailFilter(
          text: 'hi',
          to: 'c@d.com',
          age: MailAgeFilter(1, MailAgeUnit.weeks, MailAgeDirection.older),
        ),
      );
      expect(
        filter.withoutTo(),
        const MailFilter(
          text: 'hi',
          from: 'a@b.com',
          age: MailAgeFilter(1, MailAgeUnit.weeks, MailAgeDirection.older),
        ),
      );
      expect(
        filter.withoutAge(),
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

void _starTests() {
  group('starredFirst', () {
    test('puts starred first and keeps each group in order', () {
      const List<MailMessage> list = <MailMessage>[
        MailMessage(uid: 9, from: 'a', subject: ''),
        MailMessage(uid: 8, from: 'b', subject: '', starred: true),
        MailMessage(uid: 7, from: 'c', subject: ''),
        MailMessage(uid: 2, from: 'd', subject: '', starred: true),
      ];
      expect(starredFirst(list).map((MailMessage m) => m.uid), <int>[
        8,
        2,
        9,
        7,
      ]);
    });

    test('copyWith keeps and changes starred', () {
      const MailMessage m = MailMessage(uid: 1, from: 'a', subject: '');
      expect(m.copyWith(starred: true).starred, isTrue);
      expect(m.copyWith(starred: true).copyWith(unread: true).starred, isTrue);
    });
  });
}

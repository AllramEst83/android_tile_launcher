import 'package:android_tile_launcher/model/mail_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('guessImapHost', () {
    test('the big providers have their own', () {
      expect(guessImapHost('kay@gmail.com'), 'imap.gmail.com');
      expect(guessImapHost('kay@googlemail.com'), 'imap.gmail.com');
      expect(guessImapHost('kay@outlook.com'), 'outlook.office365.com');
      expect(guessImapHost('kay@hotmail.com'), 'outlook.office365.com');
      expect(guessImapHost('kay@icloud.com'), 'imap.mail.me.com');
      expect(guessImapHost('kay@yahoo.com'), 'imap.mail.yahoo.com');
    });

    test('anyone else gets imap. plus their domain', () {
      expect(guessImapHost('kay@example.se'), 'imap.example.se');
    });

    test('ignores case and stray spaces after the @', () {
      expect(guessImapHost('Kay@GMail.COM'), 'imap.gmail.com');
      expect(guessImapHost('kay@ gmail.com'), 'imap.gmail.com');
    });

    test('guesses nothing until there is a domain', () {
      expect(guessImapHost(''), '');
      expect(guessImapHost('kay'), '');
      expect(guessImapHost('kay@'), '');
      expect(guessImapHost('kay@gmail'), '');
    });
  });

  group('formatMailDate', () {
    final DateTime now = DateTime(2026, 9, 28, 15, 30);

    test('today is the time', () {
      expect(formatMailDate(DateTime(2026, 9, 28, 9, 5), now), '09:05');
    });

    test('another day is the day and month', () {
      expect(formatMailDate(DateTime(2026, 9, 25, 9, 5), now), '25 SEP');
      expect(formatMailDate(DateTime(2025, 12, 1), now), '1 DEC');
    });

    test('an unknown date is nothing', () {
      expect(formatMailDate(null, now), '');
    });
  });
}

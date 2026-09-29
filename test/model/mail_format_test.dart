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

  group('guessSmtpHost', () {
    test('the big providers have their own', () {
      expect(guessSmtpHost('kay@gmail.com'), 'smtp.gmail.com');
      expect(guessSmtpHost('kay@googlemail.com'), 'smtp.gmail.com');
      expect(guessSmtpHost('kay@outlook.com'), 'smtp.office365.com');
      expect(guessSmtpHost('kay@hotmail.com'), 'smtp.office365.com');
      expect(guessSmtpHost('kay@icloud.com'), 'smtp.mail.me.com');
      expect(guessSmtpHost('kay@yahoo.com'), 'smtp.mail.yahoo.com');
    });

    test('anyone else gets smtp. plus their domain', () {
      expect(guessSmtpHost('kay@example.se'), 'smtp.example.se');
    });

    test('ignores case and stray spaces after the @', () {
      expect(guessSmtpHost('Kay@GMail.COM'), 'smtp.gmail.com');
      expect(guessSmtpHost('kay@ gmail.com'), 'smtp.gmail.com');
    });

    test('guesses nothing until there is a domain', () {
      expect(guessSmtpHost(''), '');
      expect(guessSmtpHost('kay'), '');
      expect(guessSmtpHost('kay@'), '');
      expect(guessSmtpHost('kay@gmail'), '');
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
  group('tidyMailText', () {
    test('makes the line ends the same and trims each line', () {
      expect(tidyMailText('one  \r\ntwo\rthree\t \n').text, 'one\ntwo\nthree');
    });

    test('squeezes blank lines to one', () {
      expect(tidyMailText('a\n\n\n\n\nb').text, 'a\n\nb');
    });

    test('drops control and invisible characters, keeps tabs and newlines', () {
      expect(
        tidyMailText('a\u0000b\u200Bc\uFEFFd\u0007e\tf\ng').text,
        'abcde\tf\ng',
      );
    });

    test('a no-break space is a space', () {
      expect(tidyMailText('a\u00A0b').text, 'a b');
    });

    test('short text is not cut', () {
      final result = tidyMailText('short', limit: 100);

      expect(result.text, 'short');
      expect(result.truncated, isFalse);
    });

    test('long text is cut at a word, and says so', () {
      final result = tidyMailText('alpha beta gamma delta epsilon', limit: 18);

      expect(result.truncated, isTrue);
      expect(result.text, 'alpha beta gamma');
    });

    test('a word longer than the limit is cut where it is', () {
      final result = tidyMailText('x' * 50, limit: 10);

      expect(result.text, 'x' * 10);
      expect(result.truncated, isTrue);
    });

    test('empty stays empty', () {
      expect(tidyMailText('  \n\n ').text, '');
    });
  });

  group('plainTextFromHtml', () {
    test('drops the tags and keeps the words', () {
      expect(plainTextFromHtml('<b>Hello</b> <i>there</i>'), 'Hello there');
    });

    test('paragraphs, breaks and rows become lines', () {
      expect(
        plainTextFromHtml('<p>One</p><p>Two<br/>Three</p><div>Four</div>'),
        'One\nTwo\nThree\nFour\n',
      );
    });

    test('list items become dashes', () {
      expect(
        plainTextFromHtml('<ul><li>a</li><li>b</li></ul>').trim(),
        '- a\n- b',
      );
    });

    test('drops the head, styles, scripts and comments', () {
      expect(
        plainTextFromHtml(
          '<head><title>T</title></head><style>x{}</style><!-- c -->'
          '<script>alert(1)</script>Body',
        ),
        'Body',
      );
    });

    test('reads named and numeric entities', () {
      expect(
        plainTextFromHtml('a&nbsp;b &amp; c &lt;d&gt; &#8211; &#x41; &aring;'),
        'a b & c <d> \u2013 A \u00E5',
      );
    });

    test('leaves an entity it does not know, and a bad number, alone', () {
      expect(plainTextFromHtml('&bogus; &#99999999;'), '&bogus; &#99999999;');
    });

    test('runs of spaces are one', () {
      expect(plainTextFromHtml('a   \t  b'), 'a b');
    });

    test('table cells are kept apart', () {
      expect(plainTextFromHtml('<tr><td>a</td><td>b</td></tr>').trim(), 'a b');
    });
  });
}

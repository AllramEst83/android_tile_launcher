import 'package:android_tile_launcher/model/mail.dart';
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

  group('looksLikeHtml', () {
    test('a full document is markup', () {
      expect(looksLikeHtml('<html><body><p>Hi</p></body></html>'), isTrue);
    });

    test('a bare tag is markup', () {
      expect(looksLikeHtml('Hello<br>there'), isTrue);
      expect(looksLikeHtml('<div>Hi</div>'), isTrue);
    });

    test('ordinary prose is not markup', () {
      expect(looksLikeHtml('Hi there, see you < 5pm?'), isFalse);
    });

    test('only checks the first part of a very long text', () {
      final String prose = 'a' * 3000;
      expect(looksLikeHtml('$prose<div>late tag</div>'), isFalse);
    });
  });

  group('stripImagesFromHtml', () {
    test('drops an img tag, self-closed or not', () {
      expect(
        stripImagesFromHtml('<p>Hi</p><img src="x.png"><p>Bye</p>'),
        '<p>Hi</p><p>Bye</p>',
      );
      expect(stripImagesFromHtml('<img src="x.png" />'), '');
    });

    test('leaves everything else alone', () {
      expect(
        stripImagesFromHtml('<p>No pictures here</p>'),
        '<p>No pictures here</p>',
      );
    });
  });

  group('resolveCidImages', () {
    test('replaces a cid reference with its data URI', () {
      expect(
        resolveCidImages('<p>Hi</p><img src="cid:abc123">', <String, String>{
          'abc123': 'data:image/png;base64,xyz',
        }),
        '<p>Hi</p><img src="data:image/png;base64,xyz">',
      );
    });

    test('matches the cid case-insensitively', () {
      expect(
        resolveCidImages('<img src="cid:ABC123">', <String, String>{
          'abc123': 'data:image/png;base64,xyz',
        }),
        '<img src="data:image/png;base64,xyz">',
      );
    });

    test('a cid not in the map is left as-is, and so is a remote image', () {
      const String html =
          '<img src="cid:unknown"><img src="http://example.com/x.png">';
      expect(resolveCidImages(html, <String, String>{}), html);
    });

    test('an empty map changes nothing', () {
      const String html = '<img src="cid:abc123">';
      expect(resolveCidImages(html, <String, String>{}), html);
    });
  });

  group('formatAttachmentSize', () {
    test('bytes under a kilobyte are shown as-is', () {
      expect(formatAttachmentSize(0), '0 B');
      expect(formatAttachmentSize(512), '512 B');
    });

    test('kilobytes to one decimal place', () {
      expect(formatAttachmentSize(2048), '2.0 KB');
      expect(formatAttachmentSize(1536), '1.5 KB');
    });

    test('megabytes to one decimal place', () {
      expect(formatAttachmentSize(1024 * 1024 * 3), '3.0 MB');
    });
  });

  group('parseAddressList', () {
    test('splits on comma, semicolon or newline, trimmed', () {
      expect(parseAddressList('a@b.com, c@d.com;  e@f.com\ng@h.com'), <String>[
        'a@b.com',
        'c@d.com',
        'e@f.com',
        'g@h.com',
      ]);
    });

    test('drops the empty pieces a trailing separator leaves', () {
      expect(parseAddressList('a@b.com, ,c@d.com,'), <String>[
        'a@b.com',
        'c@d.com',
      ]);
    });

    test('one address with nothing to split on is itself', () {
      expect(parseAddressList('a@b.com'), <String>['a@b.com']);
    });

    test('blank text is no addresses', () {
      expect(parseAddressList('   '), <String>[]);
    });

    test('a stray zero-width space is never an address of its own', () {
      expect(parseAddressList('​'), <String>[]);
      expect(parseAddressList('a@b.com,​'), <String>['a@b.com']);
    });
  });

  group('looksLikeCompleteEmail', () {
    test('something, an @, something, a dot, something is complete', () {
      expect(looksLikeCompleteEmail('a@b.com'), isTrue);
      expect(looksLikeCompleteEmail('  a@b.com  '), isTrue);
    });

    test('missing a dot in the domain is not complete', () {
      expect(looksLikeCompleteEmail('a@b'), isFalse);
    });

    test('no @ at all is not complete', () {
      expect(looksLikeCompleteEmail('abc'), isFalse);
    });

    test('a trailing dot with nothing after it is not complete', () {
      expect(looksLikeCompleteEmail('a@b.'), isFalse);
    });

    test('a space inside is not one address', () {
      expect(looksLikeCompleteEmail('a b@c.com'), isFalse);
    });

    test('empty text is not complete', () {
      expect(looksLikeCompleteEmail(''), isFalse);
    });
  });

  group('replyAllCcAddresses', () {
    MailBody body({
      String fromAddress = 'anna@example.com',
      List<MailParticipant> to = const <MailParticipant>[],
      List<MailParticipant> cc = const <MailParticipant>[],
    }) => MailBody(
      uid: 1,
      from: 'Anna',
      fromAddress: fromAddress,
      to: to,
      cc: cc,
      subject: 'Hi',
      text: 'Hi',
    );

    test('every other To and Cc address, sender and self left out', () {
      final result = replyAllCcAddresses(
        body(
          to: const <MailParticipant>[
            MailParticipant(address: 'kay@gmail.com'),
            MailParticipant(address: 'cesar@example.com'),
          ],
          cc: const <MailParticipant>[
            MailParticipant(address: 'bo@example.com'),
          ],
        ),
        'kay@gmail.com',
      );

      expect(result, <String>['cesar@example.com', 'bo@example.com']);
    });

    test('case-insensitive, and duplicates dropped', () {
      final result = replyAllCcAddresses(
        body(
          to: const <MailParticipant>[
            MailParticipant(address: 'Kay@Gmail.com'),
            MailParticipant(address: 'bo@example.com'),
          ],
          cc: const <MailParticipant>[
            MailParticipant(address: 'BO@example.com'),
          ],
        ),
        'kay@gmail.com',
      );

      expect(result, <String>['bo@example.com']);
    });

    test('nobody left over is an empty list', () {
      final result = replyAllCcAddresses(
        body(
          to: const <MailParticipant>[
            MailParticipant(address: 'kay@gmail.com'),
          ],
        ),
        'kay@gmail.com',
      );

      expect(result, isEmpty);
    });

    test('no self address known still drops the sender', () {
      final result = replyAllCcAddresses(
        body(
          to: const <MailParticipant>[
            MailParticipant(address: 'anna@example.com'),
            MailParticipant(address: 'bo@example.com'),
          ],
        ),
        null,
      );

      expect(result, <String>['bo@example.com']);
    });
  });
}

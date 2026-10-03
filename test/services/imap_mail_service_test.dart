import 'dart:async';

import 'package:android_tile_launcher/model/mail.dart';
import 'package:android_tile_launcher/model/mail_format.dart';
import 'package:android_tile_launcher/services/imap_mail_service.dart';
import 'package:android_tile_launcher/services/local_store_exception.dart';
import 'package:android_tile_launcher/services/mail_account.dart';
import 'package:enough_mail/enough_mail.dart' show Mailbox, MailboxFlag;
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_imap_server.dart';
import '../fakes/fake_smtp_server.dart';
import '../fakes/in_memory_secret_store.dart';

const _password = 'abcd efgh ijkl mnop';

void main() {
  late FakeImapServer server;
  late InMemorySecretStore secrets;
  late ImapMailService mail;

  Future<void> boot(List<FakeImapMessage> messages) async {
    server = FakeImapServer(
      user: 'kay@example.com',
      password: _password,
      messages: messages,
    );
    await server.start();
    secrets = InMemorySecretStore();
    mail = ImapMailService(
      accounts: MailAccountStore(secrets),
      secure: false,
      timeout: const Duration(seconds: 5),
    );
  }

  Future<String?> setUp({String password = _password}) => mail.setUp(
    email: 'kay@example.com',
    host: '127.0.0.1:${server.port}',
    password: password,
  );

  group('splitHostPort', () {
    test('defaults to the IMAPS port', () {
      expect(splitHostPort('imap.gmail.com'), (
        host: 'imap.gmail.com',
        port: 993,
      ));
    });

    test('takes a port after a colon', () {
      expect(splitHostPort('mail.example.com:143'), (
        host: 'mail.example.com',
        port: 143,
      ));
    });

    test('leaves a colon that is not followed by a number in the host', () {
      expect(splitHostPort('odd:host').host, 'odd:host');
    });
  });

  group('set up', () {
    tearDown(() => server.stop());

    test('with the right password saves the account', () async {
      await boot(const []);
      expect(await mail.account(), isNull);

      expect(await setUp(), isNull);

      final info = await mail.account();
      expect(info?.email, 'kay@example.com');
      expect(info?.host, '127.0.0.1');
      expect(secrets.data, hasLength(1));
    });

    test('with the wrong password saves nothing and says so', () async {
      await boot(const []);

      final problem = await setUp(password: 'nope');

      expect(problem, contains('refused the login'));
      expect(problem, isNot(contains('nope')));
      expect(secrets.data, isEmpty);
      expect(await mail.account(), isNull);
    });

    test('with nobody listening says it cannot reach the host', () async {
      await boot(const []);
      final port = server.port;
      await server.stop();

      final problem = await mail.setUp(
        email: 'kay@example.com',
        host: '127.0.0.1:$port',
        password: _password,
      );

      expect(problem, contains("can't reach"));
      expect(secrets.data, isEmpty);
    });

    test('reports a store that fails, after a good login', () async {
      await boot(const []);
      secrets.failure = const LocalStoreException('keystore is locked');

      expect(await setUp(), 'keystore is locked');
    });

    test('forget removes the account', () async {
      await boot(const []);
      await setUp();

      expect(await mail.forget(), isTrue);

      expect(await mail.account(), isNull);
      expect(secrets.data, isEmpty);
      expect(await mail.forget(), isFalse); // and forgetting nothing is fine
    });
  });

  group('latest', () {
    tearDown(() => server.stop());

    const inbox = [
      FakeImapMessage(
        uid: 101,
        subject: '"Lunch tomorrow?"',
        date: 'Fri, 25 Sep 2026 10:00:00 +0000',
        address: 'anna@example.com',
        name: 'Anna Berg',
        seen: true,
      ),
      FakeImapMessage(
        uid: 102,
        subject: '"=?UTF-8?Q?Sm=C3=B6rg=C3=A5s?="',
        date: 'Sat, 26 Sep 2026 08:30:00 +0200',
        address: 'noreply@shop.example',
      ),
      FakeImapMessage(
        uid: 103,
        subject: 'NIL',
        date: 'Sat, 26 Sep 2026 09:15:00 +0000',
        address: 'bo@example.com',
        name: 'Bo',
      ),
    ];

    test('without an account is not set up', () async {
      await boot(inbox);

      expect(await mail.latest(), isA<MailNotSetUp>());
      expect(server.connections, 0);
    });

    test('lists the newest first with sender, subject and state', () async {
      await boot(inbox);
      await setUp();

      final result = await mail.latest();

      final found = result as MailMessages;
      expect(found.total, 3);
      expect(found.unread, 2);
      expect([for (final m in found.messages) m.uid], [103, 102, 101]);
      final lunch = found.messages.last;
      expect(lunch.from, 'Anna Berg');
      expect(lunch.subject, 'Lunch tomorrow?');
      expect(lunch.unread, isFalse);
      expect(lunch.date, DateTime.utc(2026, 9, 25, 10).toLocal());
    });

    test(
      'uses the address when there is no name, and decodes subjects',
      () async {
        await boot(inbox);
        await setUp();

        final found = await mail.latest() as MailMessages;

        final shop = found.messages[1];
        expect(shop.from, 'noreply@shop.example');
        expect(shop.subject, 'Smörgås');
        expect(shop.unread, isTrue);
        expect(shop.date, DateTime.utc(2026, 9, 26, 6, 30).toLocal());
        expect(found.messages.first.subject, isEmpty);
      },
    );

    test('asks for exactly the newest few, and only their envelopes', () async {
      await boot(inbox);
      await setUp();

      final found = await mail.latest(count: 2) as MailMessages;

      expect([for (final m in found.messages) m.uid], [103, 102]);

      final fetches = server.received.where((c) => c.startsWith('FETCH'));
      expect(fetches, ['FETCH 2:3 (UID FLAGS ENVELOPE)']);
    });

    test('only reads: nothing that changes the mailbox is ever sent', () async {
      await boot(inbox);
      await setUp();

      await mail.latest();

      const changing = ['STORE', 'EXPUNGE', 'DELETE', 'COPY', 'MOVE', 'APPEND'];
      for (final command in server.received) {
        expect(changing, isNot(contains(command.split(' ').first)));
      }
    });

    test('an empty inbox is an empty list', () async {
      await boot(const []);
      await setUp();

      final found = await mail.latest() as MailMessages;

      expect(found.messages, isEmpty);
      expect(found.total, 0);
      expect(found.unread, 0);
    });

    test('a server error becomes a message without the password', () async {
      await boot(inbox);
      await setUp();
      server.failSelect = true;

      final result = await mail.latest();

      final failed = result as MailUnavailable;
      expect(failed.reason, startsWith('127.0.0.1'));
      expect(failed.reason, isNot(contains('efgh')));
    });

    test('hangs up after each call', () async {
      await boot(inbox);
      await setUp();

      await mail.latest();

      expect(server.received, contains('LOGOUT'));
    });

    test('an unreadable saved account says how to recover', () async {
      await boot(inbox);
      secrets.data['mailAccount'] = 'not json';

      final result = await mail.latest();

      expect(result, isA<MailUnavailable>());
      expect((result as MailUnavailable).reason, contains('set it up again'));
    });
  });

  group('search', () {
    tearDown(() => server.stop());

    const inbox = [
      FakeImapMessage(
        uid: 101,
        subject: '"Lunch tomorrow?"',
        date: 'Fri, 25 Sep 2026 10:00:00 +0000',
        address: 'anna@example.com',
        name: 'Anna Berg',
        seen: true,
      ),
      FakeImapMessage(
        uid: 102,
        subject: '"Invoice"',
        date: 'Sat, 26 Sep 2026 08:30:00 +0200',
        address: 'noreply@shop.example',
      ),
    ];

    test('without an account is not set up, and never connects', () async {
      await boot(inbox);

      expect(
        await mail.search(const MailFilter(text: 'x')),
        isA<MailNotSetUp>(),
      );
      expect(server.connections, 0);
    });

    test('an empty filter searches ALL', () async {
      await boot(inbox);
      await setUp();
      server.searchResults = {101, 102};

      await mail.search(const MailFilter());

      expect(server.received, contains(contains('UID SEARCH ALL')));
    });

    test('free text searches subject or body', () async {
      await boot(inbox);
      await setUp();
      server.searchResults = {};

      await mail.search(const MailFilter(text: 'lunch'));

      expect(
        server.received,
        contains(contains('OR SUBJECT "lunch" BODY "lunch"')),
      );
    });

    test('from and to narrow it further', () async {
      await boot(inbox);
      await setUp();
      server.searchResults = {};

      await mail.search(
        const MailFilter(from: 'anna@example.com', to: 'kay@example.com'),
      );

      final sent = server.received.firstWhere((c) => c.contains('UID SEARCH'));
      expect(sent, contains('FROM "anna@example.com"'));
      expect(sent, contains('TO "kay@example.com"'));
    });

    test('older than sends a BEFORE cutoff from the injected clock', () async {
      await boot(inbox);
      final searchMail = ImapMailService(
        accounts: MailAccountStore(secrets),
        secure: false,
        timeout: const Duration(seconds: 5),
        clock: () => DateTime(2026, 9, 30),
      );
      await searchMail.setUp(
        email: 'kay@example.com',
        host: '127.0.0.1:${server.port}',
        password: _password,
      );
      server.searchResults = {};

      await searchMail.search(
        const MailFilter(
          age: MailAgeFilter(3, MailAgeUnit.days, MailAgeDirection.older),
        ),
      );

      expect(server.received, contains(contains('BEFORE "27-Sep-2026"')));
    });

    test('newer than sends a SINCE cutoff from the injected clock', () async {
      await boot(inbox);
      final searchMail = ImapMailService(
        accounts: MailAccountStore(secrets),
        secure: false,
        timeout: const Duration(seconds: 5),
        clock: () => DateTime(2026, 9, 30),
      );
      await searchMail.setUp(
        email: 'kay@example.com',
        host: '127.0.0.1:${server.port}',
        password: _password,
      );
      server.searchResults = {};

      await searchMail.search(
        const MailFilter(
          age: MailAgeFilter(3, MailAgeUnit.days, MailAgeDirection.newer),
        ),
      );

      expect(server.received, contains(contains('SINCE "27-Sep-2026"')));
    });

    test('every set field combines into one query', () async {
      await boot(inbox);
      await setUp();
      server.searchResults = {};

      await mail.search(
        const MailFilter(text: 'x', from: 'a@b.com', to: 'c@d.com'),
      );

      final sent = server.received.firstWhere((c) => c.contains('UID SEARCH'));
      expect(sent, contains('OR SUBJECT "x" BODY "x"'));
      expect(sent, contains('FROM "a@b.com"'));
      expect(sent, contains('TO "c@d.com"'));
    });

    test('the matching messages, newest first', () async {
      await boot(inbox);
      await setUp();
      server.searchResults = {101, 102};

      final result = await mail.search(const MailFilter(text: 'x'));

      final found = result as MailMessages;
      expect([for (final m in found.messages) m.uid], [102, 101]);
      expect(found.total, 2);
      expect(found.unread, 1);
    });

    test('no matches is an empty list, not an error', () async {
      await boot(inbox);
      await setUp();
      server.searchResults = {};

      final result = await mail.search(const MailFilter(text: 'nope'));

      final found = result as MailMessages;
      expect(found.messages, isEmpty);
      expect(found.total, 0);
    });

    test('caps at count, but total is every match', () async {
      await boot(inbox);
      await setUp();
      server.searchResults = {101, 102};

      final result = await mail.search(const MailFilter(text: 'x'), count: 1);

      final found = result as MailMessages;
      expect(found.messages, hasLength(1));
      expect(found.total, 2);
    });
  });

  group('moveToTrash', () {
    tearDown(() => server.stop());

    const inbox = [
      FakeImapMessage(
        uid: 101,
        subject: '"One"',
        date: 'Fri, 25 Sep 2026 10:00:00 +0000',
        address: 'one@example.com',
      ),
      FakeImapMessage(
        uid: 102,
        subject: '"Two"',
        date: 'Sat, 26 Sep 2026 08:30:00 +0200',
        address: 'two@example.com',
      ),
      FakeImapMessage(
        uid: 103,
        subject: '"Three"',
        date: 'Sat, 26 Sep 2026 09:15:00 +0000',
        address: 'three@example.com',
      ),
    ];

    List<int> uids(List<FakeImapMessage> list) => [for (final m in list) m.uid];

    /// The commands that change something, whatever they are called.
    Iterable<String> changes() => server.received.where(
      (c) =>
          RegExp(r'^(UID )?(MOVE|COPY|STORE|EXPUNGE|DELETE|APPEND)')
              .hasMatch(c),
    );

    test('moves the message and only that one, to the Trash folder', () async {
      await boot(inbox);
      await setUp();

      final result = await mail.moveToTrash(102);

      expect(result, isA<MailMoved>());
      expect((result as MailMoved).folder, 'Trash');
      expect(uids(server.inbox), [101, 103]);
      expect(uids(server.trash), [102]);
      expect(changes(), ['UID MOVE 102 [Gmail]/Trash']);
    });

    test('quotes a Trash folder whose name has a space in it', () async {
      await boot(inbox);
      server.trashName = 'Deleted Messages';
      await setUp();

      final result = await mail.moveToTrash(102);

      expect((result as MailMoved).folder, 'Deleted Messages');
      expect(changes(), ['UID MOVE 102 "Deleted Messages"']);
    });

    test('never sends a delete, whatever happens', () async {
      await boot(inbox);
      await setUp();

      await mail.moveToTrash(102);
      await mail.moveToTrash(999);

      for (final command in server.received) {
        expect(command, isNot(startsWith('DELETE')));
        expect(command, isNot(contains('EXPUNGE')));
        expect(command, isNot(contains('STORE')));
      }
    });

    test('without MOVE it copies, flags and expunges that uid alone', () async {
      await boot(inbox);
      server.capabilities = 'IMAP4rev1 UIDPLUS';
      await setUp();

      final result = await mail.moveToTrash(102);

      expect(result, isA<MailMoved>());
      expect(uids(server.inbox), [101, 103]);
      expect(uids(server.trash), [102]);
      expect(changes(), [
        'UID COPY 102 [Gmail]/Trash',
        r'UID STORE 102 +FLAGS.SILENT (\Deleted)',
        'UID EXPUNGE 102',
      ]);
      expect(
        server.received.where((c) => c == 'EXPUNGE'),
        isEmpty,
        reason: 'a plain EXPUNGE would remove everything flagged deleted',
      );
    });

    test('without MOVE or UIDPLUS it refuses and changes nothing', () async {
      await boot(inbox);
      server.capabilities = 'IMAP4rev1';
      await setUp();

      final result = await mail.moveToTrash(102);

      expect(result, isA<MailMoveFailed>());
      expect(
        (result as MailMoveFailed).reason,
        contains('nothing was changed'),
      );
      expect(uids(server.inbox), [101, 102, 103]);
      expect(changes(), isEmpty);
    });

    test('with no Trash folder it refuses rather than delete', () async {
      await boot(inbox);
      server.hasTrash = false;
      await setUp();

      final result = await mail.moveToTrash(102);

      expect((result as MailMoveFailed).reason, contains('no Trash folder'));
      expect(uids(server.inbox), [101, 102, 103]);
      expect(changes(), isEmpty);
    });

    test('a message that is no longer there is gone, not an error', () async {
      await boot(inbox);
      await setUp();

      final result = await mail.moveToTrash(555);

      expect(result, isA<MailGone>());
      expect(uids(server.inbox), [101, 102, 103]);
      expect(changes(), isEmpty);
    });

    test('a list read under another UIDVALIDITY is not acted on', () async {
      await boot(inbox);
      await setUp();
      final read = await mail.latest() as MailMessages;
      expect(read.validity, 1);
      server.uidValidity = 2; // the server renumbered everything

      final result = await mail.moveToTrash(102, validity: read.validity);

      expect(result, isA<MailMoveFailed>());
      expect((result as MailMoveFailed).reason, contains('renumbered'));
      expect(uids(server.inbox), [101, 102, 103]);
      expect(changes(), isEmpty);
    });

    test('the same validity goes ahead', () async {
      await boot(inbox);
      await setUp();
      final read = await mail.latest() as MailMessages;

      final result = await mail.moveToTrash(102, validity: read.validity);

      expect(result, isA<MailMoved>());
    });

    test('with no account it says so and connects to nothing', () async {
      await boot(inbox);

      expect(await mail.moveToTrash(102), isA<MailMoveNotSetUp>());
      expect(server.connections, 0);
    });

    test('a server error is a message without the password', () async {
      await boot(inbox);
      await setUp();
      server.failSelect = true;

      final result = await mail.moveToTrash(102);

      final failed = result as MailMoveFailed;
      expect(failed.reason, startsWith('127.0.0.1'));
      expect(failed.reason, isNot(contains('efgh')));
      expect(uids(server.inbox), [101, 102, 103]);
    });

    test('hangs up afterwards', () async {
      await boot(inbox);
      await setUp();

      await mail.moveToTrash(102);

      expect(server.received, contains('LOGOUT'));
    });
  });
  group('read', () {
    tearDown(() => server.stop());

    const lunch = FakeImapMessage(
      uid: 101,
      subject: '"Lunch tomorrow?"',
      date: 'Fri, 25 Sep 2026 10:00:00 +0000',
      address: 'anna@example.com',
      name: 'Anna Berg',
      text: 'Hi!\r\n\r\nShall we meet at noon?\r\n\r\n/Anna',
    );

    test('without an account is not set up, and never connects', () async {
      await boot(const [lunch]);

      expect(await mail.read(101), isA<MailReadNotSetUp>());
      expect(server.connections, 0);
    });

    test('shows the message in full', () async {
      await boot(const [lunch]);
      await setUp();

      final opened = await mail.read(101) as MailOpened;

      expect(opened.body.uid, 101);
      expect(opened.body.from, 'Anna Berg');
      expect(opened.body.subject, 'Lunch tomorrow?');
      expect(opened.body.date, DateTime.utc(2026, 9, 25, 10).toLocal());
      expect(opened.body.text, 'Hi!\n\nShall we meet at noon?\n\n/Anna');
      expect(opened.body.truncated, isFalse);
      expect(opened.body.attachments, isEmpty);
    });

    test('reads To and Cc from the message headers', () async {
      await boot([
        const FakeImapMessage(
          uid: 20,
          subject: '"Team lunch"',
          date: 'Fri, 25 Sep 2026 10:00:00 +0000',
          address: 'anna@example.com',
          name: 'Anna Berg',
          raw:
              'From: Anna Berg <anna@example.com>\r\n'
              'To: Kay <kay@example.com>, cesar@example.com\r\n'
              'Cc: Bo Berg <bo@example.com>\r\n'
              'Subject: Team lunch\r\n'
              'Date: Fri, 25 Sep 2026 10:00:00 +0000\r\n'
              'Message-ID: <20@example.com>\r\n'
              'MIME-Version: 1.0\r\n'
              'Content-Type: text/plain; charset=utf-8\r\n\r\n'
              'Hi!\r\n',
        ),
      ]);
      await setUp();

      final opened = await mail.read(20) as MailOpened;

      expect(opened.body.to.map((p) => (p.name, p.address)).toList(), [
        ('Kay', 'kay@example.com'),
        ('', 'cesar@example.com'),
      ]);
      expect(opened.body.cc.map((p) => (p.name, p.address)).toList(), [
        ('Bo Berg', 'bo@example.com'),
      ]);
    });

    test('marks it read, on the server, and says so', () async {
      await boot(const [lunch]);
      await setUp();
      expect(server.seen, isEmpty);

      final opened = await mail.read(101) as MailOpened;

      expect(server.seen, {101});
      expect(opened.body.markedRead, isTrue);
      expect(server.received.where((c) => c.contains('STORE')), hasLength(1));
    });

    test('fetches without setting the flag itself (PEEK)', () async {
      await boot(const [lunch]);
      await setUp();

      await mail.read(101);

      expect(server.received.any((c) => c.contains('BODY.PEEK[]')), isTrue);
      expect(server.received.any((c) => c.contains(' BODY[]')), isFalse);
    });

    test('a message that is already read stays read', () async {
      await boot(const [
        FakeImapMessage(
          uid: 5,
          subject: '"Hej"',
          date: 'Fri, 25 Sep 2026 10:00:00 +0000',
          address: 'a@example.com',
          seen: true,
          text: 'Hej',
        ),
      ]);
      await setUp();

      await mail.read(5);

      expect(server.seen, {5});
    });

    test('an HTML-only message is shown as its readable text', () async {
      await boot(const [
        FakeImapMessage(
          uid: 7,
          subject: '"News"',
          date: 'Fri, 25 Sep 2026 10:00:00 +0000',
          address: 'news@example.com',
          html:
              '<html><head><style>p{color:red}</style></head><body>'
              '<h1>Big &amp; small</h1><p>First<br>second</p>'
              '<ul><li>one</li><li>two</li></ul></body></html>',
        ),
      ]);
      await setUp();

      final opened = await mail.read(7) as MailOpened;

      expect(opened.body.text, contains('Big & small'));
      expect(opened.body.text, contains('First\nsecond'));
      expect(opened.body.text, contains('- one'));
      expect(opened.body.text, isNot(contains('<')));
      expect(opened.body.text, isNot(contains('color:red')));
    });

    test(
      'takes the plain text when both are there, but shows html too',
      () async {
        await boot(const [
          FakeImapMessage(
            uid: 8,
            subject: '"Both"',
            date: 'Fri, 25 Sep 2026 10:00:00 +0000',
            address: 'a@example.com',
            text: 'plain version',
            html: '<p>html version</p>',
          ),
        ]);
        await setUp();

        final opened = await mail.read(8) as MailOpened;

        expect(opened.body.text, 'plain version');
        expect(opened.body.html, '<p>html version</p>');
      },
    );

    test('an HTML-only message keeps its markup for a rich view', () async {
      await boot(const [
        FakeImapMessage(
          uid: 11,
          subject: '"News"',
          date: 'Fri, 25 Sep 2026 10:00:00 +0000',
          address: 'news@example.com',
          html: '<p>Rich <b>news</b></p><img src="http://example.com/x.png">',
        ),
      ]);
      await setUp();

      final opened = await mail.read(11) as MailOpened;

      expect(opened.body.html, '<p>Rich <b>news</b></p>');
    });

    test('an inline image is resolved to a data URI for SHOW IMAGES', () async {
      await boot([
        FakeImapMessage(
          uid: 15,
          subject: '"Photo"',
          date: 'Fri, 25 Sep 2026 10:00:00 +0000',
          address: 'a@example.com',
          raw:
              'From: a@example.com\r\nTo: kay@example.com\r\nSubject: Photo\r\n'
              'Date: Fri, 25 Sep 2026 10:00:00 +0000\r\nMIME-Version: 1.0\r\n'
              'Content-Type: multipart/related; boundary="m1"\r\n\r\n'
              '--m1\r\nContent-Type: text/html; charset=utf-8\r\n\r\n'
              '<p>Look</p><img src="cid:img1">\r\n'
              '--m1\r\nContent-Type: image/png\r\nContent-ID: <img1>\r\n'
              'Content-Disposition: inline\r\n'
              'Content-Transfer-Encoding: base64\r\n\r\niVBORw0KGgo=\r\n'
              '--m1--\r\n',
        ),
      ]);
      await setUp();

      final opened = await mail.read(15) as MailOpened;

      expect(opened.body.html, '<p>Look</p>');
      expect(opened.body.htmlWithImages, startsWith('<p>Look</p><img src='));
      expect(opened.body.htmlWithImages, contains('data:image/png;base64,'));
      expect(opened.body.htmlWithImages, isNot(contains('cid:')));
    });

    test('html with no img tag at all has nothing for SHOW IMAGES', () async {
      await boot([
        FakeImapMessage(
          uid: 16,
          subject: '"No pictures"',
          date: 'Fri, 25 Sep 2026 10:00:00 +0000',
          address: 'a@example.com',
          html: '<p>No pictures here</p>',
        ),
      ]);
      await setUp();

      final opened = await mail.read(16) as MailOpened;

      expect(opened.body.htmlWithImages, isNull);
    });

    test('a "plain" part that is really markup is shown rich too', () async {
      await boot(const [
        FakeImapMessage(
          uid: 12,
          subject: '"Sloppy"',
          date: 'Fri, 25 Sep 2026 10:00:00 +0000',
          address: 'a@example.com',
          text: '<div>Not actually plain</div>',
        ),
      ]);
      await setUp();

      final opened = await mail.read(12) as MailOpened;

      expect(opened.body.html, '<div>Not actually plain</div>');
      expect(opened.body.text, 'Not actually plain');
    });

    test('plain prose with no markup is shown as-is, with no html', () async {
      await boot(const [
        FakeImapMessage(
          uid: 13,
          subject: '"Plain"',
          date: 'Fri, 25 Sep 2026 10:00:00 +0000',
          address: 'a@example.com',
          text: 'Just a normal note.',
        ),
      ]);
      await setUp();

      final opened = await mail.read(13) as MailOpened;

      expect(opened.body.html, isNull);
      expect(opened.body.text, 'Just a normal note.');
    });

    test('reads attachments whole, name, size and bytes', () async {
      await boot([
        FakeImapMessage(
          uid: 9,
          subject: '"Photos"',
          date: 'Fri, 25 Sep 2026 10:00:00 +0000',
          address: 'a@example.com',
          raw:
              'From: a@example.com\r\nTo: kay@example.com\r\nSubject: Photos\r\n'
              'Date: Fri, 25 Sep 2026 10:00:00 +0000\r\nMIME-Version: 1.0\r\n'
              'Content-Type: multipart/mixed; boundary="m1"\r\n\r\n'
              '--m1\r\nContent-Type: text/plain; charset=utf-8\r\n\r\nSee attached.\r\n'
              '--m1\r\nContent-Type: image/png; name="a.png"\r\n'
              'Content-Disposition: attachment; filename="a.png"\r\n'
              'Content-Transfer-Encoding: base64\r\n\r\niVBORw0KGgo=\r\n'
              '--m1\r\nContent-Type: application/pdf; name="b.pdf"\r\n'
              'Content-Disposition: attachment; filename="b.pdf"\r\n'
              'Content-Transfer-Encoding: base64\r\n\r\nJVBERi0=\r\n'
              '--m1--\r\n',
        ),
      ]);
      await setUp();

      final opened = await mail.read(9) as MailOpened;

      expect(opened.body.text, 'See attached.');
      expect(opened.body.attachments, hasLength(2));
      final png = opened.body.attachments[0];
      expect(png.name, 'a.png');
      expect(png.mimeType, 'image/png');
      expect(png.bytes, isNotEmpty);
      expect(png.sizeBytes, png.bytes.length);
      final pdf = opened.body.attachments[1];
      expect(pdf.name, 'b.pdf');
      expect(pdf.mimeType, 'application/pdf');
      expect(pdf.bytes, isNotEmpty);
    });

    test('cuts a very long message', () async {
      await boot([
        FakeImapMessage(
          uid: 10,
          subject: '"Long"',
          date: 'Fri, 25 Sep 2026 10:00:00 +0000',
          address: 'a@example.com',
          text: List.filled(6000, 'word').join(' '),
        ),
      ]);
      await setUp();

      final opened = await mail.read(10) as MailOpened;

      expect(opened.body.truncated, isTrue);
      expect(opened.body.text.length, lessThanOrEqualTo(mailTextLimit));
      expect(opened.body.text.length, greaterThan(mailTextLimit - 300));
    });

    test('will not fetch a huge message, and changes nothing', () async {
      await boot(const [
        FakeImapMessage(
          uid: 11,
          subject: '"Huge"',
          date: 'Fri, 25 Sep 2026 10:00:00 +0000',
          address: 'a@example.com',
          text: 'x',
          size: 30 * 1024 * 1024,
        ),
      ]);
      await setUp();

      final result = await mail.read(11);

      expect(result, isA<MailReadFailed>());
      expect((result as MailReadFailed).reason, contains('30.0 MB'));
      expect(server.seen, isEmpty);
      expect(server.received.any((c) => c.contains('BODY.PEEK[]')), isFalse);
    });

    test('a message that is not there is gone', () async {
      await boot(const [lunch]);
      await setUp();

      expect(await mail.read(999), isA<MailReadGone>());
      expect(server.seen, isEmpty);
    });

    test('a renumbered inbox is refused, and nothing changes', () async {
      await boot(const [lunch]);
      await setUp();
      server.uidValidity = 2;

      final result = await mail.read(101, validity: 1);

      expect(result, isA<MailReadFailed>());
      expect((result as MailReadFailed).reason, contains('renumbered'));
      expect(server.seen, isEmpty);
    });

    test('still shows the message when only the marking fails', () async {
      await boot(const [lunch]);
      await setUp();
      server.failStoreSeen = true;

      final opened = await mail.read(101) as MailOpened;

      expect(opened.body.text, contains('noon'));
      expect(opened.body.markedRead, isFalse);
      expect(server.seen, isEmpty);
    });

    test('a server that is unreachable is a failure with a reason', () async {
      await boot(const [lunch]);
      await setUp();
      await server.stop();

      final result = await mail.read(101);

      expect(result, isA<MailReadFailed>());
      expect((result as MailReadFailed).reason, isNot(contains(_password)));
    });
  });

  group('mark', () {
    tearDown(() => server.stop());

    const unread = FakeImapMessage(
      uid: 21,
      subject: '"Hi"',
      date: 'Fri, 25 Sep 2026 10:00:00 +0000',
      address: 'a@example.com',
    );
    const read = FakeImapMessage(
      uid: 22,
      subject: '"Hello"',
      date: 'Fri, 25 Sep 2026 10:00:00 +0000',
      address: 'a@example.com',
      seen: true,
    );

    test('without an account is not set up', () async {
      await boot(const [unread]);

      expect(await mail.mark(21, read: true), isA<MailMarkNotSetUp>());
      expect(server.connections, 0);
    });

    test('marks a message read', () async {
      await boot(const [unread, read]);
      await setUp();

      final result = await mail.mark(21, read: true);

      expect((result as MailMarked).read, isTrue);
      expect(server.seen, {21, 22});
    });

    test('marks a message unread', () async {
      await boot(const [unread, read]);
      await setUp();

      final result = await mail.mark(22, read: false);

      expect((result as MailMarked).read, isFalse);
      expect(server.seen, isEmpty);
    });

    test('touches only that message', () async {
      await boot(const [unread, read]);
      await setUp();

      await mail.mark(21, read: true);
      await mail.mark(22, read: false);

      expect(server.seen, {21});
      expect(server.inbox, hasLength(2));
      expect(server.trash, isEmpty);
    });

    test('a message that is not there is gone', () async {
      await boot(const [unread]);
      await setUp();

      expect(await mail.mark(999, read: true), isA<MailMarkGone>());
    });

    test('a renumbered inbox is refused, and nothing changes', () async {
      await boot(const [unread]);
      await setUp();
      server.uidValidity = 2;

      final result = await mail.mark(21, read: true, validity: 1);

      expect(result, isA<MailMarkFailed>());
      expect(server.seen, isEmpty);
    });

    test(
      'a server error is a failure with a reason, nothing changed',
      () async {
        await boot(const [unread]);
        await setUp();
        server.failStoreSeen = true;

        final result = await mail.mark(21, read: true);

        expect(result, isA<MailMarkFailed>());
        expect(server.seen, isEmpty);
      },
    );

    test('the unread count follows', () async {
      await boot(const [unread, read]);
      await setUp();
      expect((await mail.latest() as MailMessages).unread, 1);

      await mail.mark(21, read: true);
      expect((await mail.latest() as MailMessages).unread, 0);

      await mail.mark(22, read: false);
      expect((await mail.latest() as MailMessages).unread, 1);
    });
  });

  group('paging and stars', () {
    tearDown(() => server.stop());

    final many = [
      for (var i = 1; i <= 7; i++)
        FakeImapMessage(
          uid: 100 + i,
          subject: '"Message $i"',
          date: 'Sat, 26 Sep 2026 08:30:00 +0000',
          address: 'a$i@example.com',
        ),
    ];

    test('latest pages through the inbox with offset', () async {
      await boot(many);
      await setUp();

      final first = await mail.latest(count: 3) as MailMessages;
      expect([for (final m in first.messages) m.uid], [107, 106, 105]);
      expect(first.nextOffset, 3);

      final second = await mail.latest(
        count: 3,
        offset: first.nextOffset!,
      ) as MailMessages;
      expect([for (final m in second.messages) m.uid], [104, 103, 102]);
      expect(second.nextOffset, 6);

      final last = await mail.latest(
        count: 3,
        offset: second.nextOffset!,
      ) as MailMessages;
      expect([for (final m in last.messages) m.uid], [101]);
      expect(last.nextOffset, isNull);
    });

    test('search fetches only the page asked for', () async {
      await boot(many);
      await setUp();
      server.searchResults = {for (var i = 101; i <= 107; i++) i};

      final page = await mail.search(
        const MailFilter(text: 'message'),
        count: 3,
        offset: 3,
      ) as MailMessages;

      expect([for (final m in page.messages) m.uid], [104, 103, 102]);
      expect(page.total, 7);
      expect(page.nextOffset, 6);
      final fetches = server.received.where((c) => c.startsWith('UID FETCH'));
      expect(fetches.single, contains('104'));
      expect(fetches.single, isNot(contains('107')));
    });

    test('withStarred lists starred messages apart from the page', () async {
      await boot(many);
      await setUp();
      server.flagged.addAll({101, 106});
      server.searchResults = {101, 106};

      final result =
          await mail.latest(count: 3, withStarred: true) as MailMessages;

      expect([for (final m in result.starred) m.uid], containsAll([101, 106]));
      expect(result.starred.every((m) => m.starred), isTrue);
      // The page holds no starred message (they are not listed twice), so it
      // may run short; the next page still starts where this one ended.
      expect([for (final m in result.messages) m.uid], [107, 105]);
      expect(result.nextOffset, 3);
    });

    test('without withStarred the page is plain inbox order', () async {
      await boot(many);
      await setUp();
      server.flagged.add(106);

      final result = await mail.latest(count: 3) as MailMessages;

      expect([for (final m in result.messages) m.uid], [107, 106, 105]);
      expect(result.messages[1].starred, isTrue);
      expect(result.starred, isEmpty);
    });

    test('star sets and clears the flag', () async {
      await boot(many);
      await setUp();

      expect(await mail.star(103, starred: true), isA<MailStarred>());
      expect(server.flagged, {103});
      expect(await mail.star(103, starred: false), isA<MailStarred>());
      expect(server.flagged, isEmpty);
      expect(await mail.star(999, starred: true), isA<MailStarGone>());
    });
  });

  group('folders', () {
    tearDown(() => server.stop());

    test('createFolder makes a top-level folder', () async {
      await boot(const []);
      await setUp();

      expect(await mail.createFolder('  Skola '), isA<MailFolderDone>());

      expect(server.extraFolders, ['Skola']);
      expect(server.received, contains('CREATE Skola'));
    });

    test('createFolder sends å, ä and ö as the server spells them', () async {
      await boot(const []);
      await setUp();

      await mail.createFolder('Beställningar');

      expect(server.extraFolders, ['Best&AOQ-llningar']);
    });

    test(
      'createFolder refuses a name that is empty, slashed or taken',
      () async {
        await boot(const []);
        await setUp();
        server.extraFolders.add('Skola');
        final connections = server.connections;

        expect(await mail.createFolder('  '), isA<MailFolderFailed>());
        expect(await mail.createFolder('a/b'), isA<MailFolderFailed>());
        // Not even asked of the server.
        expect(server.connections, connections);
        expect(await mail.createFolder('skola'), isA<MailFolderFailed>());
        expect(server.extraFolders, ['Skola']);
      },
    );

    test('renameFolder renames a folder the user made', () async {
      await boot(const []);
      await setUp();
      server.extraFolders.add('Skola');

      expect(
        await mail.renameFolder('Skola', 'Skola 2'),
        isA<MailFolderDone>(),
      );

      expect(server.extraFolders, ['Skola 2']);
    });

    test('a system folder is neither renamed nor deleted', () async {
      await boot(const []);
      await setUp();

      expect(
        await mail.renameFolder('[Gmail]/Trash', 'Bin'),
        isA<MailFolderFailed>(),
      );
      expect(await mail.deleteFolder('[Gmail]/Trash'), isA<MailFolderFailed>());
      expect(await mail.deleteFolder('INBOX'), isA<MailFolderFailed>());
      expect(server.received.where((c) => c.startsWith('RENAME')), isEmpty);
      expect(server.received.where((c) => c.startsWith('DELETE')), isEmpty);
    });

    test('deleteFolder removes a folder the user made', () async {
      await boot(const []);
      await setUp();
      server.extraFolders.addAll(['Skola', 'Sport']);

      expect(await mail.deleteFolder('Skola'), isA<MailFolderDone>());

      expect(server.extraFolders, ['Sport']);
    });

    test('without an account it is not set up', () async {
      await boot(const []);

      expect(await mail.createFolder('Skola'), isA<MailFolderNotSetUp>());
      expect(await mail.deleteFolder('Skola'), isA<MailFolderNotSetUp>());
    });

    test('folders lists them with readable labels', () async {
      await boot(const []);
      await setUp();
      server.extraFolders.add('Best&AOQ-llningar');

      final folders = await mail.folders();

      expect([
        for (final f in folders) f.label,
      ], containsAll(['INBOX', 'TRASH', 'BESTÄLLNINGAR']));
    });
  });

  group('Gmail inbox', () {
    tearDown(() => server.stop());

    final mails = [
      for (var i = 1; i <= 7; i++)
        FakeImapMessage(
          uid: 100 + i,
          subject: '"Message $i"',
          date: 'Sat, 26 Sep 2026 08:30:00 +0000',
          address: 'a$i@example.com',
        ),
    ];

    void gmail() {
      server
        ..capabilities = 'IMAP4rev1 MOVE UIDPLUS X-GM-EXT-1'
        ..hasAllMail = true
        // What Gmail calls the inbox is not all that the INBOX folder holds.
        ..searchResults = {101, 103, 105, 106, 107}
        ..starredResults = {106}
        ..unreadResults = {107};
    }

    test('lists what Gmail calls the inbox, from All Mail', () async {
      await boot(mails);
      gmail();
      await setUp();

      final result =
          await mail.latest(count: 3, withStarred: true) as MailMessages;

      expect(server.received, contains('UID SEARCH X-GM-RAW "in:inbox"'));
      // Newest first, the starred one listed apart, 102 and 104 not inbox.
      expect([for (final m in result.messages) m.uid], [-107, -105, -103]);
      expect([for (final m in result.starred) m.uid], [-106]);
      expect(
        result.messages.every((m) => m.folder == '[Gmail]/All Mail'),
        isTrue,
      );
      expect(result.total, 5);
      expect(result.unread, 1);
      expect(result.nextOffset, 3);
      expect(result.messages.first.serverUid, 107);
    });

    test('the next page carries on from where the last ended', () async {
      await boot(mails);
      gmail();
      await setUp();

      final rest = await mail.latest(
        count: 3,
        offset: 3,
        withStarred: true,
      ) as MailMessages;

      expect([for (final m in rest.messages) m.uid], [-101]);
      expect(rest.starred, isEmpty);
      expect(rest.nextOffset, isNull);
    });

    test('without the starred listing the page is plain inbox order', () async {
      await boot(mails);
      gmail();
      await setUp();

      final result = await mail.latest(count: 3) as MailMessages;

      expect([for (final m in result.messages) m.uid], [-107, -106, -105]);
      expect(result.starred, isEmpty);
    });

    test('a server that is not Gmail reads the INBOX folder', () async {
      await boot(mails);
      await setUp();

      final result = await mail.latest(count: 3) as MailMessages;

      expect([for (final m in result.messages) m.uid], [107, 106, 105]);
      expect(server.received.any((c) => c.contains('X-GM-RAW')), isFalse);
    });

    test(
      'when Gmail will not answer the INBOX folder is read instead',
      () async {
        await boot(mails);
        gmail();
        server.rejectGmailRaw = true;
        await setUp();

        final result = await mail.latest(count: 3) as MailMessages;

        expect([for (final m in result.messages) m.uid], [107, 106, 105]);
      },
    );
  });

  group('waiting for a change', () {
    tearDown(() => server.stop());

    Future<void> idling() async {
      for (var i = 0; i < 200 && !server.idling; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    }

    test('says changed when the server reports a new message', () async {
      await boot(const []);
      await setUp();

      final waiting = mail.waitForChange(timeout: const Duration(seconds: 5));
      await idling();
      expect(server.idling, isTrue);
      server.pushNewMessage();

      expect(await waiting, MailWait.changed);
      // And it ended the IDLE properly before hanging up.
      expect(server.received, contains('DONE'));
    });

    test('says quiet when nothing happens in the time given', () async {
      await boot(const []);
      await setUp();

      final result = await mail.waitForChange(
        timeout: const Duration(milliseconds: 300),
      );

      expect(result, MailWait.quiet);
      expect(server.received, contains('DONE'));
    });

    test('says quiet at once when cancelled', () async {
      await boot(const []);
      await setUp();
      final cancel = Completer<void>();

      final waiting = mail.waitForChange(
        timeout: const Duration(seconds: 30),
        cancel: cancel.future,
      );
      await idling();
      cancel.complete();

      expect(await waiting.timeout(const Duration(seconds: 3)), MailWait.quiet);
    });

    test('watches All Mail on Gmail', () async {
      await boot(const []);
      server
        ..capabilities = 'IMAP4rev1 MOVE UIDPLUS IDLE X-GM-EXT-1'
        ..hasAllMail = true;
      await setUp();

      final waiting = mail.waitForChange(timeout: const Duration(seconds: 5));
      await idling();
      server.pushNewMessage();
      await waiting;

      expect(server.received.any((c) => c.startsWith('SELECT')), isTrue);
    });

    test('a server without IDLE is a failure', () async {
      await boot(const []);
      server.capabilities = 'IMAP4rev1 MOVE UIDPLUS';
      await setUp();

      expect(await mail.waitForChange(), MailWait.failed);
    });

    test('without an account it fails without connecting', () async {
      await boot(const []);

      expect(await mail.waitForChange(), MailWait.failed);
      expect(server.connections, 0);
    });
  });

  group('mailFoldersFrom', () {
    Mailbox box(String path, List<MailboxFlag> flags) => Mailbox(
      encodedName: path.split('/').last,
      encodedPath: path,
      flags: flags,
      pathSeparator: '/',
    );

    test('keeps the encoded server name apart from the readable label', () {
      final folders = mailFoldersFrom([
        box('INBOX', [MailboxFlag.inbox]),
        box('Best&AOQ-llningar', []),
      ]);

      expect(folders.last.name, 'Best&AOQ-llningar');
      expect(folders.last.label, 'BESTÄLLNINGAR');
    });

    test('orders the well-known folders first and skips bare parents', () {
      final folders = mailFoldersFrom([
        box('Receipts', []),
        box('[Gmail]', [MailboxFlag.noSelect]),
        box('[Gmail]/Trash', [MailboxFlag.trash]),
        box('[Gmail]/Starred', [MailboxFlag.flagged]),
        box('[Gmail]/All Mail', [MailboxFlag.all]),
        box('INBOX', [MailboxFlag.inbox]),
        box('[Gmail]/Sent Mail', [MailboxFlag.sent]),
        box('[Gmail]/Spam', [MailboxFlag.junk]),
        box('[Gmail]/Drafts', [MailboxFlag.drafts]),
      ]);

      expect(
        [for (final f in folders) f.label],
        [
          'INBOX',
          'STARRED',
          'SENT',
          'DRAFTS',
          'ALL MAIL',
          'SPAM',
          'TRASH',
          'RECEIPTS',
        ],
      );
      expect(folders.first.name, 'INBOX');
      expect(folders[6].canTrash, isFalse);
      expect(folders[5].canTrash, isFalse);
      expect(folders[0].canTrash, isTrue);
    });
  });

  group('send', () {
    late FakeSmtpServer smtp;
    late InMemorySecretStore smtpSecrets;
    late ImapMailService smtpMail;

    Future<void> bootSmtp({bool account = true}) async {
      smtp = FakeSmtpServer(user: 'kay@example.com', password: _password);
      await smtp.start();
      smtpSecrets = InMemorySecretStore();
      smtpMail = ImapMailService(
        accounts: MailAccountStore(smtpSecrets),
        secure: false,
        smtpHost: '127.0.0.1',
        smtpPort: smtp.port,
        timeout: const Duration(seconds: 5),
      );
      if (account) {
        // Bypasses IMAP login: `send` only needs a saved account, not one
        // this server would accept for reading.
        await MailAccountStore(smtpSecrets).save(
          const MailAccount(
            email: 'kay@example.com',
            host: 'imap.example.com',
            password: _password,
          ),
        );
      }
    }

    tearDown(() async {
      await smtp.stop();
    });

    test('without an account it is not set up, and never connects', () async {
      await bootSmtp(account: false);

      expect(
        await smtpMail.send(to: <String>['a@b.com'], subject: 'Hi', text: 'Hi'),
        isA<MailSendNotSetUp>(),
      );
      expect(smtp.sent, isEmpty);
    });

    test('logs in and hands the server a message', () async {
      await bootSmtp();

      final result = await smtpMail.send(
        to: <String>['anna@example.com'],
        subject: 'Lunch?',
        text: 'Same place as usual?',
      );

      expect(result, isA<MailSent>());
      expect(smtp.sent, hasLength(1));
      expect(smtp.sent.single.from, 'kay@example.com');
      expect(smtp.sent.single.to, 'anna@example.com');
      expect(smtp.sent.single.data, contains('Same place as usual?'));
      expect(smtp.sent.single.data, contains('Lunch?'));
    });

    test('the wrong password refuses the login, without saying it', () async {
      await bootSmtp();
      await MailAccountStore(smtpSecrets).save(
        const MailAccount(
          email: 'kay@example.com',
          host: 'imap.example.com',
          password: 'wrong password',
        ),
      );

      final result = await smtpMail.send(
        to: <String>['a@b.com'],
        subject: 'Hi',
        text: 'Hi',
      );

      expect(result, isA<MailSendFailed>());
      expect((result as MailSendFailed).reason, contains('refused the login'));
      expect(result.reason, isNot(contains('wrong password')));
      expect(smtp.sent, isEmpty);
    });

    test('a refused recipient is a failure, and sends nothing', () async {
      await bootSmtp();
      smtp.rejectRecipient = true;

      final result = await smtpMail.send(
        to: <String>['nobody@example.com'],
        subject: 'Hi',
        text: 'Hi',
      );

      expect(result, isA<MailSendFailed>());
      expect(smtp.sent, isEmpty);
    });

    test('an unreachable server is a failure with a reason', () async {
      await bootSmtp();
      await smtp.stop();

      final result = await smtpMail.send(
        to: <String>['a@b.com'],
        subject: 'Hi',
        text: 'Hi',
      );

      expect(result, isA<MailSendFailed>());
    });

    test('an unreadable saved account says how to recover', () async {
      await bootSmtp(account: false);
      smtpSecrets.data['mailAccount'] = 'not json';

      final result = await smtpMail.send(
        to: <String>['a@b.com'],
        subject: 'Hi',
        text: 'Hi',
      );

      expect(result, isA<MailSendFailed>());
      expect(smtp.sent, isEmpty);
    });
  });
}

import 'package:android_tile_launcher/model/mail.dart';
import 'package:android_tile_launcher/model/mail_format.dart';
import 'package:android_tile_launcher/services/imap_mail_service.dart';
import 'package:android_tile_launcher/services/local_store_exception.dart';
import 'package:android_tile_launcher/services/mail_account.dart';
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
      expect(opened.body.attachments, 0);
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

    test('counts attachments without showing them', () async {
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
      expect(opened.body.attachments, 2);
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

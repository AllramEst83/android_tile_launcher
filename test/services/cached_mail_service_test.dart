import 'package:android_tile_launcher/model/mail.dart';
import 'package:android_tile_launcher/services/cached_mail_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_mail_service.dart';

MailMessages _inbox({int shown = 3, int total = 50}) => MailMessages(
  <MailMessage>[
    for (int i = 0; i < shown; i++)
      MailMessage(uid: 100 - i, from: 'Anna', subject: 'S$i'),
  ],
  total: total,
  unread: 2,
  validity: 7,
);

void main() {
  late FakeMailService inner;
  late DateTime now;
  late CachedMailService mail;
  setUp(() {
    inner = FakeMailService(_inbox());
    now = DateTime(2026, 9, 28, 10);
    mail = CachedMailService(
      inner: inner,
      maxAge: const Duration(minutes: 3),
      clock: () => now,
    );
  });

  test('the first read goes to the server', () async {
    final MailResult result = await mail.latest(count: 10);

    expect(result, isA<MailMessages>());
    expect(inner.counts, <int>[10]);
  });

  test('a second read soon after is answered without the server', () async {
    await mail.latest(count: 10);
    now = now.add(const Duration(minutes: 2));

    await mail.latest(count: 10);

    expect(inner.counts, hasLength(1));
  });

  test('past its age it asks again', () async {
    await mail.latest(count: 10);
    now = now.add(const Duration(minutes: 3));

    await mail.latest(count: 10);

    expect(inner.counts, hasLength(2));
  });

  test('fresh always asks', () async {
    await mail.latest(count: 10);

    await mail.latest(count: 10, fresh: true);

    expect(inner.counts, hasLength(2));
  });

  test(
    'asking for fewer than were kept is served from what was kept',
    () async {
      await mail.latest(count: 20);

      await mail.latest(count: 5);

      expect(inner.counts, hasLength(1));
    },
  );

  test('asking for more than were kept goes to the server', () async {
    await mail.latest(count: 10);

    await mail.latest(count: 20);

    expect(inner.counts, hasLength(2));
  });

  test(
    'asking for more is fine when the whole inbox was already there',
    () async {
      inner.result = _inbox(shown: 3, total: 3);
      await mail.latest(count: 10);

      await mail.latest(count: 20);

      expect(inner.counts, hasLength(1));
    },
  );

  test('a failure is not kept: the next read tries again', () async {
    inner.result = const MailUnavailable('no connection');
    await mail.latest(count: 10);

    inner.result = _inbox();
    final MailResult second = await mail.latest(count: 10);

    expect(second, isA<MailMessages>());
    expect(inner.counts, hasLength(2));
  });

  test('a failure drops what was kept', () async {
    await mail.latest(count: 10);
    inner.result = const MailUnavailable('no connection');
    await mail.latest(count: 10, fresh: true);

    await mail.latest(count: 10);

    expect(inner.counts, hasLength(3));
  });

  test('moving a message to Trash drops the kept listing', () async {
    await mail.latest(count: 10);

    await mail.moveToTrash(100, validity: 7);
    await mail.latest(count: 10);

    expect(inner.moves, <(int, int?)>[(100, 7)]);
    expect(inner.counts, hasLength(2));
  });

  test('opening a message drops the kept listing, and passes it on', () async {
    await mail.latest(count: 10);
    inner.readResult = const MailReadGone();

    final MailReadResult result = await mail.read(100, validity: 7);
    await mail.latest(count: 10);

    expect(result, isA<MailReadGone>());
    expect(inner.reads, <(int, int?)>[(100, 7)]);
    expect(inner.counts, hasLength(2));
  });

  test('marking a message drops the kept listing, and passes it on', () async {
    await mail.latest(count: 10);

    final MailMarkResult result = await mail.mark(
      100,
      read: false,
      validity: 7,
    );
    await mail.latest(count: 10);

    expect((result as MailMarked).read, isFalse);
    expect(inner.marks, <(int, bool, int?)>[(100, false, 7)]);
    expect(inner.counts, hasLength(2));
  });

  test('setting up or forgetting an account drops it too', () async {
    await mail.latest(count: 10);
    await mail.setUp(email: 'a@b.se', host: 'imap.b.se', password: 'x');
    await mail.latest(count: 10);
    await mail.forget();
    await mail.latest(count: 10);

    expect(inner.counts, hasLength(3));
    expect(inner.forgets, 1);
  });

  test('the account is the inner one', () async {
    await mail.setUp(email: 'a@b.se', host: 'imap.b.se', password: 'x');

    expect((await mail.account())?.email, 'a@b.se');
  });

  test('sending passes straight through, and never drops the cache', () async {
    await mail.latest(count: 10);

    final MailSendResult result = await mail.send(
      to: <String>['a@b.se'],
      subject: 'Hi',
      text: 'Hi',
    );

    expect(result, isA<MailSent>());
    expect(inner.sent, hasLength(1));
    final (to, cc, subject, text) = inner.sent.single;
    expect(to, <String>['a@b.se']);
    expect(cc, isEmpty);
    expect(subject, 'Hi');
    expect(text, 'Hi');
    // Still within the kept listing's age, so this is served from the cache
    // sending left untouched, not a second call to the server.
    await mail.latest(count: 10);
    expect(inner.counts, hasLength(1));
  });
}

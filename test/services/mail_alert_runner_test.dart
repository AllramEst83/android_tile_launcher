import 'package:android_tile_launcher/model/mail.dart';
import 'package:android_tile_launcher/model/mail_alert.dart';
import 'package:android_tile_launcher/services/mail_alert_runner.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_mail_notifier.dart';
import '../fakes/fake_mail_service.dart';
import '../fakes/in_memory_local_store.dart';

MailMessages _inbox(List<MailMessage> messages) =>
    MailMessages(messages, total: messages.length, unread: messages.length);

MailMessage _m(int uid, String from, {bool unread = true}) =>
    MailMessage(uid: uid, from: from, subject: 'Subject $uid', unread: unread);

void main() {
  late FakeMailService mail;
  late InMemoryLocalStore store;
  late FakeMailNotifier notifier;
  late MailAlertRunner runner;

  setUp(() {
    mail = FakeMailService(_inbox(<MailMessage>[_m(2, 'b'), _m(1, 'a')]))
      ..saved = const MailAccountInfo(email: 'kay@gmail.com', host: 'h');
    store = InMemoryLocalStore();
    notifier = FakeMailNotifier();
    runner = MailAlertRunner(mail: mail, store: store, notifier: notifier);
  });

  test('the first look announces nothing', () async {
    expect(await runner.check(), 0);
    expect(notifier.shown, isEmpty);
  });

  test('a later look announces what arrived, once', () async {
    await runner.check();
    mail.result = _inbox(<MailMessage>[
      _m(3, 'New one'),
      _m(2, 'b'),
      _m(1, 'a'),
    ]);

    expect(await runner.check(), 1);
    expect(notifier.shown.single.title, 'New one');
    expect(notifier.shown.single.ref, const MailRef(uid: 3));

    expect(await runner.check(), 0);
    expect(notifier.shown, hasLength(1));
  });

  test('asks the server fresh, never from a kept answer', () async {
    await runner.check();
    expect(mail.freshCalls, 1);
  });

  test('without an account it does nothing', () async {
    mail.saved = null;
    expect(await runner.check(), 0);
    expect(mail.counts, isEmpty);
  });

  test(
    'a server that cannot be reached announces nothing and keeps the cursor',
    () async {
      await runner.check();
      mail.result = const MailUnavailable('offline');

      expect(await runner.check(), 0);

      mail.result = _inbox(<MailMessage>[
        _m(3, 'Back'),
        _m(2, 'b'),
        _m(1, 'a'),
      ]);
      expect(await runner.check(), 1);
    },
  );

  test('the cursor is kept between looks, in the store', () async {
    await runner.check();
    final MailAlertRunner again = MailAlertRunner(
      mail: mail,
      store: store,
      notifier: notifier,
    );
    mail.result = _inbox(<MailMessage>[_m(5, 'Later'), _m(2, 'b')]);

    expect(await again.check(), 1);
  });
}

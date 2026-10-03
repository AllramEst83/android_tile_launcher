import 'dart:async';

import 'package:android_tile_launcher/model/mail.dart';
import 'package:android_tile_launcher/services/mail_alert_runner.dart';
import 'package:android_tile_launcher/services/mail_idle_loop.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_mail_notifier.dart';
import '../fakes/fake_mail_service.dart';
import '../fakes/in_memory_local_store.dart';

MailMessages _inbox(List<MailMessage> messages) =>
    MailMessages(messages, total: messages.length, unread: messages.length);

MailMessage _m(int uid, String from) =>
    MailMessage(uid: uid, from: from, subject: 'S$uid', unread: true);

void main() {
  late FakeMailService mail;
  late FakeMailNotifier notifier;
  late List<Duration> pauses;
  late MailIdleLoop loop;

  setUp(() {
    mail = FakeMailService(_inbox(<MailMessage>[_m(1, 'a')]))
      ..saved = const MailAccountInfo(email: 'kay@gmail.com', host: 'h');
    notifier = FakeMailNotifier();
    pauses = <Duration>[];
    loop = MailIdleLoop(
      mail: mail,
      runner: MailAlertRunner(
        mail: mail,
        store: InMemoryLocalStore(),
        notifier: notifier,
      ),
      pause: (Duration d) async => pauses.add(d),
    );
  });

  test('announces mail that arrives while it waits', () async {
    final Completer<MailWait> arrival = Completer<MailWait>();
    mail.waitGate = arrival;
    final Future<void> running = loop.run();
    // The first look sets the baseline and the loop waits.
    await pumpEventQueue();
    expect(notifier.shown, isEmpty);

    mail.result = _inbox(<MailMessage>[_m(2, 'New one'), _m(1, 'a')]);
    arrival.complete(MailWait.changed);
    await pumpEventQueue();
    loop.stop();
    await running;

    expect(notifier.shown.map((a) => a.title), <String>['New one']);
  });

  test('a quiet wait looks again and carries on', () async {
    mail.waits
      ..add(MailWait.quiet)
      ..add(MailWait.quiet);
    final Future<void> running = loop.run();
    await pumpEventQueue();
    loop.stop();
    await running;

    expect(mail.waitCalls, greaterThanOrEqualTo(2));
    expect(pauses, isEmpty);
  });

  test('a failing connection is retried after a growing pause', () async {
    mail.waits
      ..add(MailWait.failed)
      ..add(MailWait.failed)
      ..add(MailWait.failed)
      ..add(MailWait.failed)
      ..add(MailWait.failed)
      ..add(MailWait.changed);
    final Future<void> running = loop.run();
    await pumpEventQueue();
    loop.stop();
    await running;

    expect(pauses.take(5).toList(), <Duration>[
      const Duration(seconds: 30),
      const Duration(minutes: 1),
      const Duration(minutes: 2),
      const Duration(minutes: 5),
      // And it stops growing there.
      const Duration(minutes: 5),
    ]);
  });

  test('a good wait after failures starts the pauses over', () async {
    mail.waits
      ..add(MailWait.failed)
      ..add(MailWait.changed)
      ..add(MailWait.failed);
    final Future<void> running = loop.run();
    await pumpEventQueue();
    loop.stop();
    await running;

    expect(pauses, <Duration>[
      const Duration(seconds: 30),
      const Duration(seconds: 30),
    ]);
  });

  test('stop ends the wait in progress and the loop', () async {
    final Future<void> running = loop.run();
    await pumpEventQueue();
    expect(loop.stopped, isFalse);

    loop.stop();
    await running.timeout(const Duration(seconds: 2));

    expect(loop.stopped, isTrue);
  });
}

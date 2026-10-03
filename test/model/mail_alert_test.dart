import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/mail.dart';
import 'package:android_tile_launcher/model/mail_alert.dart';
import 'package:android_tile_launcher/model/settings.dart';
import 'package:flutter_test/flutter_test.dart';

MailMessage _m(
  int uid,
  String from, {
  bool unread = true,
  String subject = 'Hello',
  String? folder,
}) => MailMessage(
  uid: uid,
  from: from,
  subject: subject,
  unread: unread,
  folder: folder,
);

MailMessages _list(List<MailMessage> messages) =>
    MailMessages(messages, total: messages.length, unread: 0);

void main() {
  group('MailRef', () {
    test('round-trips through a notification payload', () {
      const MailRef inbox = MailRef(uid: 42);
      const MailRef other = MailRef(uid: -107, folder: '[Gmail]/All Mail');

      expect(MailRef.fromPayload(inbox.payload), inbox);
      expect(MailRef.fromPayload(other.payload), other);
    });

    test('anything else is no ref', () {
      expect(MailRef.fromPayload(null), isNull);
      expect(MailRef.fromPayload(''), isNull);
      expect(MailRef.fromPayload('nonsense'), isNull);
      expect(MailRef.fromPayload('x|y'), isNull);
    });
  });

  group('planMailAlerts', () {
    test('the first look only sets the cursor', () {
      final MailAlertPlan plan = planMailAlerts(
        listing: _list(<MailMessage>[_m(9, 'a'), _m(8, 'b')]),
        account: 'kay@gmail.com',
      );

      expect(plan.alerts, isEmpty);
      expect(plan.cursor.lastUid, 9);
    });

    test('reports unread mail newer than the cursor, oldest first', () {
      const MailAlertCursor cursor = MailAlertCursor(
        source: 'kay@gmail.com|inbox',
        lastUid: 7,
      );
      final MailAlertPlan plan = planMailAlerts(
        listing: _list(<MailMessage>[
          _m(10, 'Newest'),
          _m(9, 'Read already', unread: false),
          _m(8, 'Middle', subject: ''),
          _m(7, 'Old'),
        ]),
        account: 'kay@gmail.com',
        cursor: cursor,
      );

      expect(
        [for (final MailAlert a in plan.alerts) a.title],
        ['Middle', 'Newest'],
      );
      expect(plan.alerts.first.body, Messages.mailNoSubject);
      expect(plan.alerts.last.ref, const MailRef(uid: 10));
      expect(plan.cursor.lastUid, 10);
    });

    test('nothing new, nothing shown, the cursor stays', () {
      const MailAlertCursor cursor = MailAlertCursor(
        source: 'kay@gmail.com|inbox',
        lastUid: 10,
      );
      final MailAlertPlan plan = planMailAlerts(
        listing: _list(<MailMessage>[_m(10, 'a'), _m(9, 'b')]),
        account: 'kay@gmail.com',
        cursor: cursor,
      );

      expect(plan.alerts, isEmpty);
      expect(plan.cursor.lastUid, 10);
    });

    test('a message that was read before the look is not announced', () {
      const MailAlertCursor cursor = MailAlertCursor(
        source: 'kay@gmail.com|inbox',
        lastUid: 5,
      );
      final MailAlertPlan plan = planMailAlerts(
        listing: _list(<MailMessage>[_m(6, 'a', unread: false)]),
        account: 'kay@gmail.com',
        cursor: cursor,
      );

      expect(plan.alerts, isEmpty);
      // But it is looked past, not announced when it turns unread later.
      expect(plan.cursor.lastUid, 6);
    });

    test('too many new ones get a summary', () {
      const MailAlertCursor cursor = MailAlertCursor(
        source: 'kay@gmail.com|inbox',
        lastUid: 0,
      );
      final MailAlertPlan plan = planMailAlerts(
        listing: _list(<MailMessage>[
          for (int i = 7; i >= 1; i--) _m(i, 'Sender $i'),
        ]),
        account: 'kay@gmail.com',
        cursor: cursor,
        maxAlerts: 4,
      );

      expect(plan.alerts, hasLength(5));
      expect(plan.alerts.first.ref, isNull);
      expect(plan.alerts.first.title, Messages.mailAlertMoreTitle(3));
      // The four newest, oldest of them first.
      expect(
        [for (final MailAlert a in plan.alerts.skip(1)) a.ref!.uid],
        [4, 5, 6, 7],
      );
    });

    test('ids from another account or another kind of folder start over', () {
      const MailAlertCursor cursor = MailAlertCursor(
        source: 'kay@gmail.com|inbox',
        lastUid: 1,
      );

      final MailAlertPlan otherAccount = planMailAlerts(
        listing: _list(<MailMessage>[_m(50, 'a')]),
        account: 'other@gmail.com',
        cursor: cursor,
      );
      final MailAlertPlan otherKind = planMailAlerts(
        listing: _list(<MailMessage>[_m(-90, 'a', folder: '[Gmail]/All Mail')]),
        account: 'kay@gmail.com',
        cursor: cursor,
      );

      expect(otherAccount.alerts, isEmpty);
      expect(otherKind.alerts, isEmpty);
      expect(otherKind.cursor.source, 'kay@gmail.com|all');
      expect(otherKind.cursor.lastUid, 90);
    });

    test('Gmail ids, which are negative, are compared by their server id', () {
      const MailAlertCursor cursor = MailAlertCursor(
        source: 'kay@gmail.com|all',
        lastUid: 100,
      );
      final MailAlertPlan plan = planMailAlerts(
        listing: _list(<MailMessage>[
          _m(-103, 'New', folder: '[Gmail]/All Mail'),
          _m(-100, 'Old', folder: '[Gmail]/All Mail'),
        ]),
        account: 'kay@gmail.com',
        cursor: cursor,
      );

      expect(plan.alerts.single.title, 'New');
      expect(
        plan.alerts.single.ref,
        const MailRef(uid: -103, folder: '[Gmail]/All Mail'),
      );
    });
  });

  group('the cursor', () {
    test('round-trips through JSON', () {
      const MailAlertCursor cursor = MailAlertCursor(
        source: 'a|inbox',
        lastUid: 4,
      );
      final MailAlertCursor? back = MailAlertCursor.fromJson(cursor.toJson());
      expect(back?.source, 'a|inbox');
      expect(back?.lastUid, 4);
    });

    test('junk is no cursor', () {
      expect(MailAlertCursor.fromJson('x'), isNull);
      expect(MailAlertCursor.fromJson(<String, Object>{'source': 'a'}), isNull);
    });
  });

  group('the setting', () {
    test('is off by default and survives JSON', () {
      expect(const LauncherSettings().mailAlerts, MailAlertMode.off);
      final LauncherSettings on = const LauncherSettings().copyWith(
        mailAlerts: MailAlertMode.periodic,
      );
      expect(
        LauncherSettings.fromJson(on.toJson()).mailAlerts,
        MailAlertMode.periodic,
      );
    });

    test('a value it does not know is off', () {
      expect(
        LauncherSettings.fromJson(<String, Object>{'mailAlerts': 'carrier'})
            .mailAlerts,
        MailAlertMode.off,
      );
    });
  });
}

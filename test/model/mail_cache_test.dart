import 'package:android_tile_launcher/model/mail.dart';
import 'package:android_tile_launcher/model/mail_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final MailMessages listing = MailMessages(
    <MailMessage>[
      MailMessage(
        uid: 9,
        from: 'Anna',
        subject: 'Lunch',
        date: DateTime(2026, 9, 28, 9, 5),
        unread: true,
      ),
    ],
    total: 40,
    unread: 3,
    validity: 77,
    starred: const <MailMessage>[
      MailMessage(
        uid: -5,
        from: 'Old Friend',
        subject: 'Keep',
        starred: true,
        folder: '[Gmail]/Starred',
      ),
    ],
    nextOffset: 20,
  );

  test('round-trips a listing', () {
    final MailMessages? back = mailListingFromJson(
      mailListingToJson(listing, account: 'kay@gmail.com'),
      account: 'kay@gmail.com',
    );
    expect(back, isNotNull);
    expect(back!.total, 40);
    expect(back.unread, 3);
    expect(back.validity, 77);
    expect(back.nextOffset, 20);
    expect(back.messages.single.date, DateTime(2026, 9, 28, 9, 5));
    expect(back.messages.single.unread, isTrue);
    expect(back.starred.single.uid, -5);
    expect(back.starred.single.folder, '[Gmail]/Starred');
    expect(back.starred.single.starred, isTrue);
  });

  test('another account never sees it', () {
    expect(
      mailListingFromJson(
        mailListingToJson(listing, account: 'kay@gmail.com'),
        account: 'other@gmail.com',
      ),
      isNull,
    );
  });

  test('junk and old versions are no listing', () {
    expect(mailListingFromJson('x', account: 'a'), isNull);
    expect(mailListingFromJson(<String, Object>{'v': 0}, account: 'a'), isNull);
    expect(
      mailListingFromJson(<String, Object>{
        'v': 1,
        'account': 'a',
        'total': 'many',
      }, account: 'a'),
      isNull,
    );
  });

  test('a malformed message is skipped, the rest kept', () {
    final Map<String, Object?> json = mailListingToJson(listing, account: 'a');
    (json['messages']! as List<Object?>).add(<String, Object?>{'uid': 'x'});
    expect(mailListingFromJson(json, account: 'a')!.messages, hasLength(1));
  });
}

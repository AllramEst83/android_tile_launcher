import 'package:android_tile_launcher/model/mail.dart';
import 'package:android_tile_launcher/model/tile_content.dart';
import 'package:android_tile_launcher/services/mail_tile_source.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_mail_service.dart';

void main() {
  test('reads the newest ten and says when', () async {
    final FakeMailService mail = FakeMailService(
      const MailMessages(<MailMessage>[], total: 0, unread: 0),
    );
    final DateTime now = DateTime(2026, 9, 28, 10, 30);

    final TileContent content = await MailTileSource(
      service: mail,
      clock: () => now,
    ).read();

    expect(mail.counts, <int>[10]);
    expect(content, isA<MailContent>());
    expect((content as MailContent).now, now);
    expect(content.result, isA<MailMessages>());
  });

  test('passes on why there is nothing to show', () async {
    final TileContent content = await MailTileSource(service: FakeMailService())
        .read();

    expect((content as MailContent).result, isA<MailNotSetUp>());
  });

  test('the number to read can be chosen', () async {
    final FakeMailService mail = FakeMailService();

    await MailTileSource(service: mail, count: 4).read();

    expect(mail.counts, <int>[4]);
  });
}

import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/contact.dart';
import 'package:android_tile_launcher/services/contacts_service.dart';
import 'package:android_tile_launcher/services/phone_service.dart';
import 'package:android_tile_launcher/services/sms_service.dart';
import 'package:android_tile_launcher/services/whatsapp_service.dart';
import 'package:android_tile_launcher/ui/contact_sheet.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_contacts.dart';
import '../fakes/fake_tile_services.dart';

const Contact _anna = Contact(
  key: 'k1',
  name: 'Anna Andersson',
  numbers: <PhoneNumber>[
    PhoneNumber('08-123 45 67', 'HOME'),
    PhoneNumber('070-123 45 67', 'MOBILE'),
  ],
);

class _Rig {
  _Rig() {
    contacts = FakeContactsRepository(<Contact>[_anna]);
    phone = FakePhoneService();
    sms = FakeSmsService();
    whatsApp = FakeWhatsAppService();
  }

  late final FakeContactsRepository contacts;
  late final FakePhoneService phone;
  late final FakeSmsService sms;
  late final FakeWhatsAppService whatsApp;

  Future<void> open(
    WidgetTester tester, {
    String key = 'k1',
    String name = 'Anna Andersson',
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: tileLauncherTheme(),
        home: Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () => showContactSheet(
              context,
              services: fakeTileServices(
                contacts: contacts,
                phone: phone,
                sms: sms,
                whatsApp: whatsApp,
              ),
              contactKey: key,
              name: name,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets('shows the name and every number, the mobile one selected', (
    WidgetTester tester,
  ) async {
    final _Rig rig = _Rig();
    await rig.open(tester);

    expect(find.text('ANNA ANDERSSON'), findsOneWidget);
    expect(find.text('  HOME 08-123 45 67'), findsOneWidget);
    expect(find.text('> MOBILE 070-123 45 67'), findsOneWidget);
    // Nothing has been done by opening it.
    expect(rig.phone.called, isEmpty);
    expect(rig.sms.sent, isEmpty);
    expect(rig.whatsApp.opened, isEmpty);
  });

  testWidgets('CALL dials the selected number as the phone wants it', (
    WidgetTester tester,
  ) async {
    final _Rig rig = _Rig();
    await rig.open(tester);

    await tester.tap(find.byKey(contactCallKey));
    await tester.pumpAndSettle();

    expect(rig.phone.called, <String>['0701234567']);
    // The call screen takes over, so the sheet is gone.
    expect(find.byKey(contactCallKey), findsNothing);
  });

  testWidgets('choosing another number changes what CALL dials', (
    WidgetTester tester,
  ) async {
    final _Rig rig = _Rig();
    await rig.open(tester);

    await tester.tap(find.byKey(contactNumberKey(0)));
    await tester.pump();
    expect(find.text('> HOME 08-123 45 67'), findsOneWidget);
    await tester.tap(find.byKey(contactCallKey));
    await tester.pumpAndSettle();

    expect(rig.phone.called, <String>['081234567']);
  });

  testWidgets('the dialer opening is as good as a call placed', (
    WidgetTester tester,
  ) async {
    final _Rig rig = _Rig()..phone.result = const DialerOpened();
    await rig.open(tester);

    await tester.tap(find.byKey(contactCallKey));
    await tester.pumpAndSettle();

    expect(find.byKey(contactCallKey), findsNothing);
  });

  testWidgets('a call that cannot be made says why and stays', (
    WidgetTester tester,
  ) async {
    final _Rig rig = _Rig()..phone.result = const CallFailed('no dialer');
    await rig.open(tester);

    await tester.tap(find.byKey(contactCallKey));
    await tester.pumpAndSettle();

    expect(find.text('FAILED: NO DIALER'), findsOneWidget);
    expect(find.byKey(contactCallKey), findsOneWidget);
  });

  testWidgets('WHATSAPP opens the chat with the international number', (
    WidgetTester tester,
  ) async {
    final _Rig rig = _Rig();
    await rig.open(tester);

    await tester.tap(find.byKey(contactWhatsAppKey));
    await tester.pumpAndSettle();

    expect(rig.whatsApp.opened, <String>['46701234567']);
    expect(find.byKey(contactWhatsAppKey), findsNothing);
  });

  testWidgets('a WhatsApp that will not open says why', (
    WidgetTester tester,
  ) async {
    final _Rig rig = _Rig()
      ..whatsApp.result = const WhatsAppFailed('could not open WhatsApp');
    await rig.open(tester);

    await tester.tap(find.byKey(contactWhatsAppKey));
    await tester.pumpAndSettle();

    expect(find.text('FAILED: COULD NOT OPEN WHATSAPP'), findsOneWidget);
  });

  group('SMS', () {
    testWidgets('SMS only opens the message field; nothing is sent by it', (
      WidgetTester tester,
    ) async {
      final _Rig rig = _Rig();
      await rig.open(tester);
      expect(find.byKey(contactMessageKey), findsNothing);

      await tester.tap(find.byKey(contactSmsKey));
      await tester.pumpAndSettle();

      expect(find.byKey(contactMessageKey), findsOneWidget);
      expect(find.byKey(contactSendKey), findsOneWidget);
      expect(rig.sms.sent, isEmpty);
    });

    testWidgets('SEND sends what was typed to the selected number', (
      WidgetTester tester,
    ) async {
      final _Rig rig = _Rig();
      await rig.open(tester);
      await tester.tap(find.byKey(contactSmsKey));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(contactMessageKey), '  On my way  ');
      await tester.tap(find.byKey(contactSendKey));
      await tester.pumpAndSettle();

      expect(rig.sms.sent, <(String, String)>[('0701234567', 'On my way')]);
      expect(find.text(Messages.contactSent), findsOneWidget);
      // Sent: the field goes, ready for the next.
      expect(find.byKey(contactMessageKey), findsNothing);
    });

    testWidgets('SEND with nothing typed sends nothing', (
      WidgetTester tester,
    ) async {
      final _Rig rig = _Rig();
      await rig.open(tester);
      await tester.tap(find.byKey(contactSmsKey));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(contactMessageKey), '   ');
      await tester.tap(find.byKey(contactSendKey));
      await tester.pumpAndSettle();

      expect(rig.sms.sent, isEmpty);
    });

    testWidgets('a refusal keeps the text and says so', (
      WidgetTester tester,
    ) async {
      final _Rig rig = _Rig()..sms.result = const SmsDenied(permanent: true);
      await rig.open(tester);
      await tester.tap(find.byKey(contactSmsKey));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(contactMessageKey), 'Hi');

      await tester.tap(find.byKey(contactSendKey));
      await tester.pumpAndSettle();

      expect(find.text(Messages.smsAllowInSettings), findsOneWidget);
      expect(find.text('Hi'), findsOneWidget);
    });

    testWidgets('a failure keeps the text and says why', (
      WidgetTester tester,
    ) async {
      final _Rig rig = _Rig()
        ..sms.result = const SmsFailed('flight mode is on');
      await rig.open(tester);
      await tester.tap(find.byKey(contactSmsKey));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(contactMessageKey), 'Hi');

      await tester.tap(find.byKey(contactSendKey));
      await tester.pumpAndSettle();

      expect(find.text('FAILED: FLIGHT MODE IS ON'), findsOneWidget);
      expect(find.text('Hi'), findsOneWidget);
    });
  });

  testWidgets('a single number is shown, and not something to choose', (
    WidgetTester tester,
  ) async {
    final _Rig rig = _Rig()
      ..contacts.result = const ContactsRead(<Contact>[
        Contact(
          key: 'k1',
          name: 'Anna Andersson',
          numbers: <PhoneNumber>[PhoneNumber('070-1', 'MOBILE')],
        ),
      ]);
    await rig.open(tester);

    expect(find.text('> MOBILE 070-1'), findsOneWidget);
  });

  testWidgets('finds the person by name when the key no longer resolves', (
    WidgetTester tester,
  ) async {
    final _Rig rig = _Rig();
    await rig.open(tester, key: 'stale-key');

    expect(find.byKey(contactCallKey), findsOneWidget);
  });

  testWidgets('says so when the person is gone from the phone book', (
    WidgetTester tester,
  ) async {
    final _Rig rig = _Rig();
    await rig.open(tester, key: 'stale-key', name: 'Somebody Else');

    expect(find.text(Messages.contactGone), findsOneWidget);
    expect(find.byKey(contactCallKey), findsNothing);
  });

  testWidgets('says so when contacts are not allowed', (
    WidgetTester tester,
  ) async {
    final _Rig rig = _Rig()
      ..contacts.result = const ContactsDenied(permanent: false);
    await rig.open(tester);

    expect(find.text(Messages.contactsNotAllowed), findsOneWidget);
    expect(find.byKey(contactCallKey), findsNothing);
  });

  testWidgets('says where the setting is when Android will not ask again', (
    WidgetTester tester,
  ) async {
    final _Rig rig = _Rig()
      ..contacts.result = const ContactsDenied(permanent: true);
    await rig.open(tester);

    expect(find.text(Messages.contactsAllowInSettings), findsOneWidget);
  });
}

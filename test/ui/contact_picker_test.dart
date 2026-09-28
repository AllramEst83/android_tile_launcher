import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/contact.dart';
import 'package:android_tile_launcher/model/tile.dart';
import 'package:android_tile_launcher/services/contacts_service.dart';
import 'package:android_tile_launcher/services/grid_state.dart';
import 'package:android_tile_launcher/ui/contact_picker.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_contacts.dart';
import '../fakes/in_memory_local_store.dart';

Contact _person(String key, String name) => Contact(
  key: key,
  name: name,
  numbers: const <PhoneNumber>[PhoneNumber('070-1', 'MOBILE')],
);

Future<GridState> _open(
  WidgetTester tester,
  FakeContactsRepository contacts, {
  GridState? gridState,
}) async {
  final GridState state = gridState ?? GridState(store: InMemoryLocalStore());
  await tester.pumpWidget(
    MaterialApp(
      theme: tileLauncherTheme(),
      home: Builder(
        builder: (BuildContext context) => TextButton(
          onPressed: () =>
              showContactPicker(context, contacts: contacts, gridState: state),
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return state;
}

void main() {
  final List<Contact> book = <Contact>[
    _person('k1', 'Anna Andersson'),
    _person('k2', 'Bo Berg'),
    _person('k3', 'Åsa Ek'),
  ];

  testWidgets('lists everyone, by name', (WidgetTester tester) async {
    await _open(tester, FakeContactsRepository(book));

    expect(find.text('ANNA ANDERSSON'), findsOneWidget);
    expect(find.text('BO BERG'), findsOneWidget);
    expect(find.text('ÅSA EK'), findsOneWidget);
  });

  testWidgets('files Å, Ä, Ö after Z, as the app drawer does', (
    WidgetTester tester,
  ) async {
    // The provider hands them over with Ä among the A's.
    await _open(
      tester,
      FakeContactsRepository(<Contact>[
        _person('k1', 'Ärla Ek'),
        _person('k2', 'Zack Zeta'),
        _person('k3', 'Anna Ahl'),
        _person('k4', 'Östen Ek'),
        _person('k5', 'Åsa Ek'),
      ]),
    );

    double top(String key) =>
        tester.getTopLeft(find.byKey(contactRowKey(key))).dy;

    expect(top('k3'), lessThan(top('k2')));
    expect(top('k2'), lessThan(top('k5')));
    expect(top('k5'), lessThan(top('k1')));
    expect(top('k1'), lessThan(top('k4')));
  });

  testWidgets('tapping someone pins them, labelled with their name', (
    WidgetTester tester,
  ) async {
    final GridState state = await _open(tester, FakeContactsRepository(book));

    await tester.tap(find.byKey(contactRowKey('k2')));
    await tester.pumpAndSettle();

    expect(state.pinned, hasLength(1));
    final tile = state.pinned.single;
    expect(tile.kind, TileKind.contact);
    expect(tile.id, contactTileId('k2'));
    expect(tile.label, 'Bo Berg');
    // The sheet closed.
    expect(find.byKey(contactSearchKey), findsNothing);
  });

  testWidgets('typing narrows the list, ignoring case', (
    WidgetTester tester,
  ) async {
    await _open(tester, FakeContactsRepository(book));

    await tester.enterText(find.byKey(contactSearchKey), 'berg');
    await tester.pump();

    expect(find.text('BO BERG'), findsOneWidget);
    expect(find.text('ANNA ANDERSSON'), findsNothing);
  });

  testWidgets('a search that matches nobody says so', (
    WidgetTester tester,
  ) async {
    await _open(tester, FakeContactsRepository(book));

    await tester.enterText(find.byKey(contactSearchKey), 'zzz');
    await tester.pump();

    expect(find.text(Messages.contactsNoMatch), findsOneWidget);
  });

  testWidgets('someone already pinned is not offered again', (
    WidgetTester tester,
  ) async {
    final GridState state = GridState(store: InMemoryLocalStore());
    await state.pinContact(key: 'k1', name: 'Anna Andersson');

    await _open(tester, FakeContactsRepository(book), gridState: state);

    expect(find.text('ANNA ANDERSSON'), findsNothing);
    expect(find.text('BO BERG'), findsOneWidget);
  });

  testWidgets('an empty phone book says so', (WidgetTester tester) async {
    await _open(tester, FakeContactsRepository());

    expect(find.text(Messages.contactsNone), findsOneWidget);
  });

  testWidgets('a refusal is worded', (WidgetTester tester) async {
    final FakeContactsRepository refused = FakeContactsRepository()
      ..result = const ContactsDenied(permanent: false);
    await _open(tester, refused);

    expect(find.text(Messages.contactsNotAllowed), findsOneWidget);
  });

  testWidgets('a final refusal says where the setting is', (
    WidgetTester tester,
  ) async {
    final FakeContactsRepository forever = FakeContactsRepository()
      ..result = const ContactsDenied(permanent: true);
    await _open(tester, forever);

    expect(find.text(Messages.contactsAllowInSettings), findsOneWidget);
  });

  testWidgets('an unreadable phone book says why', (WidgetTester tester) async {
    final FakeContactsRepository broken = FakeContactsRepository()
      ..result = const ContactsUnavailable('the contacts did not answer');
    await _open(tester, broken);

    expect(find.text('THE CONTACTS DID NOT ANSWER'), findsOneWidget);
  });
}

import 'package:android_tile_launcher/model/contact.dart';
import 'package:android_tile_launcher/services/contacts_service.dart';
import 'package:android_tile_launcher/services/live_contacts_repository.dart';
import 'package:android_tile_launcher/services/permission_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_contacts.dart';
import '../fakes/fake_permission_service.dart';

const Contact _anna = Contact(
  key: 'k1',
  name: 'Anna',
  numbers: <PhoneNumber>[PhoneNumber('070-1', 'MOBILE')],
);

void main() {
  late FakeContactsService service;
  late FakePermissionService permissions;
  late LiveContactsRepository repository;
  setUp(() {
    service = FakeContactsService();
    permissions = FakePermissionService();
    repository = LiveContactsRepository(
      contacts: service,
      permissions: permissions,
    );
  });

  test('with access already, it reads and never asks', () async {
    service.result = const ContactsRead(<Contact>[_anna]);

    final ContactsResult result = await repository.all();

    expect((result as ContactsRead).contacts, <Contact>[_anna]);
    expect(permissions.requested, isEmpty);
  });

  test('without access it asks for contacts, then reads again', () async {
    // First read: no access. Once asked, the fake service has some.
    permissions = _GrantingPermissions(() {
      service.result = const ContactsRead(<Contact>[_anna]);
    });
    repository = LiveContactsRepository(
      contacts: service,
      permissions: permissions,
    );

    final ContactsResult result = await repository.all();

    expect(result, isA<ContactsRead>());
    expect(permissions.requested, <AppPermission>[AppPermission.contacts]);
    expect(service.calls, 2);
  });

  test('a refusal is denied, and not asked twice in one call', () async {
    permissions.answer = PermissionStatus.denied;

    final ContactsResult result = await repository.all();

    expect((result as ContactsDenied).permanent, isFalse);
    expect(permissions.requested, hasLength(1));
    expect(service.calls, 1);
  });

  test('a permanent refusal is passed on as permanent', () async {
    permissions.answer = PermissionStatus.permanentlyDenied;

    expect(((await repository.all()) as ContactsDenied).permanent, isTrue);
  });

  test('granted yet still no access is unavailable', () async {
    expect(await repository.all(), isA<ContactsUnavailable>());
  });

  test('peek reads straight from the service, and never asks', () async {
    service.result = const ContactsRead(<Contact>[_anna]);

    final ContactsResult result = await repository.peek();

    expect((result as ContactsRead).contacts, <Contact>[_anna]);
    expect(permissions.requested, isEmpty);
  });

  test('peek with no access is ContactsNoAccess, not a prompt', () async {
    expect(await repository.peek(), isA<ContactsNoAccess>());
    expect(permissions.requested, isEmpty);
  });

  test('a phone book that cannot be read says so', () async {
    service.result = const ContactsUnavailable('the contacts did not answer');

    final ContactsResult result = await repository.all();

    expect(
      (result as ContactsUnavailable).reason,
      'the contacts did not answer',
    );
    expect(permissions.requested, isEmpty);
  });
}

/// Grants the request and runs [onGrant], as the platform would make the
/// contacts readable.
class _GrantingPermissions extends FakePermissionService {
  _GrantingPermissions(this.onGrant);

  final void Function() onGrant;

  @override
  Future<PermissionStatus> request(AppPermission permission) {
    onGrant();
    return super.request(permission);
  }
}

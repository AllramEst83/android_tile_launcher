import 'package:android_tile_launcher/services/contacts_repository.dart';
import 'package:android_tile_launcher/services/contacts_service.dart';
import 'package:android_tile_launcher/services/permission_service.dart';

/// [ContactsRepository] on a [ContactsService] (the phone book) and a
/// [PermissionService] (asked when the service reports no access).
class LiveContactsRepository implements ContactsRepository {
  const LiveContactsRepository({
    required this.contacts,
    required this.permissions,
  });

  final ContactsService contacts;
  final PermissionService permissions;

  @override
  Future<ContactsResult> peek() => contacts.all();

  @override
  Future<ContactsResult> all() async {
    final ContactsResult first = await contacts.all();
    if (first is! ContactsNoAccess) return first;

    final PermissionStatus status = await permissions.request(
      AppPermission.contacts,
    );
    if (status != PermissionStatus.granted) {
      return ContactsDenied(
        permanent: status == PermissionStatus.permanentlyDenied,
      );
    }
    final ContactsResult second = await contacts.all();
    // Granted, yet still no access: something else is wrong.
    return second is ContactsNoAccess
        ? const ContactsUnavailable('could not read the contacts')
        : second;
  }
}

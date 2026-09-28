import 'package:android_tile_launcher/services/contacts_service.dart';

/// The phone book for the contact picker and a contact tile's sheet. Only ever
/// called from a tap (picking a contact to pin, opening a pinned one), so it
/// may show Android's permission dialog. Never throws: a failure is a
/// [ContactsDenied] or [ContactsUnavailable].
abstract interface class ContactsRepository {
  /// Everyone with a number, by name; [ContactsRead], [ContactsDenied] or
  /// [ContactsUnavailable] (never [ContactsNoAccess]: this asks first).
  Future<ContactsResult> all();
}

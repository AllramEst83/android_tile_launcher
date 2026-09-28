import 'package:android_tile_launcher/model/contact.dart';

sealed class ContactsResult {
  const ContactsResult();
}

/// Everyone in the phone book who has a number, by name.
class ContactsRead extends ContactsResult {
  const ContactsRead(this.contacts);

  final List<Contact> contacts;
}

/// Android has not given contacts access. Reading never asks; whoever wants
/// the dialog asks `PermissionService` first.
class ContactsNoAccess extends ContactsResult {
  const ContactsNoAccess();
}

/// The user said no. [permanent] means Android will no longer ask, so the
/// caller says where the setting is instead of asking again.
class ContactsDenied extends ContactsResult {
  const ContactsDenied({required this.permanent});

  final bool permanent;
}

/// Access is fine but the phone book could not be read; [reason] is short.
class ContactsUnavailable extends ContactsResult {
  const ContactsUnavailable(this.reason);

  final String reason;
}

/// The phone's contacts, read-only, read through Android's contacts provider.
abstract interface class ContactsService {
  /// Never throws; every failure is a [ContactsNoAccess] or
  /// [ContactsUnavailable]. Matching a name is the caller's job: a phone book
  /// is small, and matching in Dart keeps accents and case right.
  Future<ContactsResult> all();
}

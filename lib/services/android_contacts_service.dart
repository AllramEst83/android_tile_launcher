import 'dart:async';

import 'package:android_tile_launcher/model/contact.dart';
import 'package:android_tile_launcher/services/contacts_service.dart';
import 'package:flutter/services.dart';

/// [ContactsService] backed by the Kotlin `ContactsChannelHandler`. The only
/// file that knows about the channel. Never asks for permission itself.
class AndroidContactsService implements ContactsService {
  const AndroidContactsService({
    this.channel = const MethodChannel(channelName),
    this.timeout = const Duration(seconds: 15),
  });

  static const String channelName =
      'com.codedbykay.android_tile_launcher/contacts';

  final MethodChannel channel;

  /// Only guards against a reply that never comes.
  final Duration timeout;

  @override
  Future<ContactsResult> all() async {
    final List<Contact> contacts;
    try {
      final List<Map<Object?, Object?>>? raw = await channel
          .invokeListMethod<Map<Object?, Object?>>('all')
          .timeout(timeout);
      contacts = _group(raw ?? const <Map<Object?, Object?>>[]);
    } on PlatformException catch (error) {
      return switch (error.code) {
        'NO_PERMISSION' => const ContactsNoAccess(),
        _ => const ContactsUnavailable('could not read the contacts'),
      };
    } on MissingPluginException {
      return const ContactsUnavailable('contacts are not supported here');
    } on TimeoutException {
      return const ContactsUnavailable('the contacts did not answer');
    }
    // Best effort: compose's autocomplete is the only reader of emails, and a
    // phone book that reads fine otherwise should not fail just because that
    // second query did not.
    try {
      final List<Map<Object?, Object?>>? raw = await channel
          .invokeListMethod<Map<Object?, Object?>>('emails')
          .timeout(timeout);
      return ContactsRead(
        _withEmails(contacts, raw ?? const <Map<Object?, Object?>>[]),
      );
    } on Object {
      return ContactsRead(contacts);
    }
  }

  /// [contacts], each carrying the emails [rows] gave for its own key (only
  /// ever attached to a contact who already has a number).
  static List<Contact> _withEmails(
    List<Contact> contacts,
    List<Map<Object?, Object?>> rows,
  ) {
    final Map<String, List<String>> byKey = <String, List<String>>{};
    for (final Map<Object?, Object?> row in rows) {
      final String? key = _text(row['key']);
      final String? email = _text(row['email']);
      if (key == null || email == null) continue;
      final List<String> emails = byKey.putIfAbsent(key, () => <String>[]);
      if (!emails.contains(email)) emails.add(email);
    }
    if (byKey.isEmpty) return contacts;
    return List<Contact>.unmodifiable(<Contact>[
      for (final Contact c in contacts)
        if (byKey.containsKey(c.key))
          Contact(
            key: c.key,
            name: c.name,
            numbers: c.numbers,
            emails: List<String>.unmodifiable(byKey[c.key]!),
          )
        else
          c,
    ]);
  }

  /// One row per number in, one [Contact] per lookup key out, in the order the
  /// keys first appear (the platform sorts them by name).
  static List<Contact> _group(List<Map<Object?, Object?>> rows) {
    final Map<String, String> names = <String, String>{};
    final Map<String, List<PhoneNumber>> byKey = <String, List<PhoneNumber>>{};
    for (final Map<Object?, Object?> row in rows) {
      final String? key = _text(row['key']);
      final String? number = _text(row['number']);
      if (key == null || number == null) continue;
      // A contact with no name is shown by its number.
      names.putIfAbsent(key, () => _text(row['name']) ?? number);
      final List<PhoneNumber> numbers = byKey.putIfAbsent(
        key,
        () => <PhoneNumber>[],
      );
      // The same number written two ways (`070-123 45 67`, `0701234567`) is
      // one number.
      final String digits = dialable(number);
      if (numbers.any((PhoneNumber n) => dialable(n.number) == digits)) {
        continue;
      }
      numbers.add(
        PhoneNumber(number, (_text(row['label']) ?? 'other').toUpperCase()),
      );
    }
    return List<Contact>.unmodifiable(<Contact>[
      for (final MapEntry<String, List<PhoneNumber>> entry in byKey.entries)
        Contact(
          key: entry.key,
          name: names[entry.key]!,
          numbers: List<PhoneNumber>.unmodifiable(entry.value),
        ),
    ]);
  }

  static String? _text(Object? value) =>
      value is String && value.trim().isNotEmpty ? value.trim() : null;
}

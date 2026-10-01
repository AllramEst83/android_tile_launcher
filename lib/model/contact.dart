/// A phone number as saved in the phone book.
class PhoneNumber {
  const PhoneNumber(this.number, this.label);

  /// As typed into the phone book (`070-123 45 67`, `+46 70 123 45 67`).
  final String number;

  /// Uppercase and short: `MOBILE`, `HOME`, `WORK`, or a custom label.
  final String label;

  @override
  bool operator ==(Object other) =>
      other is PhoneNumber && other.number == number && other.label == label;

  @override
  int get hashCode => Object.hash(number, label);

  @override
  String toString() => 'PhoneNumber($label $number)';
}

/// One person with at least one phone number.
class Contact {
  const Contact({
    required this.key,
    required this.name,
    required this.numbers,
    this.emails = const <String>[],
  });

  /// Android's lookup key: what a pinned tile remembers the person by. It
  /// survives a rename, and Android keeps it resolving when contacts merge.
  final String key;
  final String name;
  final List<PhoneNumber> numbers;

  /// This person's email addresses, if any — only ever attached to a contact
  /// who also has a number (see `AndroidContactsService`); for compose's
  /// autocomplete, not shown anywhere else.
  final List<String> emails;

  /// The number to offer first: a mobile one if there is one (a text or a
  /// WhatsApp message goes nowhere on a landline), else the first.
  PhoneNumber get preferredNumber => numbers.firstWhere(
    (PhoneNumber n) => n.label == 'MOBILE',
    orElse: () => numbers.first,
  );

  @override
  bool operator ==(Object other) =>
      other is Contact &&
      other.key == key &&
      other.name == name &&
      _sameNumbers(other.numbers, numbers) &&
      _sameStrings(other.emails, emails);

  @override
  int get hashCode =>
      Object.hash(key, name, Object.hashAll(numbers), Object.hashAll(emails));

  @override
  String toString() => 'Contact($name, $key, ${numbers.length} numbers)';
}

bool _sameNumbers(List<PhoneNumber> a, List<PhoneNumber> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _sameStrings(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// [number] as a phone can dial it: digits and a leading `+`, nothing else.
String dialable(String number) => number.replaceAll(RegExp(r'[^\d+]'), '');

/// The country code a number written without one is taken to be in: Sweden,
/// like the rest of this launcher (Swedish collation, SMHI). Only WhatsApp
/// needs it; a call or a text goes through the phone's own network as written.
/// A later settings phase can make it a choice.
const String defaultCountryCode = '46';

/// [number] the way `wa.me` wants it: international, digits only, no `+` or
/// `00`. `070-123 45 67` becomes `46701234567`.
String whatsAppNumber(String number) {
  final String digits = dialable(number);
  if (digits.startsWith('+')) return digits.substring(1);
  if (digits.startsWith('00')) return digits.substring(2);
  if (digits.startsWith('0')) {
    return '$defaultCountryCode${digits.substring(1)}';
  }
  return digits;
}

/// The contact a tile was pinned for: the one with lookup [key], else (the key
/// stopped resolving, as it can when contacts merge) the one called [name].
/// `null` when neither is in [contacts] any more.
Contact? findContact(
  List<Contact> contacts, {
  required String key,
  required String name,
}) {
  for (final Contact c in contacts) {
    if (c.key == key) return c;
  }
  final String wanted = name.toLowerCase();
  for (final Contact c in contacts) {
    if (c.name.toLowerCase() == wanted) return c;
  }
  return null;
}

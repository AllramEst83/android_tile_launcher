// Alphabetical order as a Swedish phone book keeps it: A to Z, then Å, Ä, Ö,
// with an accented letter filed under its plain one (É with E, Ü with U). Æ
// and Ø, which Swedish sorts with Ä and Ö, are filed there.
//
// Ported from the sibling terminal launcher's `terminal/tools/alphabet.dart`
// (its contact sorting), generalised to any labelled item, so the app drawer
// (Phase 4) and the contacts tile (Phase 10) group the same way.

const Map<String, String> _folds = {
  'a': 'àáâãāăą',
  'c': 'çćč',
  'd': 'ðď',
  'e': 'èéêëēęě',
  'i': 'ìíîï',
  'l': 'ł',
  'n': 'ñń',
  'o': 'òóôõōő',
  'r': 'ř',
  's': 'šśß',
  't': 'ť',
  'u': 'ùúûüūůű',
  'y': 'ýÿ',
  'z': 'žźż',
  // After z, in the order of the Swedish alphabet.
  '{': 'å',
  '|': 'äæ',
  '}': 'öø',
};

final Map<String, String> _fold = <String, String>{
  for (final MapEntry<String, String> entry in _folds.entries)
    for (final String letter in entry.value.split('')) letter: entry.key,
};

const String _sortedLast = '{|}';
const Map<String, String> _swedish = {'{': 'Å', '|': 'Ä', '}': 'Ö'};

/// What to sort [text] by: lower case, accents folded, and Å Ä Ö placed after
/// Z. Compare two of these with `compareTo`.
String alphabeticalKey(String text) {
  final StringBuffer buffer = StringBuffer();
  for (final int rune in text.toLowerCase().runes) {
    final String letter = String.fromCharCode(rune);
    buffer.write(_fold[letter] ?? letter);
  }
  return buffer.toString();
}

/// The letter [text] is filed under: its first letter in upper case, `Å`, `Ä`
/// or `Ö` for those, the plain letter for an accented one, and `#` for a digit,
/// a symbol or nothing at all.
String initialOf(String text) {
  final String trimmed = text.trim();
  if (trimmed.isEmpty) return '#';
  final String first = String.fromCharCode(trimmed.runes.first);
  final String key = alphabeticalKey(first);
  if (_sortedLast.contains(key)) return _swedish[key]!;
  final String upper = key.toUpperCase();
  return RegExp(r'\p{L}', unicode: true).hasMatch(upper) ? upper : '#';
}

/// Orders two initials from [initialOf]: A to Z, Å, Ä, Ö, other alphabets, and
/// `#` last.
int compareInitials(String a, String b) {
  if (a == '#') return b == '#' ? 0 : 1;
  if (b == '#') return -1;
  return alphabeticalKey(a).compareTo(alphabeticalKey(b));
}

/// One bucket of a [groupByInitial] result: everything filed under [initial],
/// in label order.
class InitialGroup<T> {
  const InitialGroup({required this.initial, required this.items});

  final String initial;
  final List<T> items;
}

/// Buckets [items] the way a Swedish phone book does: A to Z, then Å, Ä, Ö,
/// with a name starting on a digit, a symbol, or nothing filed under `#` last.
/// [label] names each item; two items with the same key keep their original
/// relative order.
List<InitialGroup<T>> groupByInitial<T>(
  List<T> items,
  String Function(T item) label,
) {
  final List<(String key, int index, T item)> keyed = [
    for (final (int index, T item) in items.indexed)
      (alphabeticalKey(label(item)), index, item),
  ];
  keyed.sort((a, b) {
    final int byKey = a.$1.compareTo(b.$1);
    return byKey != 0 ? byKey : a.$2.compareTo(b.$2);
  });

  final Map<String, List<T>> byInitial = <String, List<T>>{};
  for (final (_, _, T item) in keyed) {
    byInitial.putIfAbsent(initialOf(label(item)), () => <T>[]).add(item);
  }
  final List<String> initials = byInitial.keys.toList()..sort(compareInitials);
  return [
    for (final String initial in initials)
      InitialGroup(initial: initial, items: byInitial[initial]!),
  ];
}

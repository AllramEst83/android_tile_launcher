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

/// How far through a `groupByInitial` list the group at [index] starts, as a
/// fraction of the whole (0 at the top, up to just under 1 for the last
/// group) — for a jump index that scrubs by letter to land where the list
/// actually scrolls to, not just where the letter sits among the others.
/// Scroll distance tracks content, not letter count: a group of fifty names
/// takes far more of it than one with a single name, so each group is
/// weighted by its own header (worth [headerWeight]) plus [itemWeight] per
/// item, and [index] counts for as much of the whole as the groups before it
/// do. The defaults (both `1`) treat a header and an item as the same size;
/// callers that know better — a header row is taller on screen than an item
/// row — pass the real measured heights instead, so the fraction tracks
/// actual scroll position rather than a naive per-row count that would
/// undercount every header passed, worse the more of them there are.
double jumpFraction<T>(
  List<InitialGroup<T>> groups,
  int index, {
  double headerWeight = 1,
  double itemWeight = 1,
}) {
  if (groups.isEmpty) return 0;
  final int target = index.clamp(0, groups.length - 1);
  double before = 0;
  double total = 0;
  for (final (int i, InitialGroup<T> group) in groups.indexed) {
    final double weight = headerWeight + group.items.length * itemWeight;
    if (i < target) before += weight;
    total += weight;
  }
  return total == 0 ? 0 : before / total;
}

/// The inverse of [jumpFraction]: which group is at the very top of the list
/// once it has been scrolled so that [fraction] (0 at the very top, up to
/// just under 1 at the very end) of the whole list's weighted content sits
/// above the viewport — for the jump index's own persistent marker, so it
/// tracks where the list actually is on an ordinary scroll, not only where a
/// drag on the index last sent it. [headerWeight] and [itemWeight] must match
/// whatever [jumpFraction] was called with, or the two drift apart.
int groupIndexForFraction<T>(
  List<InitialGroup<T>> groups,
  double fraction, {
  double headerWeight = 1,
  double itemWeight = 1,
}) {
  if (groups.isEmpty) return 0;
  double total = 0;
  for (final InitialGroup<T> group in groups) {
    total += headerWeight + group.items.length * itemWeight;
  }
  if (total == 0) return 0;
  final double target = fraction.clamp(0.0, 1.0) * total;
  double before = 0;
  for (final (int i, InitialGroup<T> group) in groups.indexed) {
    final double weight = headerWeight + group.items.length * itemWeight;
    if (target < before + weight) return i;
    before += weight;
  }
  return groups.length - 1;
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

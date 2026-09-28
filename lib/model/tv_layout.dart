import 'package:android_tile_launcher/model/styled_text.dart';

/// Rows shorter than this (in characters of text) say too little about where a
/// page's text sits: a page number, a lone word, a short caption.
const int _minInk = 12;

/// The blank margin, in cells, a Text TV page leaves to the left and to the
/// right of its text: the least room any of its longer rows leaves on each
/// side. Text TV pages are not laid out symmetrically (headlines are indented
/// two cells and run to the last column), so drawn as they come the text sits
/// visibly to one side of the screen.
///
/// The first row (the page's own title strip) is left out, and so are block
/// graphics and short rows.
({int left, int right}) tvTextMargins(
  List<List<StyledRun>> rows, {
  required int columns,
}) {
  int? left;
  int? right;
  for (final List<StyledRun> row in rows.skip(1)) {
    final String text = plainText(row);
    final String trimmed = text.trim();
    if (trimmed.runes.length < _minInk) continue;
    final int lead = text.length - text.trimLeft().length;
    final int trail = columns - text.trimRight().length;
    left = left == null || lead < left ? lead : left;
    right = right == null || trail < right ? trail : right;
  }
  return (left: left ?? 0, right: right ?? 0);
}

/// The black gutter, in cells, to draw at each side of a page so that its text
/// has the same margin on both. The two always add up to `2 * base` (so the
/// grid is drawn at the same size whichever way the page leans) and each is
/// at least 0: a page that already sits centred gets `base` on each side, one
/// whose text leans right gets less on the left and more on the right.
({int left, int right}) tvGutters(
  List<List<StyledRun>> rows, {
  required int columns,
  int base = 1,
}) {
  final ({int left, int right}) margins = tvTextMargins(rows, columns: columns);
  // Positive when the text leans right (more room on its left than its right).
  final int lean = ((margins.left - margins.right) / 2).round();
  final int left = (base - lean).clamp(0, base * 2);
  return (left: left, right: base * 2 - left);
}

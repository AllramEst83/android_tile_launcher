import 'package:android_tile_launcher/model/text_tv_page.dart';

final RegExp _pageNumber = RegExp(r'\b[1-8]\d\d\b');
final RegExp _trailingNumber = RegExp(r'\s+[1-8]\d\d$');

/// The headlines on [page]'s first part, as one short line each, for a tile
/// that has room for a few: the page's own title strip, blank rows, bare page
/// numbers and the navigation row (several page numbers on one line) are left
/// out, and a page number ending a headline is dropped.
List<String> textTvHeadlines(TextTvPage page) {
  if (page.parts.isEmpty) return const <String>[];
  final List<String> headlines = <String>[];
  for (final String row in page.parts.first.skip(1)) {
    final String line = row.trim();
    if (line.isEmpty) continue;
    if (RegExp(r'^\d+$').hasMatch(line)) continue;
    if (_pageNumber.allMatches(line).length >= 2) continue;
    headlines.add(line.replaceFirst(_trailingNumber, ''));
  }
  return headlines;
}

import 'dart:convert';

import 'package:android_tile_launcher/model/styled_text.dart';
import 'package:android_tile_launcher/model/text_tv_html.dart';
import 'package:android_tile_launcher/model/text_tv_page.dart';
import 'package:android_tile_launcher/services/http_fetcher.dart';
import 'package:android_tile_launcher/services/network_exception.dart';

/// SVT Text through the public texttv.nu API
/// (https://texttv.nu/blogg/texttv-api). Read-only.
class TextTv {
  TextTv({required this._fetcher, this._app = 'android_tile_launcher'});

  /// Text TV pages are laid out on a grid this wide.
  static const columns = 40;

  final HttpFetcher _fetcher;

  /// The API asks every client to identify itself with a unique `app` value.
  final String _app;

  /// The page, or null when it is not in broadcast. Throws [NetworkException]
  /// when the site cannot be reached or answers with something unexpected.
  Future<TextTvPage?> page(int number) async {
    final url = Uri.https('texttv.nu', '/api/get/$number', {
      'app': _app,
      'includePlainTextContent': '1',
    });
    final body = await _fetcher.get(url);

    final Object? json;
    try {
      json = jsonDecode(body);
    } on FormatException {
      throw _unexpected;
    }
    if (json is! List) throw _unexpected;
    // An unknown page number is answered with an empty list.
    if (json.isEmpty) return null;

    final page = json.first;
    if (page is! Map) throw _unexpected;
    final plain = page['content_plain'];
    if (plain is! List || plain.isEmpty || plain.any((p) => p is! String)) {
      throw _unexpected;
    }

    final parts = [
      for (final part in plain.cast<String>())
        [for (final line in part.split('\n')) line.trimRight()],
    ];
    if (_notBroadcast(parts)) return null;
    return TextTvPage(
      number: number,
      parts: parts,
      styledParts: _styled(page['content'], parts.length),
      previous: _pageNumber(page['prev_page']),
      next: _pageNumber(page['next_page']),
    );
  }

  /// The coloured version of every part, or null if any part cannot be read
  /// (all or nothing, so a page is never half colour). The plain text stays
  /// the source of truth.
  List<List<List<StyledRun>>>? _styled(Object? content, int parts) {
    if (content is! List || content.length != parts) return null;
    final styled = <List<List<StyledRun>>>[];
    for (final html in content) {
      if (html is! String) return null;
      final rows = parseTextTvHtml(
        html,
        columns: columns,
        commandFor: (page) => '$page',
      );
      if (rows == null) return null;
      styled.add(rows);
    }
    return styled;
  }

  /// A page that is not in broadcast comes back as one line saying so.
  bool _notBroadcast(List<List<String>> parts) {
    return parts.length == 1 &&
        parts.single.length == 1 &&
        parts.single.single.toLowerCase().contains('ej i sändning');
  }

  int? _pageNumber(Object? value) => int.tryParse('$value');

  NetworkException get _unexpected =>
      const NetworkException('texttv.nu sent an answer I could not read');
}

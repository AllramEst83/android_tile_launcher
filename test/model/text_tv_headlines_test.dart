import 'dart:io';

import 'package:android_tile_launcher/model/text_tv_headlines.dart';
import 'package:android_tile_launcher/model/text_tv_page.dart';
import 'package:android_tile_launcher/services/text_tv.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_http_fetcher.dart';

TextTvPage _page(List<String> lines) =>
    TextTvPage(number: 100, parts: <List<String>>[lines]);

void main() {
  test(
    'leaves out the title, blank rows, bare page numbers and navigation',
    () {
      final List<String> headlines = textTvHeadlines(
        _page(<String>[
          '100 SVT Text lördag 26 sep 2026',
          '',
          '  Akilov i avskildhet efter två slagsmål',
          '                   107',
          '',
          '    Inrikes 101 Utrikes 104 Innehåll 700',
        ]),
      );

      expect(headlines, <String>['Akilov i avskildhet efter två slagsmål']);
    },
  );

  test('drops the page number a headline ends with, and only that', () {
    final List<String> headlines = textTvHeadlines(
      _page(<String>[
        'title',
        '  Sandviken: Grishuvud utanför moské 108',
        '  Sida 5 av 2026 utan sidnummer',
      ]),
    );

    expect(headlines, <String>[
      'Sandviken: Grishuvud utanför moské',
      'Sida 5 av 2026 utan sidnummer',
    ]);
  });

  test('keeps a headline that carries on on the next line', () {
    final List<String> headlines = textTvHeadlines(
      _page(<String>[
        'title',
        '      Fyra dödades i ryska attacker     ',
        '      - tre döda i ukrainskt anfall     ',
      ]),
    );

    expect(headlines, <String>[
      'Fyra dödades i ryska attacker',
      '- tre döda i ukrainskt anfall',
    ]);
  });

  test('a page with no parts has no headlines', () {
    expect(
      textTvHeadlines(const TextTvPage(number: 100, parts: <List<String>>[])),
      isEmpty,
    );
  });

  test('on the real page 100', () async {
    final FakeHttpFetcher fetcher = FakeHttpFetcher()
      ..route(
        '/api/get/100',
        File('test/fixtures/texttv_100.json').readAsStringSync(),
      );
    final TextTvPage page = (await TextTv(fetcher: fetcher).page(100))!;

    final List<String> headlines = textTvHeadlines(page);

    expect(headlines, contains('Akilov i avskildhet efter två slagsmål'));
    expect(headlines, contains('Sandviken: Grishuvud utanför moské'));
    expect(headlines.where((String h) => h.contains('SVT Text')), isEmpty);
    expect(headlines.where((String h) => h.contains('Innehåll 700')), isEmpty);
    expect(
      headlines.where((String h) => RegExp(r'^\d+$').hasMatch(h)),
      isEmpty,
    );
  });
}

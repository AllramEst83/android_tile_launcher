import 'dart:convert';
import 'dart:io';

import 'package:android_tile_launcher/model/styled_text.dart';
import 'package:android_tile_launcher/model/text_tv_html.dart';
import 'package:android_tile_launcher/model/tv_layout.dart';
import 'package:flutter_test/flutter_test.dart';

/// A row of [text] padded (or cut) to the page's 40 columns.
List<StyledRun> _row(String text) => <StyledRun>[StyledRun(text.padRight(40))];

List<List<StyledRun>> _page(List<String> lines) => <List<StyledRun>>[
  for (final String line in lines) _row(line),
];

List<List<StyledRun>> _fixture(String name) {
  final Object? json = jsonDecode(
    File('test/fixtures/$name').readAsStringSync(),
  );
  final Map<Object?, Object?> page =
      (json! as List).first as Map<Object?, Object?>;
  final String html = (page['content']! as List).first as String;
  return parseTextTvHtml(html, columns: 40)!;
}

void main() {
  group('tvIsBar', () {
    test('a coloured background under the whole width is a bar', () {
      final List<StyledRun> bar = <StyledRun>[
        StyledRun(
          'Inrikes 101'.padRight(40),
          fg: TvColor.yellow,
          bg: TvColor.blue,
        ),
      ];

      expect(tvIsBar(bar, columns: 40), isTrue);
    });

    test('so is one made of several coloured runs', () {
      final List<StyledRun> bar = <StyledRun>[
        StyledRun(' ' * 4, bg: TvColor.blue),
        StyledRun(
          'Innehåll 700'.padRight(36),
          fg: TvColor.yellow,
          bg: TvColor.blue,
        ),
      ];

      expect(tvIsBar(bar, columns: 40), isTrue);
    });

    test('plain text on black is not, nor is a short coloured patch', () {
      expect(tvIsBar(_row('  Rubrik'), columns: 40), isFalse);
      expect(
        tvIsBar(<StyledRun>[
          StyledRun(' ' * 10, bg: TvColor.red),
          StyledRun(' ' * 30),
        ], columns: 40),
        isFalse,
      );
    });
  });

  group('tvTextMargins', () {
    test('a colour bar does not count as text', () {
      final List<List<StyledRun>> rows = <List<StyledRun>>[
        _row('title'),
        _row('  A headline that reaches the far edge!!'),
        <StyledRun>[
          StyledRun(
            '    Inrikes 101 Utrikes 104 Innehåll 700',
            bg: TvColor.blue,
          ),
        ],
      ];

      // The bar starts at cell 4 and ends at the last cell; the headline sets
      // the margins.
      expect(tvTextMargins(rows, columns: 40), (left: 2, right: 0));
    });

    test('the room the longest-reaching rows leave on each side', () {
      final List<List<StyledRun>> rows = _page(<String>[
        '100 SVT Text', // the title strip is not counted
        '  A headline that reaches the far edge!!',
        '    Shorter one here',
      ]);

      expect(tvTextMargins(rows, columns: 40), (left: 2, right: 0));
    });

    test('short rows and blank ones say nothing', () {
      final List<List<StyledRun>> rows = _page(<String>[
        'title',
        '',
        '                   107',
        'x',
      ]);

      expect(tvTextMargins(rows, columns: 40), (left: 0, right: 0));
    });

    test('a page with nothing in it has no margins to speak of', () {
      expect(tvTextMargins(const <List<StyledRun>>[], columns: 40), (
        left: 0,
        right: 0,
      ));
    });
  });

  group('tvGutters', () {
    test('a page already centred gets the same on both sides', () {
      final List<List<StyledRun>> rows = _page(<String>[
        'title',
        '   ${'x' * 34}',
      ]);

      expect(tvGutters(rows, columns: 40), (left: 1, right: 1));
    });

    test('text leaning right gets less on the left and more on the right', () {
      // Two blank cells left of the text, none right of it.
      final List<List<StyledRun>> rows = _page(<String>[
        'title',
        '  Ofinansierade löften - räntan höjs mer',
      ]);

      final ({int left, int right}) gutters = tvGutters(rows, columns: 40);

      expect(gutters, (left: 0, right: 2));
    });

    test('text leaning left gets more on the left', () {
      final List<List<StyledRun>> rows = _page(<String>[
        'title',
        'Text that starts at the very edge.',
      ]);

      expect(tvGutters(rows, columns: 40), (left: 2, right: 0));
    });

    test('the two always add up to twice the base', () {
      for (final String line in <String>[
        '',
        'x' * 40,
        '   ${'x' * 30}',
        'x' * 30,
      ]) {
        final ({int left, int right}) g = tvGutters(
          _page(<String>['title', line]),
          columns: 40,
        );
        expect(g.left + g.right, 2);
        expect(g.left, inInclusiveRange(0, 2));
      }
    });
  });

  group('on real pages', () {
    for (final String name in <String>[
      // (texttv_104.json is plain text only, without the coloured markup.)
      'texttv_100.json',
      'texttv_377.json',
    ]) {
      test(
        '$name ends up with its text margins equal, give or take a cell',
        () {
          final List<List<StyledRun>> rows = _fixture(name);
          final ({int left, int right}) margins = tvTextMargins(
            rows,
            columns: 40,
          );
          final ({int left, int right}) gutters = tvGutters(rows, columns: 40);

          final int visibleLeft = gutters.left + margins.left;
          final int visibleRight = gutters.right + margins.right;

          expect((visibleLeft - visibleRight).abs(), lessThanOrEqualTo(1));
        },
      );
    }
  });
}

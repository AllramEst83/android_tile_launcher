import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/text_tv_page.dart';
import 'package:android_tile_launcher/ui/text_tv_tile_view.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final TextTvPage _page = TextTvPage(
  number: 100,
  parts: <List<String>>[
    <String>[
      '100 SVT Text lördag 26 sep 2026',
      '',
      '  Akilov i avskildhet efter två slagsmål',
      '                   107',
      '  Fyra dödades i ryska attacker',
      '                   130',
      '  Räntan höjs mer',
    ],
  ],
);

Future<void> _pump(
  WidgetTester tester,
  TextTvResult result, {
  Size size = const Size(380, 185),
  VoidCallback? onTap,
}) => tester.pumpWidget(
  MaterialApp(
    theme: tileLauncherTheme(),
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: TextTvTileContentView(
            result: result,
            ink: Colors.white,
            onTap: onTap,
          ),
        ),
      ),
    ),
  ),
);

/// The headline the tile drew at [index].
Text _headline(WidgetTester tester, int index) => tester.widget<Text>(
  find.descendant(
    of: find.byKey(textTvHeadlineKey(index)),
    matching: find.byType(Text),
  ),
);

void main() {
  group('with a page', () {
    testWidgets('small: the name and the page number', (
      WidgetTester tester,
    ) async {
      await _pump(tester, TextTvShown(_page), size: const Size(90, 90));

      expect(find.text(Messages.textTvTitle), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
      expect(find.byKey(textTvHeadlineKey(0)), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('larger: the headlines that fit, in capitals', (
      WidgetTester tester,
    ) async {
      await _pump(tester, TextTvShown(_page));

      expect(
        find.text('AKILOV I AVSKILDHET EFTER TVÅ SLAGSMÅL'),
        findsOneWidget,
      );
      expect(find.text('FYRA DÖDADES I RYSKA ATTACKER'), findsOneWidget);
      expect(find.text('RÄNTAN HÖJS MER'), findsOneWidget);
    });

    testWidgets('only as many lines as the height holds', (
      WidgetTester tester,
    ) async {
      await _pump(tester, TextTvShown(_page), size: const Size(380, 60));

      expect(find.byKey(textTvHeadlineKey(0)), findsOneWidget);
      expect(find.byKey(textTvHeadlineKey(2)), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the headlines are big enough to read', (
      WidgetTester tester,
    ) async {
      await _pump(tester, TextTvShown(_page));

      expect(_headline(tester, 0).style?.fontSize, greaterThanOrEqualTo(11));
    });

    testWidgets('a headline too long for one line wraps to as many as it '
        'needs, the lead story more than the rest', (
      WidgetTester tester,
    ) async {
      await _pump(tester, TextTvShown(_page));

      // The lead story: too long for one line even at its extra allowance.
      expect(_headline(tester, 0).maxLines, 2);
      // Short enough not to need the second line the tile would allow it.
      expect(_headline(tester, 1).maxLines, 1);
    });

    testWidgets('a short headline is not stretched to lines it does not '
        'need, so the tile fits more stories', (WidgetTester tester) async {
      final TextTvPage short = TextTvPage(
        number: 100,
        parts: <List<String>>[
          <String>['100', '', '  Short one', '  Also short', '  And this'],
        ],
      );
      await _pump(tester, TextTvShown(short));

      expect(_headline(tester, 0).maxLines, 1);
      expect(_headline(tester, 1).maxLines, 1);
      expect(_headline(tester, 2).maxLines, 1);
    });

    testWidgets('narrower still, a headline needs more lines to read in '
        'full', (WidgetTester tester) async {
      await _pump(tester, TextTvShown(_page), size: const Size(185, 185));

      expect(_headline(tester, 0).maxLines, 3);
      expect(tester.takeException(), isNull);
    });
  });

  group('without a page', () {
    testWidgets('not in broadcast says so', (WidgetTester tester) async {
      await _pump(tester, const TextTvNotBroadcast(100));

      expect(find.text(Messages.textTvNotBroadcast), findsOneWidget);
    });

    testWidgets('a failure says why, and that a tap opens the viewer', (
      WidgetTester tester,
    ) async {
      await _pump(tester, const TextTvFailed('no connection'));

      expect(find.text('NO CONNECTION'), findsOneWidget);
      expect(find.text(Messages.textTvTapToOpen), findsOneWidget);
    });
  });

  group('taps', () {
    testWidgets('anywhere on the tile calls onTap, whatever it shows', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      await _pump(tester, const TextTvFailed('x'), onTap: () => taps++);

      final Rect tile = tester.getRect(find.byType(TextTvTileContentView));
      await tester.tapAt(tile.centerRight - const Offset(5, 0));
      await tester.tapAt(tile.bottomLeft + const Offset(5, -5));

      expect(taps, 2);
    });

    testWidgets('without onTap there is nothing to tap', (
      WidgetTester tester,
    ) async {
      await _pump(tester, TextTvShown(_page));

      expect(find.byType(GestureDetector), findsNothing);
    });
  });
}

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

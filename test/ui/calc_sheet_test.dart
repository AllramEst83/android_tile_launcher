import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/rates.dart';
import 'package:android_tile_launcher/ui/calc_pad.dart';
import 'package:android_tile_launcher/ui/calc_sheet.dart';
import 'package:android_tile_launcher/ui/calc_tile_view.dart';
import 'package:android_tile_launcher/ui/convert_pad.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_rates_repository.dart';

Future<void> _open(
  WidgetTester tester, {
  FakeRatesRepository? rates,
  bool convert = false,
}) async {
  tester.view
    ..physicalSize = const Size(400, 900)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: tileLauncherTheme(),
      home: Builder(
        builder: (BuildContext context) => TextButton(
          onPressed: () => showCalcSheet(
            context,
            rates: rates ?? FakeRatesRepository(),
            convert: convert,
          ),
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Future<void> _keys(WidgetTester tester, List<String> keys) async {
  for (final String key in keys) {
    await tester.tap(find.byKey(calcKey(key)));
    await tester.pump();
  }
}

Future<void> _convertKeys(WidgetTester tester, List<String> keys) async {
  for (final String key in keys) {
    await tester.tap(find.byKey(convertKey(key)));
    await tester.pump();
  }
}

/// Taps a chip, scrolling its row to it first as a thumb would.
Future<void> _chip(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.pump();
  await tester.tap(find.byKey(key));
  await tester.pump();
}

String _text(WidgetTester tester, Key key) =>
    tester.widget<Text>(find.byKey(key)).data!;

void main() {
  group('the sheet', () {
    testWidgets('opens on the calculator, with tabs and a close key', (
      WidgetTester tester,
    ) async {
      await _open(tester);

      expect(find.byKey(calcTabCalcKey), findsOneWidget);
      expect(find.byKey(calcTabConvertKey), findsOneWidget);
      expect(find.byKey(calcCloseKey), findsOneWidget);
      expect(find.byKey(calcKey('7')), findsOneWidget);
    });

    testWidgets('can open on the converter', (WidgetTester tester) async {
      await _open(tester, convert: true);
      await tester.pump();

      expect(find.byKey(convertKey('7')).hitTestable(), findsOneWidget);
    });

    testWidgets('the close key closes it', (WidgetTester tester) async {
      await _open(tester);

      await tester.tap(find.byKey(calcCloseKey));
      await tester.pumpAndSettle();

      expect(find.byKey(calcCloseKey), findsNothing);
    });

    testWidgets('switching tabs keeps what was keyed on each', (
      WidgetTester tester,
    ) async {
      await _open(tester);
      await _keys(tester, <String>['4', '2']);

      await tester.tap(find.byKey(calcTabConvertKey));
      await tester.pump();
      await _convertKeys(tester, <String>['5']);
      await tester.tap(find.byKey(calcTabCalcKey));
      await tester.pump();

      expect(_text(tester, calcExpressionKey), '42');

      await tester.tap(find.byKey(calcTabConvertKey));
      await tester.pump();
      expect(_text(tester, convertValueKey), '5 KM');
    });
  });

  group('the calculator', () {
    testWidgets('shows what is keyed, and the answer so far', (
      WidgetTester tester,
    ) async {
      await _open(tester);
      expect(_text(tester, calcExpressionKey), '0');

      await _keys(tester, <String>['2', '+', '3', '*', '4']);

      expect(_text(tester, calcExpressionKey), '2+3*4');
      expect(_text(tester, calcPreviewKey), '= 14');
    });

    testWidgets('= puts the answer in place of the sum', (
      WidgetTester tester,
    ) async {
      await _open(tester);
      await _keys(tester, <String>['2', '+', '3', '*', '4', '=']);

      expect(_text(tester, calcExpressionKey), '14');
      expect(find.byKey(calcPreviewKey), findsNothing);
    });

    testWidgets('you can carry on from an answer', (WidgetTester tester) async {
      await _open(tester);
      await _keys(tester, <String>['6', '*', '7', '=', '+', '8', '=']);

      expect(_text(tester, calcExpressionKey), '50');
    });

    testWidgets('a sum that cannot be worked out says why', (
      WidgetTester tester,
    ) async {
      await _open(tester);
      await _keys(tester, <String>['1', '/', '0', '=']);

      expect(_text(tester, calcErrorKey), 'DIVISION BY ZERO');
      expect(_text(tester, calcExpressionKey), '1/0');
    });

    testWidgets('DEL takes back a key, C clears', (WidgetTester tester) async {
      await _open(tester);
      await _keys(tester, <String>['1', '2', '3', Messages.calcDelete]);
      expect(_text(tester, calcExpressionKey), '12');

      await _keys(tester, <String>[Messages.calcClear]);
      expect(_text(tester, calcExpressionKey), '0');
    });

    testWidgets('the function keys type a function with its bracket', (
      WidgetTester tester,
    ) async {
      await _open(tester);

      await tester.tap(find.byKey(calcKey('sqrt(')));
      await tester.pump();
      await _keys(tester, <String>['1', '6']);

      expect(_text(tester, calcExpressionKey), 'sqrt(16');
      expect(_text(tester, calcPreviewKey), '= 4');
    });

    testWidgets('the constants and the power key work', (
      WidgetTester tester,
    ) async {
      await _open(tester);
      await tester.tap(find.byKey(calcKey('pi')));
      await tester.pump();
      await tester.tap(find.byKey(calcKey('^')));
      await tester.pump();
      await _keys(tester, <String>['2']);

      expect(_text(tester, calcExpressionKey), 'pi^2');
      expect(_text(tester, calcPreviewKey), startsWith('= 9.8696'));
    });

    testWidgets('a long expression shrinks to fit rather than overflow', (
      WidgetTester tester,
    ) async {
      await _open(tester);
      await _keys(tester, List<String>.filled(30, '7'));

      expect(tester.takeException(), isNull);
    });
  });

  group('converting units', () {
    Future<void> converter(WidgetTester tester) async {
      await _open(tester);
      await tester.tap(find.byKey(calcTabConvertKey));
      await tester.pump();
    }

    testWidgets('starts on length, kilometres to miles', (
      WidgetTester tester,
    ) async {
      await converter(tester);

      expect(_text(tester, convertValueKey), '0 KM');
      expect(_text(tester, convertResultKey), '= ... MI');

      await _convertKeys(tester, <String>['5']);

      expect(_text(tester, convertValueKey), '5 KM');
      expect(_text(tester, convertResultKey), startsWith('= 3.10685'));
      expect(_text(tester, convertResultKey), endsWith(' MI'));
    });

    testWidgets('choosing other units changes the answer', (
      WidgetTester tester,
    ) async {
      await converter(tester);
      await _convertKeys(tester, <String>['1', '0', '0']);

      await _chip(tester, convertToKey('M'));

      expect(_text(tester, convertResultKey), '= 100000 M');

      await _chip(tester, convertFromKey('M'));

      expect(_text(tester, convertValueKey), '100 M');
      expect(_text(tester, convertResultKey), '= 100 M');
    });

    testWidgets('a kind puts its own units on the chips and a sensible pair', (
      WidgetTester tester,
    ) async {
      await converter(tester);

      await _chip(tester, convertKindKey('TEMP'));
      await _convertKeys(tester, <String>['1', '0', '0']);

      expect(_text(tester, convertValueKey), '100 °C');
      expect(_text(tester, convertResultKey), '= 212 °F');
      expect(find.byKey(convertFromKey('KM')), findsNothing);
    });

    testWidgets('SWAP turns the conversion round', (WidgetTester tester) async {
      await converter(tester);
      await _convertKeys(tester, <String>['5']);

      await tester.tap(find.byKey(convertKey('SWAP')));
      await tester.pump();

      expect(_text(tester, convertValueKey), '5 MI');
      expect(_text(tester, convertResultKey), startsWith('= 8.04672'));
    });

    testWidgets('+/-, the point, DEL and C edit the number', (
      WidgetTester tester,
    ) async {
      await converter(tester);
      await _chip(tester, convertKindKey('TEMP'));

      await _convertKeys(tester, <String>['4', '0', '+/-']);
      expect(_text(tester, convertValueKey), '-40 °C');
      expect(_text(tester, convertResultKey), '= -40 °F');

      await _convertKeys(tester, <String>['DEL', '.', '5']);
      expect(_text(tester, convertValueKey), '-4.5 °C');

      await _convertKeys(tester, <String>['C']);
      expect(_text(tester, convertValueKey), '0 °C');
    });
  });

  group('converting money', () {
    Future<void> converter(
      WidgetTester tester,
      FakeRatesRepository rates,
    ) async {
      await _open(tester, rates: rates);
      await tester.tap(find.byKey(calcTabConvertKey));
      await tester.pump();
      await _chip(tester, convertKindKey(Messages.calcMoney));
      await tester.pumpAndSettle();
    }

    testWidgets('loads the rates, then converts kronor to euros', (
      WidgetTester tester,
    ) async {
      final FakeRatesRepository rates = FakeRatesRepository();
      await converter(tester, rates);

      expect(rates.calls, 1);
      expect(_text(tester, convertNoteKey), 'RATES FROM 2026-09-25 (ECB)');
      expect(_text(tester, convertValueKey), '0 SEK');

      await _convertKeys(tester, <String>['1', '0', '0']);

      expect(_text(tester, convertResultKey), '= 8.86 EUR');
    });

    testWidgets('lists the usual currencies first', (
      WidgetTester tester,
    ) async {
      await converter(tester, FakeRatesRepository());

      final double sek = tester
          .getTopLeft(find.byKey(convertFromKey('SEK')))
          .dx;
      final double eur = tester
          .getTopLeft(find.byKey(convertFromKey('EUR')))
          .dx;
      final double usd = tester
          .getTopLeft(find.byKey(convertFromKey('USD')))
          .dx;

      expect(sek, lessThan(eur));
      expect(eur, lessThan(usd));
    });

    testWidgets('another currency changes the answer', (
      WidgetTester tester,
    ) async {
      await converter(tester, FakeRatesRepository());
      await _convertKeys(tester, <String>['1']);

      await _chip(tester, convertToKey('USD'));

      // 1 SEK in USD: 1 / 11.29 * 1.1403
      expect(_text(tester, convertResultKey), '= 0.10 USD');
    });

    testWidgets('old saved rates say so', (WidgetTester tester) async {
      final FakeRatesRepository rates = FakeRatesRepository(
        RatesLoaded(
          Rates(
            perEuro: const <String, double>{'EUR': 1, 'SEK': 11.29},
            date: DateTime(2026, 9, 20),
            fetchedAt: DateTime(2026, 9, 20),
            stale: true,
          ),
        ),
      );
      await converter(tester, rates);

      expect(
        _text(tester, convertNoteKey),
        'SAVED RATES FROM 2026-09-20 (OFFLINE)',
      );
    });

    testWidgets('no rates says why, and TRY AGAIN asks again', (
      WidgetTester tester,
    ) async {
      final FakeRatesRepository rates = FakeRatesRepository(
        const RatesFailed('no connection'),
      );
      await converter(tester, rates);
      expect(_text(tester, convertNoteKey), 'NO CONNECTION');
      expect(_text(tester, convertResultKey), '= ... EUR');

      rates.result = FakeRatesRepository().result;
      await tester.tap(find.byKey(convertRetryKey));
      await tester.pumpAndSettle();

      expect(rates.calls, 2);
      expect(_text(tester, convertNoteKey), 'RATES FROM 2026-09-25 (ECB)');
    });

    testWidgets('the rates are only asked for when money is chosen', (
      WidgetTester tester,
    ) async {
      final FakeRatesRepository rates = FakeRatesRepository();
      await _open(tester, rates: rates);
      await tester.tap(find.byKey(calcTabConvertKey));
      await tester.pump();

      expect(rates.calls, 0);
    });
  });

  group('the tile', () {
    testWidgets('names itself and calls onTap', (WidgetTester tester) async {
      int taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: tileLauncherTheme(),
          home: Scaffold(
            body: SizedBox(
              width: 380,
              height: 185,
              child: CalcTileContentView(
                ink: Colors.white,
                onTap: () => taps++,
              ),
            ),
          ),
        ),
      );

      expect(find.text(Messages.calcTitle), findsOneWidget);
      await tester.tap(find.byType(CalcTileContentView));
      expect(taps, 1);
    });

    testWidgets('small: still fits', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: tileLauncherTheme(),
          home: const Scaffold(
            body: SizedBox(
              width: 90,
              height: 90,
              child: CalcTileContentView(ink: Colors.white),
            ),
          ),
        ),
      );

      expect(find.text(Messages.calcTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('without onTap there is nothing to tap', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: tileLauncherTheme(),
          home: const Scaffold(
            body: SizedBox(
              width: 380,
              height: 185,
              child: CalcTileContentView(ink: Colors.white),
            ),
          ),
        ),
      );

      expect(find.byType(GestureDetector), findsNothing);
    });
  });
}

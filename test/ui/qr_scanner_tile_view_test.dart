import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/ui/qr_scanner_tile_view.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester, {
  double width = 200,
  double height = 120,
  VoidCallback? onTap,
}) => tester.pumpWidget(
  MaterialApp(
    theme: tileLauncherTheme(),
    home: Scaffold(
      body: SizedBox(
        width: width,
        height: height,
        child: QrScannerTileContentView(ink: Colors.white, onTap: onTap),
      ),
    ),
  ),
);

void main() {
  testWidgets('shows its name', (WidgetTester tester) async {
    await _pump(tester);

    expect(find.text(Messages.qrScannerTitle), findsOneWidget);
  });

  testWidgets('a wider tile also says what it is for', (
    WidgetTester tester,
  ) async {
    await _pump(tester, width: 200);

    expect(find.text(Messages.qrScannerSubtitle), findsOneWidget);
  });

  testWidgets('a compact tile drops the subtitle but still shows the name', (
    WidgetTester tester,
  ) async {
    await _pump(tester, width: 80);

    expect(find.text(Messages.qrScannerTitle), findsOneWidget);
    expect(find.text(Messages.qrScannerSubtitle), findsNothing);
  });

  testWidgets(
    'a wide but one-row-tall tile (TileSize.flat) does not overflow',
    (WidgetTester tester) async {
      await _pump(tester, width: 190, height: 90);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('tapping calls onTap when given', (WidgetTester tester) async {
    var tapped = false;
    await _pump(tester, onTap: () => tapped = true);

    await tester.tap(find.byType(QrScannerTileContentView));

    expect(tapped, isTrue);
  });

  testWidgets('without onTap there is nothing to tap', (
    WidgetTester tester,
  ) async {
    await _pump(tester);

    expect(find.byType(GestureDetector), findsNothing);
  });
}

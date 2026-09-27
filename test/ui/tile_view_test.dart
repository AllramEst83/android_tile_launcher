import 'package:android_tile_launcher/model/c64_colour.dart';
import 'package:android_tile_launcher/model/tile.dart';
import 'package:android_tile_launcher/model/tile_size.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:android_tile_launcher/ui/tile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const Tile _tile = Tile(
  id: 'pkg.clock',
  size: TileSize.small,
  colour: C64Colour.red,
  appPackage: 'pkg.clock',
);

Future<void> _pump(WidgetTester tester, {VoidCallback? onTap}) =>
    tester.pumpWidget(
      MaterialApp(
        theme: tileLauncherTheme(),
        home: Scaffold(
          body: SizedBox(
            width: 100,
            height: 100,
            child: TileView(tile: _tile, label: 'Clock', onTap: onTap ?? () {}),
          ),
        ),
      ),
    );

void main() {
  testWidgets('shows the label uppercase and its first letter as the glyph', (
    WidgetTester tester,
  ) async {
    await _pump(tester);

    expect(find.text('CLOCK'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
  });

  testWidgets('tapping the tile calls onTap', (WidgetTester tester) async {
    var tapped = false;
    await _pump(tester, onTap: () => tapped = true);

    await tester.tap(find.byType(TileView));

    expect(tapped, isTrue);
  });
}

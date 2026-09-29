import 'package:android_tile_launcher/model/tile_size.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:android_tile_launcher/ui/tile_size_grid_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester, {
  required TileSize size,
  required ValueChanged<TileSize> onSizeSelected,
}) => tester.pumpWidget(
  MaterialApp(
    theme: tileLauncherTheme(),
    home: Material(
      child: Center(
        child: TileSizeGridPicker(size: size, onSizeSelected: onSizeSelected),
      ),
    ),
  ),
);

void main() {
  testWidgets('every cell is at a fixed, predictable spot', (
    WidgetTester tester,
  ) async {
    TileSize? picked;
    await _pump(
      tester,
      size: TileSize.small,
      onSizeSelected: (TileSize s) => picked = s,
    );

    await tester.tap(find.byKey(sizeGridCellKey(3, 4)));
    await tester.pump();

    expect(picked, TileSize.size3x4);
  });

  testWidgets('tapping the top-left cell picks 1x1', (
    WidgetTester tester,
  ) async {
    TileSize? picked;
    await _pump(
      tester,
      size: TileSize.large,
      onSizeSelected: (TileSize s) => picked = s,
    );

    await tester.tap(find.byKey(sizeGridCellKey(1, 1)));
    await tester.pump();

    expect(picked, TileSize.small);
  });

  testWidgets('the bottom-right cell picks the largest size, no overflow', (
    WidgetTester tester,
  ) async {
    TileSize? picked;
    await _pump(
      tester,
      size: TileSize.small,
      onSizeSelected: (TileSize s) => picked = s,
    );

    await tester.tap(find.byKey(sizeGridCellKey(4, 6)));
    await tester.pump();

    expect(picked, TileSize.size4x6);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a drag paints the rectangle up to where it ends', (
    WidgetTester tester,
  ) async {
    TileSize? picked;
    await _pump(
      tester,
      size: TileSize.small,
      onSizeSelected: (TileSize s) => picked = s,
    );

    final Finder picker = find.byKey(sizeGridPickerKey);
    final Offset origin = tester.getTopLeft(picker);
    // Cells are 28px with a 3px gap (31px steps); landing well inside the
    // 3rd column / 2nd row cell.
    await tester.dragFrom(origin + const Offset(5, 5), const Offset(65, 35));
    await tester.pump();

    expect(picked, TileSize.broad);
  });

  testWidgets('mid-drag, the picker paints the rectangle without committing', (
    WidgetTester tester,
  ) async {
    TileSize? picked;
    await _pump(
      tester,
      size: TileSize.small,
      onSizeSelected: (TileSize s) => picked = s,
    );

    final Finder picker = find.byKey(sizeGridPickerKey);
    final Offset origin = tester.getTopLeft(picker);
    final TestGesture gesture = await tester.startGesture(
      origin + const Offset(5, 5),
    );
    await gesture.moveBy(const Offset(65, 35));
    await tester.pump();

    // Nothing committed yet — only the drag's own release does that.
    expect(picked, isNull);
    expect(find.byKey(sizeGridCellKey(3, 2)), findsOneWidget);

    await gesture.up();
    await tester.pump();

    expect(picked, TileSize.broad);
  });
}

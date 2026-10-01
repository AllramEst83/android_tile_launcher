import 'package:android_tile_launcher/model/tile_size.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:android_tile_launcher/ui/tile_size_grid_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester, {
  required TileSize size,
  required ValueChanged<TileSize> onSizeSelected,
  int maxColumns = 4,
}) => tester.pumpWidget(
  MaterialApp(
    theme: tileLauncherTheme(),
    home: Material(
      child: Center(
        child: TileSizeGridPicker(
          size: size,
          maxColumns: maxColumns,
          onSizeSelected: onSizeSelected,
          // Pinned so a tap/drag's pixel geometry stays predictable; the
          // real app leaves these unset and lets the panel's own width
          // decide (see the "fills the width it is given" group below).
          cellSize: 28,
          cellGap: 3,
        ),
      ),
    ),
  ),
);

bool _filled(WidgetTester tester, int columns, int rows) {
  final DecoratedBox box = tester.widget<DecoratedBox>(
    find.descendant(
      of: find.byKey(sizeGridCellKey(columns, rows)),
      matching: find.byType(DecoratedBox),
    ),
  );
  return (box.decoration as BoxDecoration).color == TileColors.accent;
}

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

  group('a 6-column mosaic', () {
    testWidgets('offers a 6th column, unlike the default 4', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        size: TileSize.small,
        onSizeSelected: (TileSize _) {},
        maxColumns: 6,
      );

      expect(find.byKey(sizeGridCellKey(6, 1)), findsOneWidget);
    });

    testWidgets('the default 4-column mosaic has no 6th column', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        size: TileSize.small,
        onSizeSelected: (TileSize _) {},
      );

      expect(find.byKey(sizeGridCellKey(6, 1)), findsNothing);
    });

    testWidgets('the bottom-right cell picks the largest 6-wide size', (
      WidgetTester tester,
    ) async {
      TileSize? picked;
      await _pump(
        tester,
        size: TileSize.small,
        onSizeSelected: (TileSize s) => picked = s,
        maxColumns: 6,
      );

      await tester.tap(find.byKey(sizeGridCellKey(6, 6)));
      await tester.pump();

      expect(picked, TileSize.size6x6);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the 4th column picks a plain 4-wide size, not a full-width '
        'one that would stretch to 6', (WidgetTester tester) async {
      TileSize? picked;
      await _pump(
        tester,
        size: TileSize.size6x2,
        onSizeSelected: (TileSize s) => picked = s,
        maxColumns: 6,
      );

      await tester.tap(find.byKey(sizeGridCellKey(4, 2)));
      await tester.pump();

      expect(picked, TileSize.size4x2);
      expect(picked!.spanIn(6), 4);

      await tester.tap(find.byKey(sizeGridCellKey(4, 4)));
      await tester.pump();

      expect(picked, TileSize.size4x4);
      expect(picked!.spanIn(6), 4);
    });

    testWidgets('a full-width tile paints every column it really spans', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        size: TileSize.wide,
        onSizeSelected: (TileSize _) {},
        maxColumns: 6,
      );

      expect(_filled(tester, 6, 2), isTrue);
      expect(_filled(tester, 6, 3), isFalse);
    });
  });

  group('fills the width it is given', () {
    Future<void> pumpResponsive(
      WidgetTester tester, {
      required double width,
      int maxColumns = 4,
    }) => tester.pumpWidget(
      MaterialApp(
        theme: tileLauncherTheme(),
        home: Material(
          child: Align(
            alignment: Alignment.topLeft,
            // A *loose* max width, the way `TileInspector`'s own
            // `CrossAxisAlignment.start` column actually gives it one — a
            // tight `SizedBox` here would force the picker back up to that
            // exact size regardless of what it computes for itself, an
            // entirely different (and here, wrong) scenario.
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: width, maxHeight: 400),
              child: TileSizeGridPicker(
                size: TileSize.small,
                maxColumns: maxColumns,
                onSizeSelected: (TileSize _) {},
              ),
            ),
          ),
        ),
      ),
    );

    testWidgets('a wide panel grows the cells, up to the cap', (
      WidgetTester tester,
    ) async {
      await pumpResponsive(tester, width: 600);

      final Size picker = tester.getSize(find.byKey(sizeGridPickerKey));
      // 4 columns at the 36px cap, 3 gaps of 3px: 4*36 + 3*3.
      expect(picker.width, closeTo(4 * 36 + 3 * 3, 0.5));
    });

    testWidgets('a narrow panel shrinks the cells, down to the floor', (
      WidgetTester tester,
    ) async {
      // Narrow enough that the raw width-derived cell size (here, 15.25)
      // falls below the 20px floor and gets clamped up to it — checked on
      // one cell directly, since the floor can force the grid as a whole
      // wider than this deliberately-too-narrow panel (a real phone is
      // never this narrow; unreadable cells are the worse failure to avoid).
      await pumpResponsive(tester, width: 70);

      final Size cell = tester.getSize(find.byKey(sizeGridCellKey(1, 1)));
      expect(cell.width, closeTo(20, 0.5));
    });

    testWidgets('6 columns fit into the same width as 4, just smaller', (
      WidgetTester tester,
    ) async {
      await pumpResponsive(tester, width: 200, maxColumns: 6);

      final Size picker = tester.getSize(find.byKey(sizeGridPickerKey));
      expect(picker.width, lessThanOrEqualTo(200));
      expect(find.byKey(sizeGridCellKey(6, 1)), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

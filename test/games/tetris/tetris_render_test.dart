import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:android_tile_launcher/games/tetris/tetris_game.dart';
import 'package:android_tile_launcher/model/tetris_board.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Renders [game] into an actual 300x600 image (not just a widget tree) and
/// returns every distinct colour painted, so a test can check that the
/// board's own drawRect/drawLine calls actually produce pixels, not just
/// that the widget exists in the tree.
Future<Set<Color>> _renderedColours(
  WidgetTester tester,
  TetrisGame game,
) async {
  final GlobalKey boundaryKey = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      theme: tileLauncherTheme(),
      home: RepaintBoundary(
        key: boundaryKey,
        child: SizedBox(width: 300, height: 600, child: GameWidget(game: game)),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));

  final RenderRepaintBoundary boundary =
      boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  // toImage()/toByteData() resolve through the engine, not the fake test
  // clock, so they need a real event-loop turn via runAsync.
  final Uint8List pixels = await tester.runAsync(() async {
    final ui.Image image = await boundary.toImage();
    final ByteData bytes = (await image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    ))!;
    return bytes.buffer.asUint8List();
  }) as Uint8List;

  final Set<Color> colours = <Color>{};
  for (int i = 0; i + 3 < pixels.length; i += 4) {
    colours.add(
      Color.fromARGB(pixels[i + 3], pixels[i], pixels[i + 1], pixels[i + 2]),
    );
  }
  return colours;
}

void main() {
  testWidgets('the board and the falling piece actually paint pixels', (
    WidgetTester tester,
  ) async {
    final game = TetrisGame(board: TetrisBoard(random: Random(1)));
    final TetrominoType activeType = game.board.active!.type;

    final Set<Color> colours = await _renderedColours(tester, game);

    expect(colours, contains(C64.black), reason: 'the board backdrop');
    expect(
      colours,
      contains(tetrominoColour(activeType).fill),
      reason: 'the falling piece',
    );
  });

  testWidgets('a locked row paints too, not just the falling piece', (
    WidgetTester tester,
  ) async {
    final board = TetrisBoard(random: Random(1));
    board.debugFillRow(10, TetrominoType.o);
    final game = TetrisGame(board: board);

    final Set<Color> colours = await _renderedColours(tester, game);

    expect(colours, contains(tetrominoColour(TetrominoType.o).fill));
  });
}

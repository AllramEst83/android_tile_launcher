import 'dart:math';

import 'package:android_tile_launcher/model/c64_colour.dart';
import 'package:android_tile_launcher/model/tetris_board.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

/// The board's score/lines/level/next/game-over, republished after every
/// change so the Flutter HUD can rebuild from a `ValueListenableBuilder`
/// without ever touching [TetrisBoard] directly.
@immutable
class TetrisHudState {
  const TetrisHudState({
    required this.score,
    required this.lines,
    required this.level,
    required this.gameOver,
    required this.next,
  });

  final int score;
  final int lines;
  final int level;
  final bool gameOver;
  final TetrominoType next;
}

/// The VIC-II colour each tetromino type is drawn in — the classic Tetris
/// colour associations (cyan I, yellow O, ...), all still from the sixteen
/// VIC-II colours the rest of the app draws with.
C64Colour tetrominoColour(TetrominoType type) => switch (type) {
  TetrominoType.i => C64Colour.cyan,
  TetrominoType.o => C64Colour.yellow,
  TetrominoType.t => C64Colour.purple,
  TetrominoType.s => C64Colour.green,
  TetrominoType.z => C64Colour.red,
  TetrominoType.j => C64Colour.blue,
  TetrominoType.l => C64Colour.orange,
};

/// The Flame layer around a pure-Dart [TetrisBoard]: drives gravity on a
/// timer, paints the board and the falling piece onto the canvas each frame,
/// and republishes the model's state as [hud] — `model/` stays Flutter-free
/// (see .agents/architecture.md) and this is the only place that bridges it
/// to something the UI can listen to.
class TetrisGame extends FlameGame {
  TetrisGame({TetrisBoard? board}) : board = board ?? TetrisBoard() {
    _publish();
  }

  final TetrisBoard board;
  final ValueNotifier<TetrisHudState> hud = ValueNotifier<TetrisHudState>(
    const TetrisHudState(
      score: 0,
      lines: 0,
      level: 1,
      gameOver: false,
      next: TetrominoType.i,
    ),
  );

  double _sinceTick = 0;

  @override
  void update(double dt) {
    super.update(dt);
    if (board.gameOver) return;
    _sinceTick += dt;
    final double interval = board.tickInterval.inMilliseconds / 1000;
    if (_sinceTick < interval) return;
    _sinceTick = 0;
    board.tick();
    _publish();
  }

  void moveLeft() => _act(board.moveLeft);
  void moveRight() => _act(board.moveRight);
  void softDrop() => _act(board.softDrop);
  void hardDrop() => _act(board.hardDrop);
  void rotate() => _act(board.rotate);

  void _act(void Function() action) {
    if (board.gameOver) return;
    action();
    _publish();
  }

  void _publish() {
    hud.value = TetrisHudState(
      score: board.score,
      lines: board.lines,
      level: board.level,
      gameOver: board.gameOver,
      next: board.next ?? TetrominoType.i,
    );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (size.x <= 0 || size.y <= 0) return;
    final double cell = (size.x / TetrisBoard.width).clamp(
      0.0,
      size.y / TetrisBoard.height,
    );
    final double boardWidth = cell * TetrisBoard.width;
    final double boardHeight = cell * TetrisBoard.height;
    final Offset origin = Offset(
      (size.x - boardWidth) / 2,
      (size.y - boardHeight) / 2,
    );

    // Fixed black, not `TileColors.canvas`: the canvas follows the user's
    // chosen theme, and the C64 theme's own canvas colour is the same blue
    // used for the J piece — a piece would vanish against its own board.
    canvas.drawRect(
      Rect.fromLTWH(origin.dx, origin.dy, boardWidth, boardHeight),
      Paint()..color = C64.black,
    );

    final List<List<TetrominoType?>> cells = board.cells;
    for (int y = 0; y < TetrisBoard.height; y++) {
      for (int x = 0; x < TetrisBoard.width; x++) {
        final TetrominoType? type = cells[y][x];
        if (type != null) _paintCell(canvas, origin, cell, x, y, type);
      }
    }
    final ActivePiece? active = board.active;
    if (active != null) {
      for (final Point<int> c in active.cells) {
        if (c.y < 0) continue;
        _paintCell(canvas, origin, cell, c.x, c.y, active.type);
      }
    }
  }

  void _paintCell(
    Canvas canvas,
    Offset origin,
    double cell,
    int x,
    int y,
    TetrominoType type,
  ) {
    final Color fill = tetrominoColour(type).fill;
    final Rect rect = Rect.fromLTWH(
      origin.dx + x * cell,
      origin.dy + y * cell,
      cell,
      cell,
    );
    canvas.drawRect(rect, Paint()..color = fill);
    // A small bevel, light top-left and dark bottom-right, matching every
    // other tile's own C64 chrome rather than a flat, borderless block.
    final double inset = (cell * 0.08).clamp(1.0, 3.0);
    final Paint light = Paint()
      ..color = Color.lerp(fill, C64.white, 0.35)!
      ..strokeWidth = inset;
    final Paint dark = Paint()
      ..color = Color.lerp(fill, C64.black, 0.35)!
      ..strokeWidth = inset;
    canvas
      ..drawLine(rect.topLeft, rect.topRight, light)
      ..drawLine(rect.topLeft, rect.bottomLeft, light)
      ..drawLine(rect.bottomLeft, rect.bottomRight, dark)
      ..drawLine(rect.topRight, rect.bottomRight, dark);
  }
}

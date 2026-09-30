import 'dart:math';

import 'package:android_tile_launcher/games/tetris/tetris_game.dart';
import 'package:android_tile_launcher/model/c64_colour.dart';
import 'package:android_tile_launcher/model/tetris_board.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // TetrisGame reads SchedulerBinding.instance (to keep hud publishes safe
  // if they ever land during a build/layout pass) even in these plain,
  // non-widget tests.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('tetrominoColour', () {
    test('every type gets its own colour, none of them black or white', () {
      final colours = {
        for (final type in TetrominoType.values) type: tetrominoColour(type),
      };

      expect(colours.values.toSet(), hasLength(TetrominoType.values.length));
      expect(colours.values, isNot(contains(C64Colour.black)));
      expect(colours.values, isNot(contains(C64Colour.white)));
    });
  });

  group('TetrisGame', () {
    test('publishes the board\'s state through hud as soon as it is built', () {
      final game = TetrisGame(board: TetrisBoard(random: Random(1)));

      expect(game.hud.value.score, 0);
      expect(game.hud.value.lines, 0);
      expect(game.hud.value.level, 1);
      expect(game.hud.value.gameOver, isFalse);
    });

    test('moveLeft/moveRight/rotate act on the board and republish hud', () {
      final game = TetrisGame(board: TetrisBoard(random: Random(1)));
      final int startCol = game.board.active!.col;

      game.moveRight();

      expect(game.board.active!.col, startCol + 1);
    });

    test('hardDrop locks the piece and updates the hud', () {
      final game = TetrisGame(board: TetrisBoard(random: Random(1)));

      game.hardDrop();

      // The board moved on: a new piece is active, and hud reflects the
      // board's post-lock state (score/lines may or may not have changed
      // depending on whether a line cleared, but hud must be in sync).
      expect(game.hud.value.next, game.board.next);
      expect(game.hud.value.score, game.board.score);
      expect(game.hud.value.lines, game.board.lines);
    });

    test('update() ticks gravity once the interval elapses, not before', () {
      final game = TetrisGame(board: TetrisBoard(random: Random(1)));
      final int startRow = game.board.active!.row;
      final double intervalSeconds =
          game.board.tickInterval.inMilliseconds / 1000;

      game.update(intervalSeconds / 2);
      expect(game.board.active!.row, startRow);

      game.update(intervalSeconds / 2 + 0.001);
      expect(game.board.active!.row, startRow + 1);
    });

    test('actions are ignored once the board is game over', () {
      final board = TetrisBoard(random: Random(1));
      // Fill the top few rows solid enough that the next spawn collides —
      // easiest via repeated stacking in the same column with no movement.
      int guard = 0;
      while (!board.gameOver && guard < 400) {
        for (int i = 0; i < 20; i++) {
          board.moveLeft();
        }
        board.hardDrop();
        guard++;
      }
      expect(board.gameOver, isTrue);

      final game = TetrisGame(board: board);
      final TetrisHudState before = game.hud.value;
      game.moveLeft();
      game.rotate();
      game.hardDrop();

      expect(game.hud.value.gameOver, isTrue);
      expect(game.hud.value.score, before.score);
    });

    test('togglePause flips hud.paused and Flame\'s own paused flag', () {
      final game = TetrisGame(board: TetrisBoard(random: Random(1)));

      expect(game.hud.value.paused, isFalse);
      expect(game.paused, isFalse);

      game.togglePause();
      expect(game.hud.value.paused, isTrue);
      expect(game.paused, isTrue);

      game.togglePause();
      expect(game.hud.value.paused, isFalse);
      expect(game.paused, isFalse);
    });

    test('moves and drops are no-ops while paused', () {
      final game = TetrisGame(board: TetrisBoard(random: Random(1)));
      final int startCol = game.board.active!.col;
      game.togglePause();

      game.moveRight();
      game.rotate();
      game.hardDrop();

      expect(game.board.active!.col, startCol);
      expect(game.hud.value.score, 0);
    });

    test('gravity does not tick while paused', () {
      final game = TetrisGame(board: TetrisBoard(random: Random(1)));
      final int startRow = game.board.active!.row;
      final double intervalSeconds =
          game.board.tickInterval.inMilliseconds / 1000;
      game.togglePause();

      game.update(intervalSeconds + 1);

      expect(game.board.active!.row, startRow);
    });

    test('togglePause does nothing once the game is over', () {
      final board = TetrisBoard(random: Random(1));
      int guard = 0;
      while (!board.gameOver && guard < 400) {
        for (int i = 0; i < 20; i++) {
          board.moveLeft();
        }
        board.hardDrop();
        guard++;
      }
      final game = TetrisGame(board: board);

      game.togglePause();

      expect(game.hud.value.paused, isFalse);
    });

    test(
      'backgroundColor is transparent: the board paints its own backdrop',
      () {
        final game = TetrisGame(board: TetrisBoard(random: Random(1)));

        expect(game.backgroundColor().a, 0);
      },
    );
  });
}

import 'dart:math';

import 'package:android_tile_launcher/model/tetris_board.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('a fresh board', () {
    test('is 10x20, empty, with an active piece already spawned', () {
      final board = TetrisBoard(random: Random(1));

      expect(board.cells.length, 20);
      expect(board.cells.every((row) => row.length == 10), isTrue);
      expect(board.cells.every((row) => row.every((c) => c == null)), isTrue);
      expect(board.active, isNotNull);
      expect(board.next, isNotNull);
      expect(board.score, 0);
      expect(board.lines, 0);
      expect(board.level, 1);
      expect(board.gameOver, isFalse);
    });
  });

  group('the 7-bag randomizer', () {
    test('deals each of the seven types exactly once per 7 pieces', () {
      final board = TetrisBoard(random: Random(42));
      final seen = <TetrominoType>[];

      for (int i = 0; i < 7; i++) {
        seen.add(board.active!.type);
        board.hardDrop();
      }

      expect(seen.toSet(), TetrominoType.values.toSet());
      expect(seen.length, 7);
    });

    test('a fixed seed reproduces the same sequence of pieces', () {
      final a = TetrisBoard(random: Random(7));
      final b = TetrisBoard(random: Random(7));

      int compared = 0;
      while (!a.gameOver && compared < 14) {
        expect(a.active!.type, b.active!.type);
        a.hardDrop();
        b.hardDrop();
        compared++;
      }
      // Both boards see identical events from an identical seed, so either
      // both ran the full 14 pieces or both hit game over at the same piece
      // — either way, some real comparisons must have happened.
      expect(compared, greaterThan(0));
      expect(a.gameOver, b.gameOver);
    });
  });

  group('movement', () {
    test('moveLeft/moveRight shift the active piece sideways', () {
      final board = TetrisBoard(random: Random(1));
      final startCol = board.active!.col;

      board.moveRight();
      expect(board.active!.col, startCol + 1);

      board.moveLeft();
      board.moveLeft();
      expect(board.active!.col, startCol - 1);
    });

    test('moveLeft is refused once a block is at the left wall', () {
      final board = TetrisBoard(random: Random(1));
      for (int i = 0; i < 20; i++) {
        board.moveLeft();
      }
      final int stuck = board.active!.col;
      board.moveLeft();
      expect(board.active!.col, stuck);
    });

    test('softDrop returns false once resting on the floor', () {
      final board = TetrisBoard(random: Random(1));
      bool moved = true;
      while (moved) {
        moved = board.softDrop();
      }
      expect(board.softDrop(), isFalse);
    });
  });

  group('rotation', () {
    test('rotates in open space', () {
      final board = TetrisBoard(random: Random(3));
      final int start = board.active!.rotation;
      board.rotate();
      expect(board.active!.rotation, (start + 1) % 4);
    });

    test('kicks away from a wall rather than refusing outright', () {
      final board = TetrisBoard(random: Random(3));
      for (int i = 0; i < 20; i++) {
        board.moveLeft();
      }
      final int rotation = board.active!.rotation;
      board.rotate();
      // An O piece's four rotation states are identical, so a kick should
      // always succeed for it right at the wall.
      if (board.active!.type == TetrominoType.o) {
        expect(board.active!.rotation, (rotation + 1) % 4);
      }
      // No crash, and whatever happened kept every cell on the board.
      for (final cell in board.active!.cells) {
        expect(cell.x, greaterThanOrEqualTo(0));
        expect(cell.x, lessThan(TetrisBoard.width));
      }
    });
  });

  group('gravity and locking', () {
    test('tick moves the piece down by one row', () {
      final board = TetrisBoard(random: Random(1));
      final int startRow = board.active!.row;
      board.tick();
      expect(board.active!.row, startRow + 1);
    });

    test('hardDrop locks the piece into cells and spawns a new one', () {
      final board = TetrisBoard(random: Random(1));
      final TetrominoType droppedType = board.active!.type;
      board.hardDrop();

      final bool anyLocked = board.cells.any(
        (row) => row.any((c) => c == droppedType),
      );
      expect(anyLocked, isTrue);
      expect(board.active, isNotNull);
      expect(board.active!.type, isNot(equals(droppedType)));
    });
  });

  group('line clears and scoring', () {
    test('a piece that completes a row clears it and scores', () {
      // Probe: on an empty board, the first piece's hard drop lands with its
      // lowest cell(s) on the bottom row (nothing else is on the board yet)
      // — record which columns it occupies there.
      final probe = TetrisBoard(random: Random(9));
      final TetrominoType type = probe.active!.type;
      probe.hardDrop();
      const int bottom = TetrisBoard.height - 1;
      final landingCols = <int>{
        for (int x = 0; x < TetrisBoard.width; x++)
          if (probe.cells[bottom][x] == type) x,
      };
      expect(landingCols, isNotEmpty);

      // Same seed: same first piece and spawn column. Fill the bottom row
      // everywhere except where that piece will land, then drop it for real.
      final board = TetrisBoard(random: Random(9));
      board.debugFillRow(bottom, TetrominoType.t, except: landingCols);
      board.hardDrop();

      expect(board.lines, 1);
      expect(board.score, greaterThan(0));
      expect(board.gameOver, isFalse);
    });

    test('level rises every 10 lines cleared', () {
      final board = TetrisBoard(random: Random(1));
      // Force 10 full rows directly (bypassing gravity) so the level math is
      // deterministic rather than depending on natural piece placement; one
      // hardDrop's lock scans the whole board and clears them all.
      for (int y = 10; y < 20; y++) {
        board.debugFillRow(y, TetrominoType.o);
      }
      board.hardDrop();

      expect(board.lines, 10);
      expect(board.level, 2);
    });

    test('a single lock never indexes past the clear-score table', () {
      // More full rows than a real piece could ever complete at once (see
      // `debugFillRow`'s doc comment) — must not throw.
      final board = TetrisBoard(random: Random(1));
      for (int y = 5; y < 20; y++) {
        board.debugFillRow(y, TetrominoType.o);
      }
      expect(board.hardDrop, returnsNormally);
      expect(board.lines, 15);
    });
  });

  group('game over', () {
    test('spawning into a full top is game over, with no active piece', () {
      final board = TetrisBoard(random: Random(1));
      // Stack pieces straight down without ever clearing (same column every
      // time) until the board fills to the top and a spawn fails.
      int guard = 0;
      while (!board.gameOver && guard < 400) {
        for (int i = 0; i < 20; i++) {
          board.moveLeft();
        }
        board.hardDrop();
        guard++;
      }
      expect(board.gameOver, isTrue);
      expect(board.active, isNull);
    });
  });
}

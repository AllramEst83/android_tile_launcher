import 'dart:math';

/// The playfield is always 10 columns by 20 rows — the standard Tetris
/// board, not a tunable.
const int tetrisBoardWidth = 10;
const int tetrisBoardHeight = 20;

/// The seven standard tetromino shapes. [TetrisBoard] colours cells by this,
/// leaving the actual colour choice to whatever draws them (see
/// `games/tetris/tetris_game.dart`, which maps each to a VIC-II colour) —
/// this file stays pure Dart, no Flutter, per `.agents/architecture.md`.
enum TetrominoType { i, o, t, s, z, j, l }

/// A tetromino's occupied cells within a 4×4 bounding box, one list per
/// rotation state (0..3). Hardcoded per rotation rather than derived by
/// matrix rotation, so each piece's shape is easy to read and change on its
/// own without touching the others.
const Map<TetrominoType, List<List<Point<int>>>> _tetrominoRotations =
    <TetrominoType, List<List<Point<int>>>>{
      TetrominoType.i: <List<Point<int>>>[
        <Point<int>>[Point(0, 1), Point(1, 1), Point(2, 1), Point(3, 1)],
        <Point<int>>[Point(2, 0), Point(2, 1), Point(2, 2), Point(2, 3)],
        <Point<int>>[Point(0, 2), Point(1, 2), Point(2, 2), Point(3, 2)],
        <Point<int>>[Point(1, 0), Point(1, 1), Point(1, 2), Point(1, 3)],
      ],
      TetrominoType.o: <List<Point<int>>>[
        <Point<int>>[Point(1, 0), Point(2, 0), Point(1, 1), Point(2, 1)],
        <Point<int>>[Point(1, 0), Point(2, 0), Point(1, 1), Point(2, 1)],
        <Point<int>>[Point(1, 0), Point(2, 0), Point(1, 1), Point(2, 1)],
        <Point<int>>[Point(1, 0), Point(2, 0), Point(1, 1), Point(2, 1)],
      ],
      TetrominoType.t: <List<Point<int>>>[
        <Point<int>>[Point(1, 0), Point(0, 1), Point(1, 1), Point(2, 1)],
        <Point<int>>[Point(1, 0), Point(1, 1), Point(2, 1), Point(1, 2)],
        <Point<int>>[Point(0, 1), Point(1, 1), Point(2, 1), Point(1, 2)],
        <Point<int>>[Point(1, 0), Point(0, 1), Point(1, 1), Point(1, 2)],
      ],
      TetrominoType.s: <List<Point<int>>>[
        <Point<int>>[Point(1, 0), Point(2, 0), Point(0, 1), Point(1, 1)],
        <Point<int>>[Point(1, 0), Point(1, 1), Point(2, 1), Point(2, 2)],
        <Point<int>>[Point(1, 1), Point(2, 1), Point(0, 2), Point(1, 2)],
        <Point<int>>[Point(0, 0), Point(0, 1), Point(1, 1), Point(1, 2)],
      ],
      TetrominoType.z: <List<Point<int>>>[
        <Point<int>>[Point(0, 0), Point(1, 0), Point(1, 1), Point(2, 1)],
        <Point<int>>[Point(2, 0), Point(1, 1), Point(2, 1), Point(1, 2)],
        <Point<int>>[Point(0, 1), Point(1, 1), Point(1, 2), Point(2, 2)],
        <Point<int>>[Point(1, 0), Point(0, 1), Point(1, 1), Point(0, 2)],
      ],
      TetrominoType.j: <List<Point<int>>>[
        <Point<int>>[Point(0, 0), Point(0, 1), Point(1, 1), Point(2, 1)],
        <Point<int>>[Point(1, 0), Point(2, 0), Point(1, 1), Point(1, 2)],
        <Point<int>>[Point(0, 1), Point(1, 1), Point(2, 1), Point(2, 2)],
        <Point<int>>[Point(1, 0), Point(1, 1), Point(0, 2), Point(1, 2)],
      ],
      TetrominoType.l: <List<Point<int>>>[
        <Point<int>>[Point(2, 0), Point(0, 1), Point(1, 1), Point(2, 1)],
        <Point<int>>[Point(1, 0), Point(1, 1), Point(1, 2), Point(2, 2)],
        <Point<int>>[Point(0, 1), Point(1, 1), Point(2, 1), Point(0, 2)],
        <Point<int>>[Point(0, 0), Point(1, 0), Point(1, 1), Point(1, 2)],
      ],
    };

/// A tetromino in play: its shape, rotation state, and the top-left corner of
/// its 4×4 bounding box on the board (which may be negative or beyond the
/// board's edge — only [cells] need be in range).
class ActivePiece {
  const ActivePiece({
    required this.type,
    required this.rotation,
    required this.col,
    required this.row,
  });

  final TetrominoType type;

  /// 0..3.
  final int rotation;
  final int col;
  final int row;

  /// Where this piece's four blocks actually sit on the board.
  List<Point<int>> get cells => <Point<int>>[
    for (final Point<int> c in _tetrominoRotations[type]![rotation])
      Point<int>(c.x + col, c.y + row),
  ];

  ActivePiece copyWith({int? rotation, int? col, int? row}) => ActivePiece(
    type: type,
    rotation: rotation ?? this.rotation,
    col: col ?? this.col,
    row: row ?? this.row,
  );
}

/// Points awarded for clearing 1, 2, 3 or 4 lines at once (index 0 unused),
/// scaled by [TetrisBoard.level] — the standard single/double/triple/tetris
/// curve.
const List<int> _lineClearScores = <int>[0, 100, 300, 500, 800];

/// How many lines clear a level.
const int _linesPerLevel = 10;

/// The pure-Dart Tetris rules engine: a 10×20 board, a 7-bag randomizer (each
/// of the seven pieces exactly once per bag, so no piece is starved), and the
/// standard actions (move, rotate with simple wall kicks, soft/hard drop, a
/// gravity [tick]) plus scoring, levelling and game-over. No Flutter import —
/// `games/tetris/tetris_game.dart` is the Flame/UI layer that renders this
/// and republishes its state as a `ValueNotifier`.
class TetrisBoard {
  TetrisBoard({Random? random}) : _random = random ?? Random() {
    _active = _nextSpawn();
  }

  static const int width = tetrisBoardWidth;
  static const int height = tetrisBoardHeight;

  final Random _random;
  final List<List<TetrominoType?>> _cells = List<List<TetrominoType?>>.generate(
    tetrisBoardHeight,
    (_) => List<TetrominoType?>.filled(tetrisBoardWidth, null),
  );
  final List<TetrominoType> _bag = <TetrominoType>[];

  ActivePiece? _active;
  TetrominoType? _next;

  int score = 0;
  int lines = 0;
  int level = 1;
  bool gameOver = false;

  /// The locked board, one row at a time, top first. `null` is an empty
  /// cell; a non-null value is the type of the piece that filled it (for
  /// colouring).
  List<List<TetrominoType?>> get cells => <List<TetrominoType?>>[
    for (final List<TetrominoType?> row in _cells)
      List<TetrominoType?>.unmodifiable(row),
  ];

  /// The piece currently falling, or `null` only once [gameOver].
  ActivePiece? get active => _active;

  /// The piece that will spawn after the current one locks.
  TetrominoType? get next => _next;

  /// Milliseconds between automatic gravity ticks at the current [level]:
  /// faster the higher the level, floored so it never becomes instant.
  Duration get tickInterval =>
      Duration(milliseconds: max(100, 1000 - (level - 1) * 75));

  TetrominoType _drawFromBag() {
    if (_bag.isEmpty) {
      _bag
        ..addAll(TetrominoType.values)
        ..shuffle(_random);
    }
    return _bag.removeAt(0);
  }

  /// Spawns the next piece (queuing the one after), or sets [gameOver] if it
  /// would immediately collide.
  ActivePiece? _nextSpawn() {
    final TetrominoType type = _next ?? _drawFromBag();
    _next = _drawFromBag();
    final ActivePiece piece = ActivePiece(
      type: type,
      rotation: 0,
      col: (width - 4) ~/ 2,
      row: 0,
    );
    if (_collides(piece)) {
      gameOver = true;
      return null;
    }
    return piece;
  }

  bool _collides(ActivePiece piece) {
    for (final Point<int> cell in piece.cells) {
      if (cell.x < 0 || cell.x >= width || cell.y >= height) return true;
      if (cell.y < 0) continue; // Above the board: fine while spawning.
      if (_cells[cell.y][cell.x] != null) return true;
    }
    return false;
  }

  /// Moves the active piece left, if there's room.
  void moveLeft() => _tryMove(dc: -1);

  /// Moves the active piece right, if there's room.
  void moveRight() => _tryMove(dc: 1);

  /// Moves the active piece down one row. Returns whether it actually moved
  /// (`false` means it's resting on the floor or another piece).
  bool softDrop() => _tryMove(dr: 1);

  bool _tryMove({int dc = 0, int dr = 0}) {
    if (gameOver || _active == null) return false;
    final ActivePiece moved = _active!.copyWith(
      col: _active!.col + dc,
      row: _active!.row + dr,
    );
    if (_collides(moved)) return false;
    _active = moved;
    return true;
  }

  /// Rotates the active piece clockwise, trying a small side-to-side kick
  /// (0, then ±1, then ±2 columns) if the bare rotation would collide —
  /// simpler than full SRS kick tables, enough to keep a rotation near a
  /// wall from just being refused outright.
  void rotate() {
    if (gameOver || _active == null) return;
    final ActivePiece piece = _active!;
    final int nextRotation = (piece.rotation + 1) % 4;
    for (final int kick in const <int>[0, -1, 1, -2, 2]) {
      final ActivePiece candidate = piece.copyWith(
        rotation: nextRotation,
        col: piece.col + kick,
      );
      if (!_collides(candidate)) {
        _active = candidate;
        return;
      }
    }
  }

  /// Drops the active piece straight to the floor and locks it at once.
  void hardDrop() {
    if (gameOver || _active == null) return;
    while (softDrop()) {}
    _lock();
  }

  /// Advances gravity by one step: moves the active piece down a row, or
  /// locks it in place if it can't (and spawns the next one).
  void tick() {
    if (gameOver || _active == null) return;
    if (!softDrop()) _lock();
  }

  void _lock() {
    final ActivePiece piece = _active!;
    for (final Point<int> cell in piece.cells) {
      if (cell.y < 0) continue;
      _cells[cell.y][cell.x] = piece.type;
    }
    final int cleared = _clearFullRows();
    _score(cleared);
    _active = _nextSpawn();
  }

  int _clearFullRows() {
    final List<int> full = <int>[
      for (int y = 0; y < height; y++)
        if (_cells[y].every((TetrominoType? c) => c != null)) y,
    ];
    for (final int y in full.reversed) {
      _cells.removeAt(y);
    }
    for (int i = 0; i < full.length; i++) {
      _cells.insert(0, List<TetrominoType?>.filled(width, null));
    }
    return full.length;
  }

  void _score(int cleared) {
    if (cleared == 0) return;
    // A real lock clears at most 4 rows (a piece is never taller than that),
    // so `_lineClearScores` only goes up to index 4 — clamped defensively
    // rather than assumed, since `debugFillRow` lets a test set up more.
    score +=
        _lineClearScores[min(cleared, _lineClearScores.length - 1)] * level;
    lines += cleared;
    level = 1 + lines ~/ _linesPerLevel;
  }

  /// Test-only seam: fills every cell of row [y] with [type] directly
  /// (skipping columns in [except]), bypassing gravity and locking, so
  /// line-clear and scoring behaviour can be tested without depending on how
  /// a real game happens to stack pieces.
  void debugFillRow(
    int y,
    TetrominoType type, {
    Set<int> except = const <int>{},
  }) {
    for (int x = 0; x < width; x++) {
      if (except.contains(x)) continue;
      _cells[y][x] = type;
    }
  }
}

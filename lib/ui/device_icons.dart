import 'package:android_tile_launcher/ui/pixel_icon.dart';
import 'package:flutter/widgets.dart';

/// The grid these icons are drawn on. Coarser than [WeatherIcon]'s 12: these
/// sit beside a meter's label at a fraction of that icon's usual size, and
/// fewer, bigger blocks read better small than the same detail shrunk past
/// the point it can still be told apart.
const int _grid = 8;

/// A battery-cell picture, its charge level filled bottom-up like the real
/// thing — not a discrete "empty/half/full" set of bitmaps, since the level
/// itself is continuous. `null` (unknown) draws the outline only, the same
/// way [formatBattery] shows dashes rather than a number it doesn't have.
class BatteryIcon extends StatelessWidget {
  const BatteryIcon({
    super.key,
    required this.fraction,
    required this.size,
    required this.color,
  });

  /// 0..1, or `null` if unknown.
  final double? fraction;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => PixelIcon(
    rows: _batteryBitmap(fraction),
    size: size,
    color: color,
    gridSize: _grid,
  );
}

/// A disk picture beside the storage meter — a squat cylinder, the shape a
/// drive icon has had since long before this launcher's own C64.
class DiskIcon extends StatelessWidget {
  const DiskIcon({super.key, required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      PixelIcon(rows: _diskBitmap, size: size, color: color, gridSize: _grid);
}

/// A memory chip picture beside the RAM meter — a body with pins top and
/// bottom, the same way a schematic draws one.
class MemoryIcon extends StatelessWidget {
  const MemoryIcon({super.key, required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      PixelIcon(rows: _memoryBitmap, size: size, color: color, gridSize: _grid);
}

// The nub sits in the middle two columns; the body's border is its outer
// ring; the interior (rows 2-6, columns 1-6) is what the charge level fills.
const int _bodyTop = 1;
const int _bodyBottom = 7;
const int _interiorTop = 2;
const int _interiorBottom = 6;
const int _interiorLeft = 1;
const int _interiorRight = 6;

List<String> _batteryBitmap(double? fraction) {
  final List<List<String>> grid = List<List<String>>.generate(
    _grid,
    (_) => List<String>.filled(_grid, '.'),
  );
  void fill(int y, int x) => grid[y][x] = '#';

  fill(0, 3);
  fill(0, 4);
  for (int x = 0; x < _grid; x++) {
    fill(_bodyTop, x);
    fill(_bodyBottom, x);
  }
  for (int y = _bodyTop; y <= _bodyBottom; y++) {
    fill(y, 0);
    fill(y, _grid - 1);
  }

  if (fraction != null) {
    final int interiorRows = _interiorBottom - _interiorTop + 1;
    final int filled = (fraction.clamp(0.0, 1.0) * interiorRows).round();
    for (int i = 0; i < filled; i++) {
      final int y = _interiorBottom - i;
      for (int x = _interiorLeft; x <= _interiorRight; x++) {
        fill(y, x);
      }
    }
  }

  return <String>[for (final List<String> row in grid) row.join()];
}

const List<String> _diskBitmap = <String>[
  '.######.',
  '#......#',
  '#......#',
  '#......#',
  '#......#',
  '.######.',
  '........',
  '........',
];

const List<String> _memoryBitmap = <String>[
  '.#.##.#.',
  '########',
  '#......#',
  '#......#',
  '#......#',
  '#......#',
  '########',
  '.#.##.#.',
];

import 'package:android_tile_launcher/model/weather.dart';
import 'package:flutter/widgets.dart';

/// A 12x12 pixel-block picture of the sky in one colour: a sun, a cloud, rain
/// and so on. Drawn in code from the bitmaps below, so it takes the tile's ink
/// and needs no asset; hard-edged blocks, like the rest of the look.
class WeatherIcon extends StatelessWidget {
  const WeatherIcon({
    super.key,
    required this.kind,
    required this.size,
    required this.color,
  });

  final WeatherKind kind;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _PixelPainter(_bitmaps[kind]!, color)),
      ),
    );
  }
}

class _PixelPainter extends CustomPainter {
  const _PixelPainter(this.rows, this.color);

  final List<String> rows;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final double cell = size.shortestSide / _grid;
    // No anti-aliasing: it would leave hairline seams between blocks.
    final Paint paint = Paint()
      ..color = color
      ..isAntiAlias = false;
    for (int y = 0; y < rows.length; y++) {
      for (int x = 0; x < rows[y].length; x++) {
        if (rows[y][x] != '#') continue;
        canvas.drawRect(
          Rect.fromLTWH(x * cell, y * cell, cell + 0.5, cell + 0.5),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_PixelPainter old) =>
      old.rows != rows || old.color != color;
}

const int _grid = 12;

const List<String> _cloudTop = <String>[
  '....###.....',
  '..#######...',
  '.#########..',
  '###########.',
  '############',
  '.##########.',
];

const List<String> _blank = <String>['............'];

/// [_cloudTop] pushed down by [before] blank rows, padded to the grid.
List<String> _cloudAt(int before) => <String>[
  for (int i = 0; i < before; i++) ..._blank,
  ..._cloudTop,
  for (int i = before + _cloudTop.length; i < _grid; i++) ..._blank,
];

/// A cloud at the top with [under] (six rows) beneath it.
List<String> _cloudOver(List<String> under) => <String>[..._cloudTop, ...under];

final Map<WeatherKind, List<String>> _bitmaps = <WeatherKind, List<String>>{
  WeatherKind.clear: const <String>[
    '.....##.....',
    '.#...##...#.',
    '..#......#..',
    '....####....',
    '...######...',
    '##.######.##',
    '##.######.##',
    '...######...',
    '....####....',
    '..#......#..',
    '.#...##...#.',
    '.....##.....',
  ],
  WeatherKind.partlyCloudy: const <String>[
    '.........#..',
    '.......#...#',
    '........###.',
    '......#.####',
    '...###..###.',
    '.#######...#',
    '#########...',
    '###########.',
    '############',
    '.##########.',
    '............',
    '............',
  ],
  WeatherKind.cloudy: _cloudAt(3),
  WeatherKind.fog: <String>[
    ..._blank,
    ..._cloudTop,
    ..._blank,
    '.##########.',
    ..._blank,
    '..########..',
    ..._blank,
  ],
  WeatherKind.drizzle: _cloudOver(const <String>[
    '............',
    '..#..#..#...',
    '............',
    '.#..#..#....',
    '............',
    '............',
  ]),
  WeatherKind.rain: _cloudOver(const <String>[
    '............',
    '..#..#..#...',
    '.#..#..#....',
    '............',
    '..#..#..#...',
    '.#..#..#....',
  ]),
  WeatherKind.snow: _cloudOver(const <String>[
    '............',
    '.#...#...#..',
    '............',
    '...#...#....',
    '............',
    '.#...#...#..',
  ]),
  WeatherKind.thunder: _cloudOver(const <String>[
    '.....###....',
    '....###.....',
    '...#####....',
    '.....##.....',
    '....##......',
    '...#........',
  ]),
};

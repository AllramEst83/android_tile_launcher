import 'package:android_tile_launcher/ui/pixel_icon.dart';
import 'package:flutter/widgets.dart';

/// A QR code picture, for the QR scanner tile: the three corner finder
/// squares a real one has, with a scatter of modules between them.
class QrCodeIcon extends StatelessWidget {
  const QrCodeIcon({super.key, required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      PixelIcon(rows: _qrBitmap, size: size, color: color);
}

const List<String> _qrBitmap = <String>[
  '#####..#####',
  '#...#..#...#',
  '#.#.#..#.#.#',
  '#...#..#...#',
  '#####..#####',
  '............',
  '..#..##..#..',
  '#####..#.#..',
  '#...#....##.',
  '#.#.#..#..#.',
  '#...#.#.....',
  '#####..##.#.',
];

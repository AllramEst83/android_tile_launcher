import 'package:android_tile_launcher/ui/pixel_icon.dart';
import 'package:flutter/widgets.dart';

/// A folder picture, for a directory row in the file explorer.
class FolderIcon extends StatelessWidget {
  const FolderIcon({super.key, required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      PixelIcon(rows: _folderBitmap, size: size, color: color);
}

/// A document picture, for a file row — three ruled lines on a page, the
/// same shorthand paper has had since long before this launcher's own C64.
class DocumentIcon extends StatelessWidget {
  const DocumentIcon({super.key, required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      PixelIcon(rows: _documentBitmap, size: size, color: color);
}

/// A trash-can picture, for a row's delete control — a lid, a bin inset
/// under it, and two ribs, the same shorthand a delete action has had since
/// long before this launcher's own C64. Coarser (8x8) than the folder and
/// document pictures: it sits inside a small button, not beside a name.
class TrashIcon extends StatelessWidget {
  const TrashIcon({super.key, required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      PixelIcon(rows: _trashBitmap, size: size, color: color, gridSize: 8);
}

const List<String> _folderBitmap = <String>[
  '..####......',
  '.##########.',
  '#..........#',
  '#..........#',
  '#..........#',
  '#..........#',
  '.##########.',
  '............',
  '............',
  '............',
  '............',
  '............',
];

const List<String> _documentBitmap = <String>[
  '.##########.',
  '#..........#',
  '#.########.#',
  '#..........#',
  '#.########.#',
  '#..........#',
  '#.########.#',
  '#..........#',
  '############',
  '............',
  '............',
  '............',
];

const List<String> _trashBitmap = <String>[
  '..####..',
  '.######.',
  '..####..',
  '..#..#..',
  '..#..#..',
  '..#..#..',
  '..####..',
  '........',
];

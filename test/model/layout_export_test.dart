import 'dart:convert';

import 'package:android_tile_launcher/model/c64_colour.dart';
import 'package:android_tile_launcher/model/layout_export.dart';
import 'package:android_tile_launcher/model/pinned_tile.dart';
import 'package:android_tile_launcher/model/settings.dart';
import 'package:android_tile_launcher/model/tile.dart';
import 'package:android_tile_launcher/model/tile_size.dart';
import 'package:flutter_test/flutter_test.dart';

final List<PinnedTile> _tiles = <PinnedTile>[
  PinnedTile.app(packageName: 'com.example.maps', index: 0),
  PinnedTile.system(kind: TileKind.clock, index: 1),
  PinnedTile.contact(key: 'k1', name: 'Anna', index: 2),
];

const LauncherSettings _settings = LauncherSettings(
  theme: ThemeVariant.beige,
  columns: 6,
  gap: GridGap.tight,
);

void main() {
  group('exportLayout', () {
    test('is one line of JSON that says what it is', () {
      final String text = exportLayout(tiles: _tiles, settings: _settings);

      expect(text.contains('\n'), isFalse);
      final Map<String, Object?> json =
          jsonDecode(text) as Map<String, Object?>;
      expect(json['format'], layoutFormat);
      expect(json['version'], layoutVersion);
      expect((json['tiles']! as List).length, 3);
    });

    test('an empty layout is still a layout', () {
      final String text = exportLayout(
        tiles: const <PinnedTile>[],
        settings: const LauncherSettings(),
      );

      expect(parseLayout(text), isA<LayoutImported>());
    });
  });

  group('parseLayout', () {
    test('reads back what exportLayout wrote, in order', () {
      final LayoutImport result = parseLayout(
        exportLayout(tiles: _tiles, settings: _settings),
      );

      expect(result, isA<LayoutImported>());
      final LayoutImported imported = result as LayoutImported;
      expect(imported.tiles, _tiles);
      expect(imported.settings, _settings);
      expect(imported.skipped, 0);
    });

    test('keeps a contact tile\'s name', () {
      final LayoutImported imported = parseLayout(
        exportLayout(tiles: _tiles, settings: _settings),
      ) as LayoutImported;

      expect(imported.tiles.last.label, 'Anna');
    });

    test('tolerates spaces and a newline round the text', () {
      final String text = exportLayout(tiles: _tiles, settings: _settings);

      expect(parseLayout('  \n$text\n  '), isA<LayoutImported>());
    });

    test('nothing, or only spaces, is nothing to import', () {
      expect((parseLayout(null) as LayoutRejected).reason, 'nothing to import');
      expect(
        (parseLayout('   ') as LayoutRejected).reason,
        'nothing to import',
      );
    });

    test('text that is not JSON, or not a layout, is rejected', () {
      for (final String text in <String>[
        'hello',
        '[1, 2]',
        '{}',
        '{"tiles": []}',
        '{"format": "something-else", "version": 1, "tiles": []}',
        '{"format": "$layoutFormat", "version": 1}',
        '{"format": "$layoutFormat", "version": "1", "tiles": []}',
        '{"format": "$layoutFormat", "version": 0, "tiles": []}',
        '{"format": "$layoutFormat", "version": 1, "tiles": {}}',
      ]) {
        expect(parseLayout(text), isA<LayoutRejected>(), reason: text);
      }
    });

    test('a layout from a newer launcher is refused, not misread', () {
      final LayoutRejected rejected = parseLayout(
        '{"format": "$layoutFormat", "version": ${layoutVersion + 1}, '
        '"tiles": []}',
      ) as LayoutRejected;

      expect(rejected.reason, 'made by a newer launcher');
    });

    test('a tile that cannot be read is skipped and counted', () {
      final String text = jsonEncode(<String, Object?>{
        'format': layoutFormat,
        'version': 1,
        'tiles': <Object?>[
          _tiles.first.toJson(),
          <String, Object?>{'id': 'x', 'kind': 'spreadsheet', 'size': 'small'},
          'nonsense',
          _tiles[1].toJson(),
        ],
      });

      final LayoutImported imported = parseLayout(text) as LayoutImported;

      expect(imported.tiles, <PinnedTile>[_tiles.first, _tiles[1]]);
      expect(imported.skipped, 2);
    });

    test('a tile listed twice keeps its first place', () {
      final PinnedTile bigger = _tiles.first.copyWith(size: TileSize.large);
      final String text = jsonEncode(<String, Object?>{
        'format': layoutFormat,
        'version': 1,
        'tiles': <Object?>[_tiles.first.toJson(), bigger.toJson()],
      });

      final LayoutImported imported = parseLayout(text) as LayoutImported;

      expect(imported.tiles, <PinnedTile>[_tiles.first]);
    });

    test('missing or damaged settings are the defaults', () {
      final LayoutImported imported = parseLayout(
        '{"format": "$layoutFormat", "version": 1, "tiles": [], '
        '"settings": {"theme": "neon", "columns": 9}}',
      ) as LayoutImported;

      expect(imported.settings, const LauncherSettings());
    });

    test('colours and sizes survive', () {
      const PinnedTile tile = PinnedTile(
        id: 'com.example.a',
        size: TileSize.medium,
        colour: C64Colour.purple,
      );

      final LayoutImported imported = parseLayout(
        exportLayout(
          tiles: const <PinnedTile>[tile],
          settings: const LauncherSettings(),
        ),
      ) as LayoutImported;

      expect(imported.tiles.single, tile);
    });
  });
}

import 'dart:convert';

import 'package:android_tile_launcher/model/pinned_tile.dart';
import 'package:android_tile_launcher/model/settings.dart';

/// What a layout export says it is, so pasting anything else is recognised.
const String layoutFormat = 'tile-launcher-layout';

/// The version of the format [exportLayout] writes; [parseLayout] refuses a
/// higher one, which a newer launcher wrote and this one may misread.
const int layoutVersion = 1;

/// The home layout (the pinned tiles, in order, with their sizes and colours)
/// and the settings as one line of text, to keep or to move to another phone.
/// Apps are named by package, so an app that is not installed where the layout
/// is imported is simply a tile that opens nothing.
String exportLayout({
  required List<PinnedTile> tiles,
  required LauncherSettings settings,
}) => jsonEncode(<String, Object?>{
  'format': layoutFormat,
  'version': layoutVersion,
  'settings': settings.toJson(),
  'tiles': <Object?>[for (final PinnedTile tile in tiles) tile.toJson()],
});

sealed class LayoutImport {
  const LayoutImport();
}

/// A layout read from text: [tiles] in order, the [settings], and how many
/// entries in it could not be read ([skipped]: a malformed tile, or one of a
/// kind this launcher does not have).
class LayoutImported extends LayoutImport {
  const LayoutImported({
    required this.tiles,
    required this.settings,
    this.skipped = 0,
  });

  final List<PinnedTile> tiles;
  final LauncherSettings settings;
  final int skipped;
}

/// The text was not a layout this launcher can use; [reason] is short and
/// printable.
class LayoutRejected extends LayoutImport {
  const LayoutRejected(this.reason);

  final String reason;
}

/// [text] as a layout written by [exportLayout]. Never throws: anything else is
/// a [LayoutRejected], and within a good layout a tile that cannot be read is
/// skipped (and counted) rather than spoiling the rest. A tile named twice
/// keeps its first place.
LayoutImport parseLayout(String? text) {
  final String trimmed = (text ?? '').trim();
  if (trimmed.isEmpty) return const LayoutRejected('nothing to import');
  final Object? json;
  try {
    json = jsonDecode(trimmed);
  } on FormatException {
    return const LayoutRejected('that is not a launcher layout');
  }
  if (json is! Map || json['format'] != layoutFormat) {
    return const LayoutRejected('that is not a launcher layout');
  }
  final Object? version = json['version'];
  if (version is! int || version < 1) {
    return const LayoutRejected('that is not a launcher layout');
  }
  if (version > layoutVersion) {
    return const LayoutRejected('made by a newer launcher');
  }
  final Object? entries = json['tiles'];
  if (entries is! List) {
    return const LayoutRejected('that is not a launcher layout');
  }

  final List<PinnedTile> tiles = <PinnedTile>[];
  final Set<String> seen = <String>{};
  int skipped = 0;
  for (final Object? entry in entries) {
    final PinnedTile? tile = PinnedTile.fromJson(entry);
    if (tile == null) {
      skipped++;
    } else if (seen.add(tile.id)) {
      tiles.add(tile);
    }
  }
  return LayoutImported(
    tiles: tiles,
    settings: LauncherSettings.fromJson(json['settings']),
    skipped: skipped,
  );
}

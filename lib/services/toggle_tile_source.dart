import 'package:android_tile_launcher/model/tile.dart';
import 'package:android_tile_launcher/model/tile_content.dart';
import 'package:android_tile_launcher/services/system_control_service.dart';
import 'package:android_tile_launcher/services/tile_source.dart';

/// One [TileSource] for every toggle kind (silent mode, vibration mode,
/// flashlight) — they all read the same shape, just [kind] and which
/// [SystemControlService] method it maps to differ.
class ToggleTileSource implements TileSource {
  const ToggleTileSource({required this.kind, required this.control});

  final TileKind kind;
  final SystemControlService control;

  @override
  Future<TileContent> read() async =>
      ToggleContent(on: await control.isOn(kind));
}

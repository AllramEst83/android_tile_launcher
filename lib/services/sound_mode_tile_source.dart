import 'package:android_tile_launcher/model/tile_content.dart';
import 'package:android_tile_launcher/services/system_control_service.dart';
import 'package:android_tile_launcher/services/tile_source.dart';

/// The sound tile's content: the ringer's current mode.
class SoundModeTileSource implements TileSource {
  const SoundModeTileSource({required this.control});

  final SystemControlService control;

  @override
  Future<TileContent> read() async =>
      SoundContent(mode: await control.soundMode());
}

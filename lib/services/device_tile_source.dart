import 'package:android_tile_launcher/model/tile_content.dart';
import 'package:android_tile_launcher/services/device_repository.dart';
import 'package:android_tile_launcher/services/tile_source.dart';

/// The device tile's content: the current battery and storage.
class DeviceTileSource implements TileSource {
  const DeviceTileSource({required this.repository});

  final DeviceRepository repository;

  @override
  Future<TileContent> read() async =>
      DeviceContent(status: await repository.status());
}

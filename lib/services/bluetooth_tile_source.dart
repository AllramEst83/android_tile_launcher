import 'package:android_tile_launcher/model/tile_content.dart';
import 'package:android_tile_launcher/services/bluetooth_service.dart';
import 'package:android_tile_launcher/services/tile_source.dart';

/// The Bluetooth tile's content: the adapter's state, read from
/// [BluetoothService].
class BluetoothTileSource implements TileSource {
  const BluetoothTileSource({required this.service});

  final BluetoothService service;

  @override
  Future<TileContent> read() async =>
      BluetoothTileContent(status: await service.status());
}

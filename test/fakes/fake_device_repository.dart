import 'package:android_tile_launcher/model/device_status.dart';
import 'package:android_tile_launcher/services/device_repository.dart';

class FakeDeviceRepository implements DeviceRepository {
  FakeDeviceRepository([this.current = const DeviceStatus()]);

  DeviceStatus current;
  int calls = 0;

  @override
  Future<DeviceStatus> status() async {
    calls++;
    return current;
  }
}

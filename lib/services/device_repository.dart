import 'package:android_tile_launcher/model/device_status.dart';

/// Battery and storage, for the device tile. Queried fresh every call — both
/// change all the time — and never throws: what can't be read comes back
/// `null` in the [DeviceStatus].
abstract interface class DeviceRepository {
  Future<DeviceStatus> status();
}

import 'package:android_tile_launcher/model/byte_format.dart';
import 'package:android_tile_launcher/model/device_status.dart';

/// `87%`, `87% +` while charging, `--` when unknown.
String formatBattery(DeviceStatus status) {
  final int? percent = status.batteryPercent;
  if (percent == null) return '--';
  return status.charging ? '$percent% +' : '$percent%';
}

/// `42 GB FREE`, `812 MB FREE`, `--` when unknown. Decimal units, like
/// Android's own storage screen.
String formatStorageFree(DeviceStatus status) {
  final int? free = status.storageFreeBytes;
  if (free == null) return '--';
  return '${formatBytes(free)} FREE';
}

/// `2.1 GB FREE`, `--` when unknown — the same units and wording as
/// [formatStorageFree], for the same reason: what is available right now.
String formatMemoryAvailable(DeviceStatus status) {
  final int? available = status.memoryAvailableBytes;
  if (available == null) return '--';
  return '${formatBytes(available)} FREE';
}

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
  return '${_formatBytes(free)} FREE';
}

String _formatBytes(int bytes) {
  const int mb = 1000 * 1000;
  const int gb = 1000 * mb;
  if (bytes >= gb) {
    final double value = bytes / gb;
    return '${value.toStringAsFixed(value >= 100 ? 0 : 1)} GB';
  }
  return '${(bytes / mb).round()} MB';
}

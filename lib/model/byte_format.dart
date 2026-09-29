/// A byte count as the smallest unit that keeps it readable — `1.2 GB`,
/// `812 MB`, `340 KB`, `95 B` — decimal units, like Android's own storage
/// screen. Shared by the device tile's meters and the file explorer, rather
/// than each keeping its own copy: a device's free space is always big
/// enough to land in the MB/GB tiers this always had, but one file can be
/// any size, hence the KB/B tiers under them.
String formatBytes(int bytes) {
  const int kb = 1000;
  const int mb = 1000 * kb;
  const int gb = 1000 * mb;
  if (bytes >= gb) {
    final double value = bytes / gb;
    return '${value.toStringAsFixed(value >= 100 ? 0 : 1)} GB';
  }
  if (bytes >= mb) {
    return '${(bytes / mb).round()} MB';
  }
  if (bytes >= kb) {
    return '${(bytes / kb).round()} KB';
  }
  return '$bytes B';
}

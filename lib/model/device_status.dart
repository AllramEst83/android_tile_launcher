/// What the device tile shows: battery and internal storage. Every field can
/// be unknown — a platform query that fails leaves it `null` rather than
/// inventing a value.
class DeviceStatus {
  const DeviceStatus({
    this.batteryPercent,
    this.charging = false,
    this.storageFreeBytes,
    this.storageTotalBytes,
  });

  final int? batteryPercent;
  final bool charging;
  final int? storageFreeBytes;
  final int? storageTotalBytes;

  /// Battery charge as 0..1, or `null` if unknown.
  double? get batteryFraction {
    final int? percent = batteryPercent;
    return percent == null ? null : (percent / 100).clamp(0.0, 1.0);
  }

  /// Share of storage still free as 0..1, or `null` if unknown — the same
  /// direction as the battery: a fuller bar is more left.
  double? get storageFreeFraction {
    final int? free = storageFreeBytes;
    final int? total = storageTotalBytes;
    if (free == null || total == null || total <= 0) return null;
    return (free / total).clamp(0.0, 1.0);
  }

  @override
  bool operator ==(Object other) =>
      other is DeviceStatus &&
      other.batteryPercent == batteryPercent &&
      other.charging == charging &&
      other.storageFreeBytes == storageFreeBytes &&
      other.storageTotalBytes == storageTotalBytes;

  @override
  int get hashCode => Object.hash(
    batteryPercent,
    charging,
    storageFreeBytes,
    storageTotalBytes,
  );

  @override
  String toString() =>
      'DeviceStatus($batteryPercent%, charging: $charging, '
      '$storageFreeBytes/$storageTotalBytes free)';
}

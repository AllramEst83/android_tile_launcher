/// What the device tile shows: battery, internal storage and free memory.
/// Every field can be unknown — a platform query that fails leaves it `null`
/// rather than inventing a value.
class DeviceStatus {
  const DeviceStatus({
    this.batteryPercent,
    this.charging = false,
    this.storageFreeBytes,
    this.storageTotalBytes,
    this.memoryAvailableBytes,
    this.memoryTotalBytes,
  });

  final int? batteryPercent;
  final bool charging;
  final int? storageFreeBytes;
  final int? storageTotalBytes;

  /// RAM Android reports as available to new processes right now (not "free":
  /// Android keeps used RAM around to reopen an app faster, so this is the
  /// figure that actually says how much headroom there is), and the phone's
  /// total RAM.
  final int? memoryAvailableBytes;
  final int? memoryTotalBytes;

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

  /// Share of RAM still available as 0..1, or `null` if unknown — the same
  /// direction as storage: a fuller bar is more available.
  double? get memoryAvailableFraction {
    final int? available = memoryAvailableBytes;
    final int? total = memoryTotalBytes;
    if (available == null || total == null || total <= 0) return null;
    return (available / total).clamp(0.0, 1.0);
  }

  @override
  bool operator ==(Object other) =>
      other is DeviceStatus &&
      other.batteryPercent == batteryPercent &&
      other.charging == charging &&
      other.storageFreeBytes == storageFreeBytes &&
      other.storageTotalBytes == storageTotalBytes &&
      other.memoryAvailableBytes == memoryAvailableBytes &&
      other.memoryTotalBytes == memoryTotalBytes;

  @override
  int get hashCode => Object.hash(
    batteryPercent,
    charging,
    storageFreeBytes,
    storageTotalBytes,
    memoryAvailableBytes,
    memoryTotalBytes,
  );

  @override
  String toString() =>
      'DeviceStatus($batteryPercent%, charging: $charging, '
      '$storageFreeBytes/$storageTotalBytes free, '
      '$memoryAvailableBytes/$memoryTotalBytes memory)';
}

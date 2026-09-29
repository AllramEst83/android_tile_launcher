import 'package:android_tile_launcher/model/device_format.dart';
import 'package:android_tile_launcher/model/device_status.dart';
import 'package:android_tile_launcher/ui/device_icons.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';

/// The device tile's content: battery, free storage and free memory, each a
/// small icon, a label, a value and a flat bar (an outline filled to the
/// level — no gradients, in keeping with the rest of the look). Purely a
/// view; [status] is already read.
class DeviceTileContentView extends StatelessWidget {
  const DeviceTileContentView({
    super.key,
    required this.status,
    required this.ink,
  });

  final DeviceStatus status;
  final Color ink;

  static const double _iconSize = 14;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(TileMetrics.gutter / 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          _Meter(
            icon: BatteryIcon(
              fraction: status.batteryFraction,
              size: _iconSize,
              color: ink,
            ),
            label: 'BATTERY',
            value: formatBattery(status),
            fraction: status.batteryFraction,
            ink: ink,
          ),
          _Meter(
            icon: DiskIcon(size: _iconSize, color: ink),
            label: 'STORAGE',
            value: formatStorageFree(status),
            fraction: status.storageFreeFraction,
            ink: ink,
          ),
          _Meter(
            icon: MemoryIcon(size: _iconSize, color: ink),
            label: 'MEMORY',
            value: formatMemoryAvailable(status),
            fraction: status.memoryAvailableFraction,
            ink: ink,
          ),
        ],
      ),
    );
  }
}

class _Meter extends StatelessWidget {
  const _Meter({
    required this.icon,
    required this.label,
    required this.value,
    required this.fraction,
    required this.ink,
  });

  final Widget icon;
  final String label;
  final String value;
  final double? fraction;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    final TextStyle base = TextStyle(fontFamily: kPixelFontFamily, color: ink);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            icon,
            const SizedBox(width: 4),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '$label  $value',
                  style: base.copyWith(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 8,
          decoration: BoxDecoration(border: Border.all(color: ink)),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: fraction ?? 0,
            heightFactor: 1,
            child: ColoredBox(color: ink),
          ),
        ),
      ],
    );
  }
}

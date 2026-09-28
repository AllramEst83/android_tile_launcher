import 'package:android_tile_launcher/model/device_format.dart';
import 'package:android_tile_launcher/model/device_status.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';

/// The device tile's content: battery and free storage, each a small label, a
/// value and a flat bar (an outline filled to the level — no gradients, in
/// keeping with the rest of the look). Purely a view; [status] is already read.
class DeviceTileContentView extends StatelessWidget {
  const DeviceTileContentView({
    super.key,
    required this.status,
    required this.ink,
  });

  final DeviceStatus status;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(TileMetrics.gutter / 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          _Meter(
            label: 'BATTERY',
            value: formatBattery(status),
            fraction: status.batteryFraction,
            ink: ink,
          ),
          _Meter(
            label: 'STORAGE',
            value: formatStorageFree(status),
            fraction: status.storageFreeFraction,
            ink: ink,
          ),
        ],
      ),
    );
  }
}

class _Meter extends StatelessWidget {
  const _Meter({
    required this.label,
    required this.value,
    required this.fraction,
    required this.ink,
  });

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
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text('$label  $value', style: base.copyWith(fontSize: 12)),
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

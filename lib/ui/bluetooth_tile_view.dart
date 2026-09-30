import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/bluetooth_status.dart';
import 'package:android_tile_launcher/ui/state_tile_view.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';

/// Keys so tests can find the parts.
const Key bluetoothTileCountKey = ValueKey<String>('bluetooth-tile-count');
Key bluetoothTileRowKey(int index) =>
    ValueKey<String>('bluetooth-tile-row-$index');

/// The Bluetooth tile's content: the names of currently *connected* devices,
/// as many as the tile's own size fits (more as it grows, fewer — down to
/// just a count — as it shrinks). No ON/OFF or MANAGE DEVICES control ever
/// sits on the tile's own face: those, and the full device list (connected
/// and disconnected), live in the sheet a tap opens; every other state (off,
/// unsupported, unavailable, needing permission, or on with nothing
/// connected) falls back to the same short state line the tile always showed.
class BluetoothTileContentView extends StatelessWidget {
  const BluetoothTileContentView({
    super.key,
    required this.status,
    required this.ink,
    this.onTap,
  });

  final BluetoothStatus status;
  final Color ink;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final BluetoothStatus s = status;
    final List<PairedDevice> connected = s is BluetoothOn
        ? <PairedDevice>[
            for (final PairedDevice d in s.devices)
              if (d.connected) d,
          ]
        : const <PairedDevice>[];
    if (connected.isEmpty) {
      return StateTileContentView(
        label: Messages.bluetoothTitle,
        state: _stateLabel(status),
        ink: ink,
        onTap: onTap,
      );
    }
    final Widget body = SizedBox.expand(
      child: Padding(
        padding: const EdgeInsets.all(TileMetrics.gutter / 2),
        child: LayoutBuilder(
          builder: (context, constraints) =>
              // An outer `FittedBox`, the same "shrink the whole stack" fix
              // the device, mail, agenda and Text TV tiles all use: a
              // one-row-tall tile (or a large font-scale setting) leaves less
              // room than the row-fit math below assumes for, and this is
              // the safety net rather than an overflow.
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: constraints.maxWidth,
                  child: _ConnectedDevices(
                    devices: connected,
                    ink: ink,
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                  ),
                ),
              ),
        ),
      ),
    );
    if (onTap == null) return body;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: body,
    );
  }
}

String _stateLabel(BluetoothStatus status) => switch (status) {
  BluetoothOn() => Messages.bluetoothNoneConnected,
  BluetoothOff() => Messages.bluetoothOff,
  BluetoothUnsupported() => Messages.bluetoothUnsupported,
  BluetoothUnavailable() => Messages.bluetoothUnsupported,
  BluetoothNeedsPermission() => Messages.bluetoothOff,
};

/// The box one line of tile text sits in, as a multiple of its type size —
/// the same convention the mail and agenda tiles' own lists use.
const double _leading = 1.45;

TextStyle _text(Color ink, double size) => TextStyle(
  fontFamily: kPixelFontFamily,
  fontSize: size,
  height: _leading,
  color: ink,
);

class _ConnectedDevices extends StatelessWidget {
  const _ConnectedDevices({
    required this.devices,
    required this.ink,
    required this.width,
    required this.height,
  });

  final List<PairedDevice> devices;
  final Color ink;
  final double width;
  final double height;

  /// Below this width there is no room for a name to mean anything; a count
  /// is more honest than a truncated one.
  static const double _compact = 120;

  @override
  Widget build(BuildContext context) {
    if (width < _compact) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          FittedBox(
            key: bluetoothTileCountKey,
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text('${devices.length}', style: _text(ink, 28)),
          ),
          const SizedBox(height: 4),
          Text(Messages.bluetoothConnected, style: _text(ink, 9)),
        ],
      );
    }

    // Every fixed-height row below is sized off the FONT SIZE setting's
    // scaler, not the bare type size, the same as the mail and agenda tiles'
    // own lists — a `SizedBox` built from the unscaled size would still hold
    // the same physical height while the `Text` inside it rendered taller.
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final double rowHeight = scaler.scale(9) * _leading;
    final double headerHeight = scaler.scale(10) * _leading + 2;
    final int fit = ((height - headerHeight) / rowHeight).floor().clamp(
      1,
      devices.length,
    );
    final int hidden = devices.length - fit;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          height: headerHeight,
          child: Row(
            children: <Widget>[
              Text(Messages.bluetoothTitle, style: _text(ink, 10)),
              const Spacer(),
              if (hidden > 0) Text('+$hidden', style: _text(ink, 8)),
            ],
          ),
        ),
        for (final (int i, PairedDevice d) in devices.take(fit).indexed)
          SizedBox(
            key: bluetoothTileRowKey(i),
            height: rowHeight,
            child: Text(
              d.name.toUpperCase(),
              style: _text(ink, 9),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}

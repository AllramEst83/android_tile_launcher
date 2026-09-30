import 'dart:async';

import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/bluetooth_status.dart';
import 'package:android_tile_launcher/services/bluetooth_service.dart';
import 'package:android_tile_launcher/ui/pad_key.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';

/// Keys so tests can find the parts.
const Key bluetoothCloseKey = ValueKey<String>('bluetooth-close');
const Key bluetoothAllowKey = ValueKey<String>('bluetooth-allow');
const Key bluetoothToggleKey = ValueKey<String>('bluetooth-toggle');
Key bluetoothDeviceKey(String address) =>
    ValueKey<String>('bluetooth-device-$address');

/// What a tap on the Bluetooth tile opens: the adapter's state and, once it
/// is on, its paired devices filling the whole pane — a tap on one opens
/// Android's own device screen, since connecting or disconnecting a specific
/// device has no public API this app can call (see `BluetoothService`'s own
/// doc comment). While the adapter is off, the only thing on offer is a
/// button to Android's own toggle panel, for the same reason.
Future<void> showBluetoothSheet(
  BuildContext context, {
  required BluetoothService bluetooth,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: TileColors.canvas,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext sheetContext) =>
        _BluetoothSheet(bluetooth: bluetooth),
  );
}

class _BluetoothSheet extends StatefulWidget {
  const _BluetoothSheet({required this.bluetooth});

  final BluetoothService bluetooth;

  @override
  State<_BluetoothSheet> createState() => _BluetoothSheetState();
}

class _BluetoothSheetState extends State<_BluetoothSheet>
    with WidgetsBindingObserver {
  BluetoothStatus? _status;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_load());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Turning Bluetooth on/off and managing a device both happen on a screen
  // Android owns, not this one, so the only way to see the result is to
  // re-read once this app is in front again — the same pattern the settings
  // screen already uses for the Home-app role.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_load());
  }

  Future<void> _load() async {
    final BluetoothStatus status = await widget.bluetooth.status();
    if (!mounted) return;
    setState(() => _status = status);
  }

  Future<void> _allow() async {
    await widget.bluetooth.allow();
    unawaited(_load());
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(TileMetrics.margin),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // So the title row is not flush against the sheet's own top edge.
            const SizedBox(height: TileMetrics.gutter),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(Messages.bluetoothTitle, style: text.bodyMedium),
                ),
                SizedBox(
                  width: 48,
                  child: PadKey(
                    key: bluetoothCloseKey,
                    label: 'X',
                    height: 32,
                    fontSize: 12,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: TileMetrics.margin),
            Flexible(child: _body(text)),
          ],
        ),
      ),
    );
  }

  Widget _body(TextTheme text) {
    final BluetoothStatus? status = _status;
    if (status == null) {
      return Text(Messages.filesLoading, style: text.bodyMedium);
    }
    return switch (status) {
      BluetoothUnsupported() => Text(
        Messages.bluetoothUnsupportedBody,
        style: text.bodyMedium,
      ),
      BluetoothUnavailable(:final String reason) => Text(
        reason.toUpperCase(),
        style: text.bodyMedium,
      ),
      BluetoothNeedsPermission(:final bool permanent) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (permanent)
            Text(Messages.bluetoothAllowInSettings, style: text.bodyMedium)
          else
            PadKey(
              key: bluetoothAllowKey,
              label: Messages.bluetoothTapToAllow,
              height: 48,
              fontSize: 12,
              onTap: _allow,
            ),
        ],
      ),
      BluetoothOff() => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(Messages.bluetoothOffBody, style: text.bodyMedium),
          const SizedBox(height: TileMetrics.gutter),
          PadKey(
            key: bluetoothToggleKey,
            label: Messages.bluetoothToggle,
            height: 44,
            fontSize: 12,
            onTap: widget.bluetooth.openPanel,
          ),
        ],
      ),
      // No TURN ON/OFF or MANAGE DEVICES row here any more: the paired list
      // is the whole pane, filling whatever the sheet's own `Flexible` gives
      // it. Android's own device screen is still reachable — a tap on a
      // device opens it, the same place MANAGE DEVICES used to.
      BluetoothOn(:final List<PairedDevice> devices) =>
        devices.isEmpty
            ? Text(Messages.bluetoothNoDevices, style: text.bodyMedium)
            : ListView(
                children: <Widget>[
                  for (final PairedDevice device in devices)
                    _DeviceRow(
                      device: device,
                      // Connecting or disconnecting a specific device has no
                      // public API this app can call (see `BluetoothService`'s
                      // own doc comment) — Android's own device list is the
                      // actual destination.
                      onTap: widget.bluetooth.openSettings,
                    ),
                ],
              ),
    };
  }
}

class _DeviceRow extends StatelessWidget {
  const _DeviceRow({required this.device, required this.onTap});

  final PairedDevice device;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      key: bluetoothDeviceKey(device.address),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                device.name.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodySmall?.copyWith(
                  fontSize: 11,
                  color: TileColors.textBright,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              device.connected
                  ? Messages.bluetoothConnected
                  : Messages.bluetoothNotConnected,
              style: text.bodySmall?.copyWith(
                fontSize: 9,
                color: device.connected ? TileColors.accent : TileColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:android_tile_launcher/model/bluetooth_status.dart';
import 'package:android_tile_launcher/services/bluetooth_service.dart';
import 'package:android_tile_launcher/services/permission_service.dart';
import 'package:flutter/services.dart';

/// [BluetoothService] on the Kotlin `BluetoothChannelHandler` (the adapter
/// and its paired devices) and a [PermissionService] (`BLUETOOTH_CONNECT`,
/// asked only from [allow]) — the same read+permission split
/// `LiveAgendaRepository` uses for the calendar, rather than a second
/// repository layer for what is otherwise a small, flat interface.
class AndroidBluetoothService implements BluetoothService {
  AndroidBluetoothService({
    required this.permissions,
    this.channel = const MethodChannel(channelName),
  });

  static const String channelName =
      'com.codedbykay.android_tile_launcher/bluetooth';

  final MethodChannel channel;
  final PermissionService permissions;

  // Why the last request for access failed. Kept for the same reason
  // `LiveAgendaRepository._denied` is: Android reports "no access" the same
  // way whether it was never asked or was refused, and the tile re-reads
  // right after a tap, so without this it would say "tap to allow" again as
  // if nothing had happened.
  bool? _deniedPermanently;

  @override
  Future<BluetoothStatus> status() async {
    final Map<Object?, Object?>? raw;
    try {
      raw = await channel.invokeMapMethod<Object?, Object?>('status');
    } on PlatformException {
      return const BluetoothUnsupported();
    } on MissingPluginException {
      return const BluetoothUnsupported();
    }
    if (raw == null) return const BluetoothUnsupported();

    if (raw['supported'] != true) return const BluetoothUnsupported();
    if (raw['hasAccess'] != true) {
      return BluetoothNeedsPermission(permanent: _deniedPermanently ?? false);
    }
    _deniedPermanently = null;
    if (raw['enabled'] != true) return const BluetoothOff();

    final List<Object?> rawDevices = (raw['devices'] as List<Object?>?) ?? [];
    return BluetoothOn(<PairedDevice>[
      for (final Object? entry in rawDevices)
        if (entry is Map<Object?, Object?>)
          PairedDevice(
            name: entry['name'] as String? ?? '',
            address: entry['address'] as String? ?? '',
            connected: entry['connected'] == true,
          ),
    ]);
  }

  @override
  Future<void> allow() async {
    final PermissionStatus result = await permissions.request(
      AppPermission.bluetooth,
    );
    _deniedPermanently = switch (result) {
      PermissionStatus.granted => null,
      PermissionStatus.denied => false,
      PermissionStatus.permanentlyDenied => true,
    };
  }

  @override
  Future<void> openPanel() => _open('openPanel');

  @override
  Future<void> openSettings() => _open('openSettings');

  Future<void> _open(String method) async {
    try {
      await channel.invokeMethod<void>(method);
    } on PlatformException {
      // Nothing more to do: there is no fallback screen to open instead.
    } on MissingPluginException {
      // Same.
    }
  }
}

import 'package:android_tile_launcher/model/bluetooth_status.dart';
import 'package:android_tile_launcher/services/bluetooth_service.dart';
import 'package:android_tile_launcher/services/permission_service.dart';
import 'package:flutter/services.dart';

/// [BluetoothService] on the Kotlin `BluetoothChannelHandler` (the adapter
/// and its paired devices, plus a broadcast-backed [changes] stream for
/// pair/connect/adapter-state events) and a [PermissionService]
/// (`BLUETOOTH_CONNECT`, asked only from [allow]) — the same read+permission
/// split `LiveAgendaRepository` uses for the calendar, rather than a second
/// repository layer for what is otherwise a small, flat interface.
class AndroidBluetoothService implements BluetoothService {
  AndroidBluetoothService({
    required this.permissions,
    this.channel = const MethodChannel(channelName),
    EventChannel? eventChannel,
  }) : _eventChannel =
           eventChannel ?? const EventChannel('$channelName/events');

  static const String channelName =
      'com.codedbykay.android_tile_launcher/bluetooth';

  final MethodChannel channel;
  final PermissionService permissions;
  final EventChannel _eventChannel;

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
    } on PlatformException catch (error) {
      // A real native error, never reworded as "no radio": a phone that
      // plainly has Bluetooth once showed exactly that message, because this
      // used to treat every platform exception as [BluetoothUnsupported].
      return BluetoothUnavailable(error.message ?? 'could not read bluetooth');
    } on MissingPluginException {
      return const BluetoothUnavailable('bluetooth is not supported here');
    }
    if (raw == null) {
      return const BluetoothUnavailable('bluetooth did not answer');
    }

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

  /// Lazy and cached, not a bare getter: `EventChannel.receiveBroadcastStream`
  /// starts a fresh native listener on every call, and this is a broadcast
  /// stream that may well have more than one Dart subscriber (any tile this
  /// service is handed to); without caching, a second subscriber would
  /// register a second native receiver the first never gets torn down. A
  /// platform error (no listener on the native side) is swallowed, same as
  /// every other failure in this file: the poll interval still covers it.
  @override
  late final Stream<void> changes = _eventChannel
      .receiveBroadcastStream()
      .map((Object? _) {})
      .handleError((Object _) {});

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

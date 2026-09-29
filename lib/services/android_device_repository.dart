import 'package:android_tile_launcher/model/device_status.dart';
import 'package:android_tile_launcher/services/device_repository.dart';
import 'package:flutter/services.dart';

/// [DeviceRepository] backed by the Kotlin `DeviceChannelHandler`. This is the
/// only file that knows about the channel.
class AndroidDeviceRepository implements DeviceRepository {
  // Not `this._channel`: that would make the parameter name the private
  // `_channel`, which a test in another file could not pass by name.
  const AndroidDeviceRepository({
    MethodChannel channel = const MethodChannel(channelName),
    // ignore: prefer_initializing_formals
  }) : _channel = channel;

  static const String channelName =
      'com.codedbykay.android_tile_launcher/device';

  final MethodChannel _channel;

  @override
  Future<DeviceStatus> status() async {
    final Map<Object?, Object?>? raw;
    try {
      raw = await _channel.invokeMapMethod<Object?, Object?>('status');
    } on PlatformException {
      return const DeviceStatus();
    } on MissingPluginException {
      return const DeviceStatus();
    }
    if (raw == null) return const DeviceStatus();
    return DeviceStatus(
      batteryPercent: _int(raw['batteryPercent']),
      charging: raw['charging'] == true,
      storageFreeBytes: _int(raw['storageFreeBytes']),
      storageTotalBytes: _int(raw['storageTotalBytes']),
      memoryAvailableBytes: _int(raw['memoryAvailableBytes']),
      memoryTotalBytes: _int(raw['memoryTotalBytes']),
    );
  }

  static int? _int(Object? value) => value is int ? value : null;
}

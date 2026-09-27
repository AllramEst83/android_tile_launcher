import 'package:android_tile_launcher/model/tile.dart';
import 'package:android_tile_launcher/services/system_control_service.dart';
import 'package:flutter/services.dart';

/// [SystemControlService] backed by the Kotlin `SystemControlChannelHandler`.
/// This is the only file that knows about the channel.
class AndroidSystemControlService implements SystemControlService {
  // Not `this._channel`: that would make the parameter name the private
  // `_channel`, which a test in another file could not pass by name.
  const AndroidSystemControlService({
    MethodChannel channel = const MethodChannel(channelName),
    // ignore: prefer_initializing_formals
  }) : _channel = channel;

  static const String channelName =
      'com.codedbykay.android_tile_launcher/system_control';

  final MethodChannel _channel;

  @override
  Future<bool> isOn(TileKind kind) async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('isOn', {
        'kind': kind.name,
      });
      return result ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<void> setOn(TileKind kind, bool on) async {
    try {
      await _channel.invokeMethod<void>('setOn', {'kind': kind.name, 'on': on});
    } on PlatformException {
      // Best-effort, like every other platform action in this app: there is
      // no error surface for a tile tap to report a failure through.
    } on MissingPluginException {
      // no-op
    }
  }
}

import 'package:android_tile_launcher/model/sound_mode.dart';
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
  Future<SoundMode> soundMode() async {
    try {
      final String? name = await _channel.invokeMethod<String>('getSoundMode');
      return SoundMode.values.asNameMap()[name] ?? SoundMode.normal;
    } on PlatformException {
      return SoundMode.normal;
    } on MissingPluginException {
      return SoundMode.normal;
    }
  }

  @override
  Future<void> setSoundMode(SoundMode mode) =>
      _invoke('setSoundMode', {'mode': mode.name});

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
  Future<void> setOn(TileKind kind, bool on) =>
      _invoke('setOn', {'kind': kind.name, 'on': on});

  // Best-effort, like every other platform action in this app: there is no
  // error surface for a tile tap to report a failure through.
  Future<void> _invoke(String method, Map<String, Object?> arguments) async {
    try {
      await _channel.invokeMethod<void>(method, arguments);
    } on PlatformException {
      // no-op
    } on MissingPluginException {
      // no-op
    }
  }
}

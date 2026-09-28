import 'dart:async';

import 'package:android_tile_launcher/services/shade_service.dart';
import 'package:flutter/services.dart';

/// [ShadeService] backed by the Kotlin `ShadeChannelHandler`. The only file
/// that knows about the channel.
class AndroidShadeService implements ShadeService {
  const AndroidShadeService({
    this.channel = const MethodChannel(channelName),
    this.timeout = const Duration(seconds: 5),
  });

  static const String channelName =
      'com.codedbykay.android_tile_launcher/shade';

  final MethodChannel channel;

  /// Only guards against a reply that never comes.
  final Duration timeout;

  @override
  Future<bool> expandNotifications() => _call('expandNotifications');

  @override
  Future<bool> expandQuickSettings() => _call('expandQuickSettings');

  Future<bool> _call(String method) async {
    try {
      return await channel.invokeMethod<bool>(method).timeout(timeout) ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    } on TimeoutException {
      return false;
    }
  }
}

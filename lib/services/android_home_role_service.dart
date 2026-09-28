import 'dart:async';

import 'package:android_tile_launcher/services/home_role_service.dart';
import 'package:flutter/services.dart';

/// [HomeRoleService] backed by the Kotlin `HomeRoleChannelHandler`. The only
/// file that knows about the channel.
class AndroidHomeRoleService implements HomeRoleService {
  const AndroidHomeRoleService({
    this.channel = const MethodChannel(channelName),
    this.timeout = const Duration(seconds: 5),
  });

  static const String channelName = 'com.codedbykay.android_tile_launcher/home';

  final MethodChannel channel;

  /// Only guards against a reply that never comes.
  final Duration timeout;

  @override
  Future<bool?> isDefault() async {
    try {
      return await channel.invokeMethod<bool>('isDefault').timeout(timeout);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    } on TimeoutException {
      return null;
    }
  }

  @override
  Future<bool> openSettings() async {
    try {
      return await channel
              .invokeMethod<bool>('openSettings')
              .timeout(timeout) ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    } on TimeoutException {
      return false;
    }
  }
}

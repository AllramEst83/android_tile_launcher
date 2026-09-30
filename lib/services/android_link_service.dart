import 'dart:async';

import 'package:android_tile_launcher/services/link_service.dart';
import 'package:flutter/services.dart';

/// [LinkService] backed by the Kotlin `LinkChannelHandler`. The only file that
/// knows about the channel.
class AndroidLinkService implements LinkService {
  const AndroidLinkService({
    this.channel = const MethodChannel(channelName),
    this.timeout = const Duration(seconds: 10),
  });

  static const String channelName = 'com.codedbykay.android_tile_launcher/link';

  final MethodChannel channel;

  /// Only guards against a reply that never comes.
  final Duration timeout;

  @override
  Future<LinkResult> open(String url) async {
    try {
      final bool ok =
          await channel
              .invokeMethod<bool>('open', <String, Object?>{'url': url})
              .timeout(timeout) ??
          false;
      return ok ? const LinkOpened() : _failed;
    } on PlatformException {
      return _failed;
    } on MissingPluginException {
      return const LinkFailed('opening links is not supported here');
    } on TimeoutException {
      return _failed;
    }
  }

  static const LinkFailed _failed = LinkFailed('could not open that link');
}

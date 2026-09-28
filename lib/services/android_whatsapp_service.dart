import 'dart:async';

import 'package:android_tile_launcher/services/whatsapp_service.dart';
import 'package:flutter/services.dart';

/// [WhatsAppService] backed by the Kotlin `WhatsAppChannelHandler`. The only
/// file that knows about the channel.
class AndroidWhatsAppService implements WhatsAppService {
  const AndroidWhatsAppService({
    this.channel = const MethodChannel(channelName),
    this.timeout = const Duration(seconds: 10),
  });

  static const String channelName =
      'com.codedbykay.android_tile_launcher/whatsapp';

  final MethodChannel channel;

  /// Only guards against a reply that never comes.
  final Duration timeout;

  @override
  Future<WhatsAppResult> openChat(String number) async {
    try {
      final bool ok =
          await channel
              .invokeMethod<bool>('open', <String, Object?>{'number': number})
              .timeout(timeout) ??
          false;
      return ok ? const WhatsAppOpened() : _failed;
    } on PlatformException {
      return _failed;
    } on MissingPluginException {
      return const WhatsAppFailed('WhatsApp hand-off is not supported here');
    } on TimeoutException {
      return _failed;
    }
  }

  static const WhatsAppFailed _failed = WhatsAppFailed(
    'could not open WhatsApp',
  );
}

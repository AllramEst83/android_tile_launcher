import 'dart:async';

import 'package:android_tile_launcher/services/permission_service.dart';
import 'package:android_tile_launcher/services/sms_service.dart';
import 'package:flutter/services.dart';

/// [SmsService] backed by the Kotlin `SmsChannelHandler`, after asking
/// [PermissionService] for `sms`. The only file that knows about the channel.
class AndroidSmsService implements SmsService {
  const AndroidSmsService({
    required this.permissions,
    this.channel = const MethodChannel(channelName),
    this.timeout = const Duration(seconds: 45),
  });

  static const String channelName = 'com.codedbykay.android_tile_launcher/sms';

  final PermissionService permissions;
  final MethodChannel channel;

  /// The Kotlin side stops waiting for the network after 30 s; this only
  /// guards against a reply that never comes at all.
  final Duration timeout;

  @override
  Future<SmsResult> send(String number, String text) async {
    final PermissionStatus status = await permissions.request(
      AppPermission.sms,
    );
    if (status != PermissionStatus.granted) {
      return SmsDenied(permanent: status == PermissionStatus.permanentlyDenied);
    }
    try {
      final bool? ok = await channel
          .invokeMethod<bool>('send', <String, Object?>{
            'number': number,
            'text': text,
          })
          .timeout(timeout);
      return ok == true ? const SmsSent() : const SmsFailed(_generic);
    } on PlatformException catch (error) {
      return switch (error.code) {
        'NO_PERMISSION' => const SmsDenied(permanent: false),
        'NO_SERVICE' => const SmsFailed('no network service'),
        'RADIO_OFF' => const SmsFailed('flight mode is on'),
        // Some parts may have gone; resending blindly could double them.
        'NOT_CONFIRMED' => const SmsFailed(_notConfirmed),
        _ => const SmsFailed(_generic),
      };
    } on MissingPluginException {
      return const SmsFailed('texting is not supported here');
    } on TimeoutException {
      return const SmsFailed(_notConfirmed);
    }
  }

  static const String _generic = 'the message could not be sent';
  static const String _notConfirmed =
      'not confirmed by the network; check before resending';
}

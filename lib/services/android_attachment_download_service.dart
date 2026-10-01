import 'dart:async';

import 'package:android_tile_launcher/services/attachment_download_service.dart';
import 'package:flutter/services.dart';

/// [AttachmentDownloadService] backed by the Kotlin `AttachmentChannelHandler`.
/// The only file that knows about the channel.
class AndroidAttachmentDownloadService implements AttachmentDownloadService {
  const AndroidAttachmentDownloadService({
    this.channel = const MethodChannel(channelName),
    // Writing a large file takes a moment; this only guards against a reply
    // that never comes.
    this.timeout = const Duration(seconds: 30),
  });

  static const String channelName =
      'com.codedbykay.android_tile_launcher/attachments';

  final MethodChannel channel;
  final Duration timeout;

  @override
  Future<AttachmentSaveResult> save(
    Uint8List bytes, {
    required String fileName,
    required String mimeType,
  }) async {
    try {
      final String? reply = await channel
          .invokeMethod<String>('save', <String, Object?>{
            'bytes': bytes,
            'fileName': fileName,
            'mimeType': mimeType,
          })
          .timeout(timeout);
      return switch (reply) {
        'saved' => AttachmentSaveResult.saved,
        'refused' => AttachmentSaveResult.refused,
        _ => AttachmentSaveResult.failed,
      };
    } on PlatformException {
      return AttachmentSaveResult.failed;
    } on MissingPluginException {
      return AttachmentSaveResult.failed;
    } on TimeoutException {
      return AttachmentSaveResult.failed;
    }
  }
}

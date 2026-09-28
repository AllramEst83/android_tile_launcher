import 'dart:async';

import 'package:android_tile_launcher/model/wallpaper.dart';
import 'package:android_tile_launcher/services/wallpaper_service.dart';
import 'package:flutter/services.dart';

/// [WallpaperService] backed by the Kotlin `WallpaperChannelHandler`. The only
/// file that knows about the channel.
class AndroidWallpaperService implements WallpaperService {
  const AndroidWallpaperService({
    this.channel = const MethodChannel(channelName),
    // Decoding and setting a big picture takes a moment; this only guards
    // against a reply that never comes.
    this.timeout = const Duration(seconds: 30),
  });

  static const String channelName =
      'com.codedbykay.android_tile_launcher/wallpaper';

  final MethodChannel channel;
  final Duration timeout;

  @override
  Future<WallpaperResult> set(Uint8List image, WallpaperTarget target) =>
      _call('set', <String, Object?>{'image': image, 'target': target.name});

  @override
  Future<WallpaperResult> clear(WallpaperTarget target) =>
      _call('clear', <String, Object?>{'target': target.name});

  Future<WallpaperResult> _call(
    String method,
    Map<String, Object?> arguments,
  ) async {
    try {
      final String? reply = await channel
          .invokeMethod<String>(method, arguments)
          .timeout(timeout);
      return switch (reply) {
        'done' => WallpaperResult.done,
        'refused' => WallpaperResult.refused,
        _ => WallpaperResult.failed,
      };
    } on PlatformException {
      return WallpaperResult.failed;
    } on MissingPluginException {
      return WallpaperResult.failed;
    } on TimeoutException {
      return WallpaperResult.failed;
    }
  }
}

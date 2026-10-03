import 'dart:async';

import 'package:android_tile_launcher/model/media_snapshot.dart';
import 'package:android_tile_launcher/services/media_service.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/services.dart';

/// [MediaService] backed by the Kotlin `MediaChannelHandler`. The only file
/// that knows about the channel.
class AndroidMediaService implements MediaService {
  AndroidMediaService({
    this.channel = const MethodChannel(channelName),
    this.timeout = const Duration(seconds: 5),
  });

  static const String channelName =
      'com.codedbykay.android_tile_launcher/media';

  final MethodChannel channel;

  /// Only guards against a reply that never comes.
  final Duration timeout;

  /// The last art handed out. Every read gets fresh bytes from Android, and
  /// [Image.memory] treats new bytes as a new image — decoding it again and
  /// blinking — so while the art is unchanged the same instance is returned.
  Uint8List? _lastArtwork;

  Uint8List? _stable(Uint8List? fresh) {
    final Uint8List? last = _lastArtwork;
    if (fresh != null && last != null && listEquals(fresh, last)) return last;
    return _lastArtwork = fresh;
  }

  @override
  Future<MediaSnapshot> now() async {
    try {
      final Map<Object?, Object?>? map = await channel
          .invokeMethod<Map<Object?, Object?>>('now')
          .timeout(timeout);
      if (map == null) return const MediaUnavailable('NO REPLY');
      if (map['needsAccess'] == true) {
        return const MediaNeedsNotificationAccess();
      }
      if (map['none'] == true) return const MediaNone();
      return MediaPlaying(
        title: map['title'] as String? ?? '',
        artist: map['artist'] as String? ?? '',
        isPlaying: map['isPlaying'] as bool? ?? false,
        album: map['album'] as String?,
        appLabel: map['appLabel'] as String?,
        artwork: _stable(map['artwork'] as Uint8List?),
      );
    } on PlatformException {
      return const MediaUnavailable('COULD NOT READ IT');
    } on MissingPluginException {
      return const MediaUnavailable('COULD NOT READ IT');
    } on TimeoutException {
      return const MediaUnavailable('COULD NOT READ IT');
    }
  }

  @override
  Future<void> playPause() => _fireAndForget('playPause');

  @override
  Future<void> next() => _fireAndForget('next');

  @override
  Future<void> previous() => _fireAndForget('previous');

  Future<void> _fireAndForget(String method) async {
    try {
      await channel.invokeMethod<void>(method).timeout(timeout);
    } on PlatformException {
      // Nothing to control right now; not an error worth surfacing.
    } on MissingPluginException {
      // Ditto.
    } on TimeoutException {
      // Ditto.
    }
  }

  @override
  Future<bool> openAccessSettings() async {
    try {
      return await channel
              .invokeMethod<bool>('openAccessSettings')
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

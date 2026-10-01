import 'dart:typed_data';

/// What the Now Playing tile can show right now: the active session (if
/// any), or the reason there is none to show. Unlike the agenda/weather
/// permission flow there is no runtime dialog to ask for — notification
/// access is a "special access" permission granted only from Android's own
/// Settings — so [MediaNeedsNotificationAccess] is the one case a tap always
/// fixes the same way, by opening it.
sealed class MediaSnapshot {
  const MediaSnapshot();
}

/// A session is active: [title]/[artist] (and optionally [album], [artwork],
/// [appLabel]) came from whatever app owns it (Spotify, YouTube Music, a
/// podcast app, ...). [isPlaying] is false for a paused session, not a
/// stopped one — Android drops a session once playback actually stops.
class MediaPlaying extends MediaSnapshot {
  const MediaPlaying({
    required this.title,
    required this.artist,
    required this.isPlaying,
    this.album,
    this.appLabel,
    this.artwork,
  });

  final String title;
  final String artist;
  final bool isPlaying;
  final String? album;

  /// The app's own label ("Spotify"), not its package name.
  final String? appLabel;

  /// Album art, straight from the session's metadata; `null` when it has
  /// none. Never compared for equality — two reads of the same art are not
  /// guaranteed to be the same bytes.
  final Uint8List? artwork;

  @override
  String toString() => 'MediaPlaying($title, $artist, playing: $isPlaying)';
}

/// No app has an active media session.
class MediaNone extends MediaSnapshot {
  const MediaNone();

  @override
  bool operator ==(Object other) => other is MediaNone;

  @override
  int get hashCode => (MediaNone).hashCode;
}

/// Notification-listener access has not been granted, so no session can be
/// read even if one exists. There is no "ask" step, unlike a runtime
/// permission: a tap always opens Android's own settings page for it.
class MediaNeedsNotificationAccess extends MediaSnapshot {
  const MediaNeedsNotificationAccess();

  @override
  bool operator ==(Object other) => other is MediaNeedsNotificationAccess;

  @override
  int get hashCode => (MediaNeedsNotificationAccess).hashCode;
}

/// Access is fine but the session could not be read; [reason] is short.
class MediaUnavailable extends MediaSnapshot {
  const MediaUnavailable(this.reason);

  final String reason;

  @override
  bool operator ==(Object other) =>
      other is MediaUnavailable && other.reason == reason;

  @override
  int get hashCode => Object.hash(MediaUnavailable, reason);
}

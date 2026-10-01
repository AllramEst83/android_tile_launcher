import 'package:android_tile_launcher/model/media_snapshot.dart';

/// What is playing right now in whatever app owns the active media session
/// (Spotify, YouTube Music, a podcast app, ...), and the transport controls
/// for it. Reading this needs Android's notification-listener access — a
/// "special access" permission granted only from its own Settings screen,
/// never a runtime dialog (see [openAccessSettings]). Never throws.
abstract interface class MediaService {
  Future<MediaSnapshot> now();

  /// No session, no access, or nothing to control: every one of these is a
  /// no-op rather than an error.
  Future<void> playPause();
  Future<void> next();
  Future<void> previous();

  /// Opens Android's own page for granting notification-listener access.
  /// `true` once it was opened.
  Future<bool> openAccessSettings();
}

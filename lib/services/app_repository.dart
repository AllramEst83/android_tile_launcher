import 'dart:typed_data';

import 'package:android_tile_launcher/services/app_info.dart';

/// Fetches an app's icon (PNG bytes), or `null` when it has none.
typedef AppIconLoader = Future<Uint8List?> Function(String packageName);

/// The only way the launcher reaches installed apps. Implementations list
/// launchable apps only, exclude this app, and sort by label.
abstract interface class AppRepository {
  /// Cached after the first call; [refresh] forces a new platform query.
  /// Throws `AppRepositoryException` if the platform query fails.
  Future<List<AppInfo>> listApps({bool refresh = false});

  /// Returns `false` when the app has no launch intent or starting it fails.
  Future<bool> launch(String packageName);

  /// Opens Android's uninstall confirmation for [packageName]. `true` only
  /// means the dialog was shown; the user may still cancel, so callers must
  /// not assume the app is gone.
  Future<bool> uninstall(String packageName);

  /// Opens Android's own "App info" settings screen for [packageName].
  Future<bool> openAppDetails(String packageName);

  /// The icon of [packageName] as PNG bytes, or `null` when the app has none,
  /// is gone, or the platform could not draw it. Never throws; repeated asks
  /// for the same app are answered from memory.
  Future<Uint8List?> icon(String packageName);
}

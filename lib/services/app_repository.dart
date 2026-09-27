import 'package:android_tile_launcher/services/app_info.dart';

/// The only way the launcher reaches installed apps. Implementations list
/// launchable apps only, exclude this app, and sort by label.
///
/// `uninstall` is added when the drawer's quick actions land (plan.md,
/// Phase 4); nothing needs it yet.
abstract interface class AppRepository {
  /// Cached after the first call; [refresh] forces a new platform query.
  /// Throws `AppRepositoryException` if the platform query fails.
  Future<List<AppInfo>> listApps({bool refresh = false});

  /// Returns `false` when the app has no launch intent or starting it fails.
  Future<bool> launch(String packageName);
}

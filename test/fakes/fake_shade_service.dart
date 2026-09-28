import 'package:android_tile_launcher/services/shade_service.dart';

/// Counts how often each panel was pulled down.
class FakeShadeService implements ShadeService {
  int notificationCalls = 0;
  int quickSettingsCalls = 0;

  @override
  Future<bool> expandNotifications() async {
    notificationCalls++;
    return true;
  }

  @override
  Future<bool> expandQuickSettings() async {
    quickSettingsCalls++;
    return true;
  }
}

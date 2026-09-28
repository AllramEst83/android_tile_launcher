import 'package:android_tile_launcher/services/home_role_service.dart';

/// Says the launcher is (or is not, or might be) the Home app, and counts how
/// often the chooser was opened.
class FakeHomeRoleService implements HomeRoleService {
  FakeHomeRoleService([this.isDefaultAnswer = true]);

  bool? isDefaultAnswer;
  bool opens = false;
  int openCalls = 0;

  @override
  Future<bool?> isDefault() async => isDefaultAnswer;

  @override
  Future<bool> openSettings() async {
    openCalls++;
    return opens = true;
  }
}

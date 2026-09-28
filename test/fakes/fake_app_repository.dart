import 'dart:typed_data';

import 'package:android_tile_launcher/services/app_info.dart';
import 'package:android_tile_launcher/services/app_repository.dart';

class FakeAppRepository implements AppRepository {
  FakeAppRepository({
    this.apps = const [],
    this.launchSucceeds = true,
    this.uninstallSucceeds = true,
    this.openAppDetailsSucceeds = true,
    this.listError,
  });

  List<AppInfo> apps;
  bool launchSucceeds;
  bool uninstallSucceeds;
  bool openAppDetailsSucceeds;
  Object? listError;

  /// Package names passed to [launch], in call order.
  final List<String> launched = [];

  /// Package names passed to [uninstall], in call order.
  final List<String> uninstalled = [];

  /// Package names passed to [openAppDetails], in call order.
  final List<String> detailsOpened = [];

  /// The icon each package has (none by default), and every package asked for.
  final Map<String, Uint8List> icons = {};
  final List<String> iconsAsked = [];
  int listCalls = 0;

  /// How many of the [listApps] calls asked for a refresh.
  int refreshCalls = 0;

  @override
  Future<List<AppInfo>> listApps({bool refresh = false}) async {
    listCalls++;
    if (refresh) refreshCalls++;
    final Object? error = listError;
    if (error != null) throw error;
    return apps;
  }

  @override
  Future<bool> launch(String packageName) async {
    launched.add(packageName);
    return launchSucceeds;
  }

  @override
  Future<bool> uninstall(String packageName) async {
    uninstalled.add(packageName);
    return uninstallSucceeds;
  }

  @override
  Future<Uint8List?> icon(String packageName) async {
    iconsAsked.add(packageName);
    return icons[packageName];
  }

  @override
  Future<bool> openAppDetails(String packageName) async {
    detailsOpened.add(packageName);
    return openAppDetailsSucceeds;
  }
}

import 'package:android_tile_launcher/services/app_info.dart';
import 'package:android_tile_launcher/services/app_repository.dart';

class FakeAppRepository implements AppRepository {
  FakeAppRepository({
    this.apps = const [],
    this.launchSucceeds = true,
    this.listError,
  });

  List<AppInfo> apps;
  bool launchSucceeds;
  Object? listError;

  /// Package names passed to [launch], in call order.
  final List<String> launched = [];
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
}

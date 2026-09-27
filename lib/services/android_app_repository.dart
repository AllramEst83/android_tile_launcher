import 'package:android_tile_launcher/services/app_info.dart';
import 'package:android_tile_launcher/services/app_repository.dart';
import 'package:android_tile_launcher/services/app_repository_exception.dart';
import 'package:flutter/services.dart';

/// [AppRepository] backed by the Kotlin `AppsChannelHandler`. This is the only
/// file that knows about the channel; swapping it must touch nothing else.
class AndroidAppRepository implements AppRepository {
  // Not `this._channel`: that would make the parameter name the private
  // `_channel`, which a test in another file could not pass by name.
  AndroidAppRepository({
    required this.ownPackage,
    MethodChannel channel = const MethodChannel(channelName),
    // ignore: prefer_initializing_formals
  }) : _channel = channel;

  static const String channelName = 'com.codedbykay.android_tile_launcher/apps';

  /// Excluded from the listing. The manifest's `LAUNCHER` filter makes this
  /// app show up in its own query, and a tile must not relaunch the launcher.
  final String ownPackage;
  final MethodChannel _channel;
  List<AppInfo>? _cache;

  @override
  Future<List<AppInfo>> listApps({bool refresh = false}) async {
    final List<AppInfo>? cached = _cache;
    if (!refresh && cached != null) return cached;

    final List<Map<Object?, Object?>>? raw;
    try {
      raw = await _channel.invokeListMethod<Map<Object?, Object?>>('listApps');
    } on PlatformException catch (error) {
      throw AppRepositoryException(
        'could not list apps: ${error.message ?? error.code}',
      );
    } on MissingPluginException {
      throw const AppRepositoryException('could not list apps: unsupported');
    }

    final List<AppInfo> apps = <AppInfo>[
      for (final Map<Object?, Object?> entry in raw ?? const [])
        if (_parse(entry) case final AppInfo app) app,
    ]..sort(_byLabel);
    return _cache = List.unmodifiable(apps);
  }

  @override
  Future<bool> launch(String packageName) async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('launch', {
        'packageName': packageName,
      });
      return result ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  AppInfo? _parse(Map<Object?, Object?> entry) {
    final Object? packageName = entry['packageName'];
    if (packageName is! String || packageName == ownPackage) return null;
    final Object? label = entry['label'];
    return AppInfo(
      label: label is String && label.isNotEmpty ? label : packageName,
      packageName: packageName,
    );
  }

  static int _byLabel(AppInfo a, AppInfo b) {
    final int byLabel = a.label.toLowerCase().compareTo(b.label.toLowerCase());
    return byLabel != 0 ? byLabel : a.packageName.compareTo(b.packageName);
  }
}

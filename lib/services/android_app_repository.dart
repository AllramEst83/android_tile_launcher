import 'dart:async';

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

  /// How many icons are kept: enough for a long app list, and each is a few
  /// kilobytes. The oldest is dropped first.
  static const int maxIcons = 400;

  /// The icon's side in pixels: sharp on a 3x screen at a 48 dp tile icon.
  static const int iconPixels = 144;

  // The pending or finished answer for each app, so a list that scrolls back
  // and forth (and a tile drawn twice) asks the platform once.
  final Map<String, Future<Uint8List?>> _icons = <String, Future<Uint8List?>>{};

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
  Future<bool> launch(String packageName) => _invokeBool('launch', packageName);

  @override
  Future<bool> uninstall(String packageName) =>
      _invokeBool('uninstall', packageName);

  @override
  Future<bool> openAppDetails(String packageName) =>
      _invokeBool('openAppDetails', packageName);

  @override
  Future<Uint8List?> icon(String packageName) {
    final Future<Uint8List?>? known = _icons.remove(packageName);
    if (known != null) {
      // Moved to the newest place, so a used icon outlives an unused one.
      return _icons[packageName] = known;
    }
    if (_icons.length >= maxIcons) _forget(_icons.keys.first);
    return _icons[packageName] = _fetchIcon(packageName);
  }

  // `Map.remove` hands back the removed future, which nobody awaits here.
  void _forget(String packageName) => _icons.removeWhere(
    (String key, Future<Uint8List?> _) => key == packageName,
  );

  Future<Uint8List?> _fetchIcon(String packageName) async {
    try {
      final Uint8List? bytes = await _channel.invokeMethod<Uint8List>('icon', {
        'packageName': packageName,
        'size': iconPixels,
      });
      if (bytes == null || bytes.isEmpty) {
        _forget(packageName);
        return null;
      }
      return bytes;
    } on PlatformException {
      _forget(packageName);
      return null;
    } on MissingPluginException {
      _forget(packageName);
      return null;
    }
  }

  /// Expected failures (no launch intent, dialog refused, no settings screen
  /// for that package) are a `false`, not an exception, so the UI can show
  /// them plainly instead of crashing.
  Future<bool> _invokeBool(String method, String packageName) async {
    try {
      final bool? result = await _channel.invokeMethod<bool>(method, {
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

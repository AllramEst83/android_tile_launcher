import 'dart:io';

import 'package:android_tile_launcher/model/file_entry.dart';
import 'package:android_tile_launcher/services/files_service.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// [FilesService] on Android's "all files access" special permission
/// (`package:permission_handler`, a well-established, actively-maintained
/// plugin for exactly this fiddly Settings-redirect flow) and plain
/// `dart:io` once it is granted — no document-tree API is needed here, since
/// this app now has the same ordinary filesystem access Android's own Files
/// app does. `roots` alone needs a platform call: `dart:io` has no way to ask
/// Android what storage volumes exist, only to read paths once it already
/// knows them — the Kotlin `FilesChannelHandler`'s one job, kept as this
/// app's own small channel rather than a second package, after the
/// once-considered `external_path` turned out to still apply the Kotlin
/// Gradle Plugin the old way, one Flutter is phasing out.
class AndroidFilesService implements FilesService {
  // Not `this._channel`: that would make the parameter name the private
  // `_channel`, which a caller in another file could not pass by name.
  AndroidFilesService({
    MethodChannel channel = const MethodChannel(channelName),
    Future<bool> Function()? hasAccessCheck,
    Future<bool> Function()? requestAccessCheck,
    // ignore: prefer_initializing_formals
  }) : _channel = channel,
       _hasAccessCheck = hasAccessCheck ?? _defaultHasAccess,
       _requestAccessCheck = requestAccessCheck ?? _defaultRequestAccess;

  static const String channelName =
      'com.codedbykay.android_tile_launcher/files';

  final MethodChannel _channel;
  final Future<bool> Function() _hasAccessCheck;
  final Future<bool> Function() _requestAccessCheck;

  static Future<bool> _defaultHasAccess() async =>
      (await Permission.manageExternalStorage.status).isGranted;

  static Future<bool> _defaultRequestAccess() async =>
      (await Permission.manageExternalStorage.request()).isGranted;

  @override
  Future<bool> hasAccess() async {
    try {
      return await _hasAccessCheck();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<AccessResult> requestAccess() async {
    try {
      final bool granted = await _requestAccessCheck();
      return granted ? const AccessGranted() : const AccessDenied();
    } catch (_) {
      return const AccessDenied();
    }
  }

  @override
  Future<FilesResult> roots() async {
    List<String> paths;
    try {
      final List<Object?>? raw = await _channel.invokeListMethod<Object?>(
        'storageRoots',
      );
      paths = (raw ?? const <Object?>[]).whereType<String>().toList();
    } on PlatformException catch (error) {
      return FilesUnavailable(error.message ?? 'could not read storage');
    } on MissingPluginException {
      return const FilesUnavailable('not supported here');
    } catch (error) {
      return FilesUnavailable(_reason(error));
    }
    if (paths.isEmpty) return const FilesUnavailable('no storage found');
    return FilesListed(<FileEntry>[
      for (final (int i, String path) in paths.indexed)
        FileEntry(
          name: _rootName(i),
          path: path,
          isDirectory: true,
          sizeBytes: 0,
        ),
    ]);
  }

  @override
  Future<FilesResult> list(String path) async {
    if (!await hasAccess()) return const FilesNoAccess();
    try {
      final Directory directory = Directory(path);
      if (!await directory.exists()) {
        return const FilesUnavailable('that folder is gone');
      }
      final List<FileEntry> entries = <FileEntry>[];
      await for (final FileSystemEntity child in directory.list()) {
        final bool isDirectory = child is Directory;
        int size = 0;
        int? itemCount;
        DateTime? modified;
        try {
          modified = (await child.stat()).modified;
        } on FileSystemException {
          // Unreadable for whatever reason; left blank rather than dropped,
          // so it is still there to delete.
        }
        if (isDirectory) {
          try {
            itemCount = await child.list().length;
          } on FileSystemException {
            // Same as above: blank, not dropped.
          }
        } else {
          try {
            size = await (child as File).length();
          } on FileSystemException {
            // Same as above: shown as 0 B rather than dropped.
          }
        }
        entries.add(
          FileEntry(
            name: _basename(child.path),
            path: child.path,
            isDirectory: isDirectory,
            sizeBytes: size,
            modified: modified,
            itemCount: itemCount,
          ),
        );
      }
      // A stable base order; sorting the way the user actually wants it
      // (by name, MODIFIED or SIZE, either direction) is the sheet's own job
      // now that it is interactive rather than a fixed service-side choice.
      entries.sort(
        (FileEntry a, FileEntry b) =>
            a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return FilesListed(entries);
    } on FileSystemException catch (error) {
      return FilesUnavailable(error.osError?.message ?? error.message);
    } catch (error) {
      return FilesUnavailable(_reason(error));
    }
  }

  @override
  Future<DeleteResult> delete(String path) async {
    try {
      final FileSystemEntityType type = await FileSystemEntity.type(path);
      switch (type) {
        case FileSystemEntityType.directory:
          await Directory(path).delete(recursive: true);
        case FileSystemEntityType.notFound:
          return const DeleteFailed('already gone');
        default:
          await File(path).delete();
      }
      return const DeleteSucceeded();
    } on FileSystemException catch (error) {
      return DeleteFailed(error.osError?.message ?? error.message);
    } catch (error) {
      return DeleteFailed(_reason(error));
    }
  }

  static String _rootName(int index) => switch (index) {
    0 => 'INTERNAL STORAGE',
    1 => 'SD CARD',
    _ => 'SD CARD $index',
  };

  // Android paths are always '/'-separated; `\` is only ever seen running
  // this same code against a real filesystem on a Windows dev machine's own
  // tests, not on the phone this actually ships to.
  static String _basename(String path) {
    final int slash = path.lastIndexOf(RegExp(r'[/\\]'));
    return slash < 0 ? path : path.substring(slash + 1);
  }

  static String _reason(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
}

import 'package:android_tile_launcher/model/media_snapshot.dart';
import 'package:android_tile_launcher/services/media_service.dart';

/// Answers with [snapshot]; counts how often each transport action and
/// [openAccessSettings] were called.
class FakeMediaService implements MediaService {
  FakeMediaService([this.snapshot = const MediaNone()]);

  MediaSnapshot snapshot;
  int playPauseCalls = 0;
  int nextCalls = 0;
  int previousCalls = 0;
  int openAccessSettingsCalls = 0;

  @override
  Future<MediaSnapshot> now() async => snapshot;

  @override
  Future<void> playPause() async => playPauseCalls++;

  @override
  Future<void> next() async => nextCalls++;

  @override
  Future<void> previous() async => previousCalls++;

  @override
  Future<bool> openAccessSettings() async {
    openAccessSettingsCalls++;
    return true;
  }
}

import 'package:android_tile_launcher/model/media_snapshot.dart';
import 'package:android_tile_launcher/model/tile_content.dart';
import 'package:android_tile_launcher/services/media_tile_source.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_media_service.dart';

void main() {
  test('reads what the service has', () async {
    final service = FakeMediaService(
      const MediaPlaying(title: 'A SONG', artist: 'A BAND', isPlaying: true),
    );
    final source = MediaTileSource(service: service);

    final content = await source.read();

    expect(content, isA<MediaContent>());
    expect((content as MediaContent).snapshot, isA<MediaPlaying>());
  });
}

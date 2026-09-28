import 'package:android_tile_launcher/model/text_tv_page.dart';
import 'package:android_tile_launcher/model/tile_content.dart';
import 'package:android_tile_launcher/services/text_tv_tile_source.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_text_tv_repository.dart';

void main() {
  test('reads the headline page', () async {
    final FakeTextTvRepository repository = FakeTextTvRepository(
      <int, TextTvPage>{
        100: const TextTvPage(
          number: 100,
          parts: <List<String>>[
            <String>['x'],
          ],
        ),
      },
    );

    final TileContent content = await TextTvTileSource(repository: repository)
        .read();

    expect(repository.requests, <(int, bool)>[(100, false)]);
    expect((content as TextTvContent).result, isA<TextTvShown>());
  });

  test('passes on why there is nothing to show', () async {
    final TileContent content = await TextTvTileSource(
      repository: FakeTextTvRepository(),
    ).read();

    expect((content as TextTvContent).result, isA<TextTvNotBroadcast>());
  });

  test('the page to read can be chosen', () async {
    final FakeTextTvRepository repository = FakeTextTvRepository();

    await TextTvTileSource(repository: repository, page: 300).read();

    expect(repository.requests.single.$1, 300);
  });
}

import 'dart:convert';

import 'package:android_tile_launcher/model/text_tv_page.dart';
import 'package:android_tile_launcher/services/live_text_tv_repository.dart';
import 'package:android_tile_launcher/services/network_exception.dart';
import 'package:android_tile_launcher/services/text_tv.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_http_fetcher.dart';

String _page(int number, {String line = 'Hello'}) => jsonEncode(<Object>[
  <String, Object>{
    'num': '$number',
    'content_plain': <String>[line],
    'next_page': '${number + 1}',
    'prev_page': '${number - 1}',
  },
]);

void main() {
  late FakeHttpFetcher fetcher;
  late DateTime now;
  late LiveTextTvRepository repository;
  setUp(() {
    fetcher = FakeHttpFetcher()
      ..route('/api/get/', (Uri url) {
        final int number = int.parse(url.pathSegments.last);
        return _page(number);
      });
    now = DateTime(2026, 9, 28, 10);
    repository = LiveTextTvRepository(
      textTv: TextTv(fetcher: fetcher),
      maxAge: const Duration(minutes: 5),
      capacity: 3,
      clock: () => now,
    );
  });

  test('reads a page from the site', () async {
    final TextTvResult result = await repository.page(130);

    expect(result, isA<TextTvShown>());
    expect((result as TextTvShown).page.number, 130);
    expect(fetcher.requests, hasLength(1));
  });

  test('a page read a moment ago is not read again', () async {
    await repository.page(130);
    now = now.add(const Duration(minutes: 4));

    await repository.page(130);

    expect(fetcher.requests, hasLength(1));
  });

  test('past its age it is read again', () async {
    await repository.page(130);
    now = now.add(const Duration(minutes: 5));

    await repository.page(130);

    expect(fetcher.requests, hasLength(2));
  });

  test('fresh always asks the site', () async {
    await repository.page(130);

    await repository.page(130, fresh: true);

    expect(fetcher.requests, hasLength(2));
  });

  test(
    'a page that is not in broadcast says so, and is asked for again',
    () async {
      fetcher.route('/api/get/999', '[]');

      final TextTvResult first = await repository.page(999);
      await repository.page(999);

      expect(first, isA<TextTvNotBroadcast>());
      expect((first as TextTvNotBroadcast).number, 999);
      expect(fetcher.requests, hasLength(2));
    },
  );

  test('a failure says why, and is not kept', () async {
    fetcher.route('/api/get/500', NetworkException('no connection'));

    final TextTvResult first = await repository.page(500);
    await repository.page(500);

    expect((first as TextTvFailed).reason, 'no connection');
    expect(fetcher.requests, hasLength(2));
  });

  test('keeps only the most recently read pages', () async {
    await repository.page(101);
    await repository.page(102);
    await repository.page(103);
    await repository.page(104); // pushes 101 out

    await repository.page(104);
    await repository.page(102);
    expect(fetcher.requests, hasLength(4));

    await repository.page(101);
    expect(fetcher.requests, hasLength(5));
  });
}

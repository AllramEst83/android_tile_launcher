import 'package:android_tile_launcher/model/app_matcher.dart';
import 'package:android_tile_launcher/services/app_info.dart';
import 'package:flutter_test/flutter_test.dart';

const List<AppInfo> _apps = [
  AppInfo(label: 'Maps', packageName: 'pkg.maps'),
  AppInfo(label: 'Mastodon', packageName: 'pkg.mastodon'),
  AppInfo(label: 'Gmail', packageName: 'pkg.gmail'),
];

void main() {
  group('rankApps', () {
    test('an empty query matches nothing', () {
      expect(rankApps(_apps, ''), isEmpty);
      expect(rankApps(_apps, '   '), isEmpty);
    });

    test('an exact label match comes first', () {
      final ranked = rankApps(_apps, 'maps');

      expect(ranked.first.packageName, 'pkg.maps');
    });

    test('prefix matches follow exact matches, then substring matches', () {
      final ranked = rankApps(_apps, 'ma');

      // Gmail matches too ("gMAil" contains "ma"), but only as a weaker
      // substring tier, after both prefix matches.
      expect(ranked.map((a) => a.packageName), [
        'pkg.maps',
        'pkg.mastodon',
        'pkg.gmail',
      ]);
    });

    test('substring matches are included after prefix matches', () {
      final ranked = rankApps(_apps, 'ail');

      expect(ranked.single.packageName, 'pkg.gmail');
    });

    test('matching is case-insensitive', () {
      expect(rankApps(_apps, 'GMAIL').single.packageName, 'pkg.gmail');
    });

    test('no match returns an empty list', () {
      expect(rankApps(_apps, 'zzz'), isEmpty);
    });
  });
}

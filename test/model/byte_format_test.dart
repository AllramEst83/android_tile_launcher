import 'package:android_tile_launcher/model/byte_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatBytes', () {
    test('gigabytes with one decimal under 100', () {
      expect(formatBytes(42400000000), '42.4 GB');
    });

    test('gigabytes with no decimal from 100 up', () {
      expect(formatBytes(123600000000), '124 GB');
    });

    test('megabytes below a gigabyte', () {
      expect(formatBytes(812000000), '812 MB');
    });

    test('kilobytes below a megabyte', () {
      expect(formatBytes(340000), '340 KB');
    });

    test('bytes below a kilobyte', () {
      expect(formatBytes(95), '95 B');
    });

    test('zero is zero bytes', () {
      expect(formatBytes(0), '0 B');
    });
  });
}

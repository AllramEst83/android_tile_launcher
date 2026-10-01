import 'package:android_tile_launcher/model/file_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final DateTime now = DateTime(2026, 9, 27, 15, 0);

  test('null is empty', () {
    expect(formatFileDate(null, now), '');
  });

  test('today is just the time', () {
    expect(formatFileDate(DateTime(2026, 9, 27, 14, 32), now), '14:32');
  });

  test('another day is the date, without the weekday', () {
    expect(formatFileDate(DateTime(2026, 9, 20), now), '20 SEP');
  });
}

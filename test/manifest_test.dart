import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final String manifest = File('android/app/src/main/AndroidManifest.xml')
      .readAsStringSync();

  test('the launcher activity is locked to portrait', () {
    expect(manifest, contains('android:screenOrientation="portrait"'));
  });

  test('it can still be chosen as the Home app', () {
    expect(manifest, contains('android.intent.category.HOME'));
    expect(manifest, contains('android.intent.action.MAIN'));
  });
}

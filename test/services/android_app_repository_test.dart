import 'package:android_tile_launcher/services/android_app_repository.dart';
import 'package:android_tile_launcher/services/app_info.dart';
import 'package:android_tile_launcher/services/app_repository_exception.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const MethodChannel _channel = MethodChannel(AndroidAppRepository.channelName);
const String _self = 'com.codedbykay.android_tile_launcher';

/// Stands in for the Kotlin side; the real platform is never touched in tests.
void _mockChannel(Future<Object?>? Function(MethodCall call) handler) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_channel, handler);
}

Map<String, String> _entry(String label, String packageName) => {
  'label': label,
  'packageName': packageName,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => _mockChannel((call) async => null));

  AndroidAppRepository repository() =>
      AndroidAppRepository(ownPackage: _self, channel: _channel);

  test('maps entries and sorts case-insensitively by label', () async {
    _mockChannel(
      (call) async => [
        _entry('maps', 'pkg.maps'),
        _entry('Zoom', 'pkg.zoom'),
        _entry('Clock', 'pkg.clock'),
      ],
    );

    final apps = await repository().listApps();

    expect(apps, const [
      AppInfo(label: 'Clock', packageName: 'pkg.clock'),
      AppInfo(label: 'maps', packageName: 'pkg.maps'),
      AppInfo(label: 'Zoom', packageName: 'pkg.zoom'),
    ]);
  });

  test('excludes this app from the listing', () async {
    _mockChannel(
      (call) async => [_entry('Tiles', _self), _entry('Clock', 'pkg.clock')],
    );

    final apps = await repository().listApps();

    expect(apps.map((a) => a.packageName), ['pkg.clock']);
  });

  test('skips malformed entries and falls back to the package name', () async {
    _mockChannel(
      (call) async => [
        {'label': 'No package'},
        {'packageName': 'pkg.nolabel'},
        _entry('Clock', 'pkg.clock'),
      ],
    );

    final apps = await repository().listApps();

    expect(apps, const [
      AppInfo(label: 'Clock', packageName: 'pkg.clock'),
      AppInfo(label: 'pkg.nolabel', packageName: 'pkg.nolabel'),
    ]);
  });

  test('caches the list until an explicit refresh', () async {
    var queries = 0;
    _mockChannel((call) async {
      queries++;
      return [_entry('Clock', 'pkg.clock')];
    });
    final repo = repository();

    await repo.listApps();
    await repo.listApps();
    expect(queries, 1);

    await repo.listApps(refresh: true);
    expect(queries, 2);
  });

  test('a platform failure becomes an AppRepositoryException', () async {
    _mockChannel((call) async => throw PlatformException(code: 'LIST_FAILED'));

    expect(repository().listApps(), throwsA(isA<AppRepositoryException>()));
  });

  test('a failed listing is not cached', () async {
    var fail = true;
    _mockChannel((call) async {
      if (fail) throw PlatformException(code: 'LIST_FAILED');
      return [_entry('Clock', 'pkg.clock')];
    });
    final repo = repository();

    await expectLater(repo.listApps(), throwsA(isA<AppRepositoryException>()));
    fail = false;

    expect(await repo.listApps(), hasLength(1));
  });

  test('launch sends the package name and returns the result', () async {
    MethodCall? received;
    _mockChannel((call) async {
      received = call;
      return true;
    });

    final launched = await repository().launch('pkg.clock');

    expect(launched, isTrue);
    expect(received?.method, 'launch');
    expect(received?.arguments, {'packageName': 'pkg.clock'});
  });

  test('launch returns false when the platform says so', () async {
    _mockChannel((call) async => false);

    expect(await repository().launch('pkg.clock'), isFalse);
  });

  test('launch returns false instead of throwing on platform errors', () async {
    _mockChannel((call) async => throw PlatformException(code: 'BOOM'));

    expect(await repository().launch('pkg.clock'), isFalse);
  });

  test('uninstall sends the package name on its own method', () async {
    MethodCall? received;
    _mockChannel((call) async {
      received = call;
      return true;
    });

    final started = await repository().uninstall('pkg.clock');

    expect(started, isTrue);
    expect(received?.method, 'uninstall');
    expect(received?.arguments, {'packageName': 'pkg.clock'});
  });

  test(
    'uninstall returns false instead of throwing on platform errors',
    () async {
      _mockChannel((call) async => throw PlatformException(code: 'BOOM'));

      expect(await repository().uninstall('pkg.clock'), isFalse);
    },
  );

  test('openAppDetails sends the package name on its own method', () async {
    MethodCall? received;
    _mockChannel((call) async {
      received = call;
      return true;
    });

    final opened = await repository().openAppDetails('pkg.clock');

    expect(opened, isTrue);
    expect(received?.method, 'openAppDetails');
    expect(received?.arguments, {'packageName': 'pkg.clock'});
  });

  test(
    'openAppDetails returns false instead of throwing on platform errors',
    () async {
      _mockChannel((call) async => throw PlatformException(code: 'BOOM'));

      expect(await repository().openAppDetails('pkg.clock'), isFalse);
    },
  );
  group('icon', () {
    final Uint8List png = Uint8List.fromList(<int>[1, 2, 3, 4]);

    test(
      'asks for the package at the icon size, and returns the bytes',
      () async {
        MethodCall? received;
        _mockChannel((call) async {
          received = call;
          return png;
        });

        final Uint8List? icon = await repository().icon('pkg.clock');

        expect(icon, png);
        expect(received?.method, 'icon');
        expect(received?.arguments, {
          'packageName': 'pkg.clock',
          'size': AndroidAppRepository.iconPixels,
        });
      },
    );

    test(
      'asks the platform once for an app, however often it is wanted',
      () async {
        int calls = 0;
        _mockChannel((call) async {
          calls++;
          return png;
        });
        final AndroidAppRepository repo = repository();

        // Two at once, and one later.
        final List<Uint8List?> both = await Future.wait(<Future<Uint8List?>>[
          repo.icon('pkg.clock'),
          repo.icon('pkg.clock'),
        ]);
        await repo.icon('pkg.clock');

        expect(calls, 1);
        expect(both, <Uint8List?>[png, png]);
      },
    );

    test(
      'an app with no icon is null, and asked about again next time',
      () async {
        int calls = 0;
        _mockChannel((call) async {
          calls++;
          return null;
        });
        final AndroidAppRepository repo = repository();

        expect(await repo.icon('pkg.gone'), isNull);
        expect(await repo.icon('pkg.gone'), isNull);

        expect(calls, 2);
      },
    );

    test('an empty picture counts as none', () async {
      _mockChannel((call) async => Uint8List(0));

      expect(await repository().icon('pkg.clock'), isNull);
    });

    test('a platform error, or no handler, is null, never a throw', () async {
      _mockChannel((call) async => throw PlatformException(code: 'BOOM'));
      expect(await repository().icon('pkg.clock'), isNull);

      _mockChannel((call) => throw MissingPluginException());
      expect(await repository().icon('pkg.clock'), isNull);
    });

    test('the oldest icons are dropped past the limit', () async {
      final List<String> asked = <String>[];
      _mockChannel((call) async {
        asked.add(
          (call.arguments as Map<Object?, Object?>)['packageName']! as String,
        );
        return png;
      });
      final AndroidAppRepository repo = repository();

      for (int i = 0; i < AndroidAppRepository.maxIcons; i++) {
        await repo.icon('pkg.$i');
      }
      // One over: the first goes.
      await repo.icon('pkg.extra');
      asked.clear();
      await repo.icon('pkg.2'); // still remembered
      expect(asked, isEmpty);
      await repo.icon('pkg.0'); // forgotten, so asked again
      expect(asked, <String>['pkg.0']);
    });

    test('an icon in use outlives one that is not', () async {
      final List<String> asked = <String>[];
      _mockChannel((call) async {
        asked.add(
          (call.arguments as Map<Object?, Object?>)['packageName']! as String,
        );
        return png;
      });
      final AndroidAppRepository repo = repository();

      for (int i = 0; i < AndroidAppRepository.maxIcons; i++) {
        await repo.icon('pkg.$i');
      }
      await repo.icon('pkg.0'); // used again: now the newest
      await repo.icon('pkg.extra'); // pushes out pkg.1, not pkg.0
      asked.clear();
      await repo.icon('pkg.0');
      await repo.icon('pkg.1');

      expect(asked, <String>['pkg.1']);
    });
  });
}

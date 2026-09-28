import 'dart:io';

import 'package:android_tile_launcher/model/weather.dart';
import 'package:android_tile_launcher/model/weather_snapshot.dart';
import 'package:android_tile_launcher/services/live_weather_repository.dart';
import 'package:android_tile_launcher/services/local_store_exception.dart';
import 'package:android_tile_launcher/services/location_service.dart';
import 'package:android_tile_launcher/services/network_exception.dart';
import 'package:android_tile_launcher/services/weather.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_http_fetcher.dart';
import '../fakes/fake_location_service.dart';
import '../fakes/in_memory_local_store.dart';

String _forecast() =>
    File('test/fixtures/forecast_goteborg.json').readAsStringSync();

const _place = Place(
  name: 'Gothenburg',
  latitude: 57.70716,
  longitude: 11.96679,
);

const _here = LocationFound(
  latitude: 57.7,
  longitude: 11.97,
  name: 'Göteborg',
  region: 'Västra Götaland',
  country: 'Sweden',
);

class _Rig {
  _Rig({LocationResult? location, this.saved = true}) {
    fetcher.route('v1/forecast', _forecast());
    if (location != null) locationService.result = location;
    if (saved) store.write(Weather.homeKey, _place.toJson());
    repository = LiveWeatherRepository(
      weather: Weather(fetcher: fetcher, store: store),
      location: locationService,
      clock: () => now,
    );
  }

  final bool saved;
  final fetcher = FakeHttpFetcher();
  final store = InMemoryLocalStore();
  final locationService = FakeLocationService();
  late final LiveWeatherRepository repository;
  DateTime now = DateTime(2026, 9, 28, 12);

  int get forecastRequests =>
      fetcher.requests.where((u) => u.path.contains('forecast')).length;
}

void main() {
  group('current', () {
    test('needs a place until one is saved', () async {
      final rig = _Rig(saved: false);

      expect(await rig.repository.current(), isA<WeatherNeedsPlace>());
      expect(rig.forecastRequests, 0);
    });

    test('fetches the saved place\'s forecast', () async {
      final rig = _Rig();

      final snapshot = await rig.repository.current();

      expect(snapshot, isA<WeatherReady>());
      final ready = snapshot as WeatherReady;
      expect(ready.forecast.place.name, 'Gothenburg');
      expect(ready.stale, isFalse);
    });

    test('reuses a recent forecast instead of fetching again', () async {
      final rig = _Rig();

      await rig.repository.current();
      rig.now = rig.now.add(const Duration(minutes: 14));
      await rig.repository.current();

      expect(rig.forecastRequests, 1);
    });

    test('fetches afresh once the forecast is old', () async {
      final rig = _Rig();

      await rig.repository.current();
      rig.now = rig.now.add(const Duration(minutes: 16));
      await rig.repository.current();

      expect(rig.forecastRequests, 2);
    });

    test('fetches afresh when forced, however recent', () async {
      final rig = _Rig();

      await rig.repository.current();
      await rig.repository.current(force: true);

      expect(rig.forecastRequests, 2);
    });

    test('with no connection and nothing kept, is offline', () async {
      final rig = _Rig();
      rig.fetcher.route('v1/forecast', const NetworkException('no network'));

      final snapshot = await rig.repository.current();

      expect(snapshot, isA<WeatherOffline>());
      expect((snapshot as WeatherOffline).message, 'no network');
    });

    test(
      'keeps showing the last forecast, marked stale, if a refresh fails',
      () async {
        final rig = _Rig();
        await rig.repository.current();
        rig.fetcher.route('v1/forecast', const NetworkException('no network'));
        rig.now = rig.now.add(const Duration(hours: 1));

        final snapshot = await rig.repository.current();

        expect(snapshot, isA<WeatherReady>());
        expect((snapshot as WeatherReady).stale, isTrue);
      },
    );
  });

  group('locate', () {
    test('saves where the phone is and returns its forecast', () async {
      final rig = _Rig(location: _here, saved: false);

      final snapshot = await rig.repository.locate();

      expect(snapshot, isA<WeatherReady>());
      final place = (snapshot as WeatherReady).forecast.place;
      expect(place.name, 'Göteborg');
      expect(place.latitude, 57.7);
      expect(
        (await Weather(fetcher: rig.fetcher, store: rig.store).home())?.name,
        'Göteborg',
      );
    });

    test('names a place the geocoder could not', () async {
      final rig = _Rig(
        location: const LocationFound(latitude: 1, longitude: 2),
        saved: false,
      );

      final snapshot = await rig.repository.locate() as WeatherReady;

      expect(snapshot.forecast.place.name, 'HERE');
    });

    test('a new place replaces the forecast kept for the old one', () async {
      final rig = _Rig(location: _here);
      await rig.repository.current();

      await rig.repository.locate();

      expect(rig.forecastRequests, 2);
      expect(rig.fetcher.requests.last.queryParameters['latitude'], '57.7');
    });

    test('carries on for this run when the place cannot be saved', () async {
      final rig = _Rig(location: _here, saved: false);
      rig.store.failure = const LocalStoreException('disk full');

      final snapshot = await rig.repository.locate();

      expect(snapshot, isA<WeatherReady>());
      expect(await rig.repository.current(), isA<WeatherReady>());
    });

    test('reports a refusal, and whether it is permanent', () async {
      final rig = _Rig(
        location: const LocationDenied(permanent: true),
        saved: false,
      );

      final snapshot = await rig.repository.locate();

      expect(snapshot, isA<WeatherLocationDenied>());
      expect((snapshot as WeatherLocationDenied).permanent, isTrue);
    });

    test('reports why there is no position', () async {
      final rig = _Rig(
        location: const LocationUnavailable('location is switched off'),
        saved: false,
      );

      final snapshot = await rig.repository.locate();

      expect(snapshot, isA<WeatherLocationUnavailable>());
      expect(
        (snapshot as WeatherLocationUnavailable).reason,
        'location is switched off',
      );
    });

    test('a refusal is remembered, so the tile can keep showing it', () async {
      final rig = _Rig(
        location: const LocationDenied(permanent: false),
        saved: false,
      );

      await rig.repository.locate();
      final snapshot = await rig.repository.current();

      expect(snapshot, isA<WeatherLocationDenied>());
    });

    test('a later success clears the remembered refusal', () async {
      final rig = _Rig(
        location: const LocationDenied(permanent: false),
        saved: false,
      );
      await rig.repository.locate();
      rig.locationService.result = _here;

      await rig.repository.locate();

      expect(await rig.repository.current(), isA<WeatherReady>());
    });

    test('a second tap while the first is still asking joins it', () async {
      final rig = _Rig(location: _here, saved: false);

      final first = rig.repository.locate();
      final second = rig.repository.locate();
      await Future.wait([first, second]);

      expect(rig.locationService.calls, 1);
    });
  });
}

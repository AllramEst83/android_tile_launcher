import 'dart:convert';

import 'package:android_tile_launcher/model/weather.dart';
import 'package:android_tile_launcher/services/http_fetcher.dart';
import 'package:android_tile_launcher/services/local_store.dart';
import 'package:android_tile_launcher/services/local_store_exception.dart';
import 'package:android_tile_launcher/services/network_exception.dart';

/// Somewhere a forecast can come from. [Weather] asks its preferred one first
/// and falls back to Open-Meteo when that cannot answer.
abstract interface class ForecastSource {
  /// The forecast for [place]. Throws [NetworkException] when there is none to
  /// give: out of its area, unreachable, or an answer it could not read.
  Future<Forecast> forecast(Place place);
}

/// Weather: places come from Open-Meteo's geocoding service, and forecasts from
/// [preferred] when there is one and it can answer, else from Open-Meteo
/// (https://open-meteo.com, free, no key). Also remembers one home place.
class Weather {
  Weather({
    required this._fetcher,
    required this._store,
    this._days = 5,
    this._preferred,
  });

  static const homeKey = 'weather.home';

  final HttpFetcher _fetcher;
  final LocalStore _store;

  /// How many days the forecast covers, today included.
  final int _days;

  /// Tried first for every forecast (SMHI, which is better where it reaches).
  final ForecastSource? _preferred;

  /// The best match for [name], or null when there is none. Throws
  /// [NetworkException] when the service cannot be reached or misbehaves.
  Future<Place?> find(String name) async {
    final json = await _json(
      Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
        'name': name,
        'count': '1',
        'language': 'en',
        'format': 'json',
      }),
    );
    // No match at all is an answer without a `results` key.
    final results = json['results'];
    if (results == null) return null;
    if (results is! List) throw _unexpected;
    if (results.isEmpty) return null;
    for (final result in results) {
      try {
        return Place.fromJson({
          'name': _field(result, 'name'),
          'region': _field(result, 'admin1', optional: true),
          'country': _field(result, 'country', optional: true),
          'latitude': _field(result, 'latitude'),
          'longitude': _field(result, 'longitude'),
        });
      } on FormatException {
        continue;
      }
    }
    throw _unexpected;
  }

  Future<Forecast> forecast(Place place) async {
    final preferred = _preferred;
    if (preferred != null) {
      try {
        return await preferred.forecast(place);
      } on NetworkException catch (error) {
        // Outside its area (a 404), or it is down: Open-Meteo covers the
        // world. Out of area is normal and unremarkable; anything else is
        // reported with the answer, since the user would otherwise never know
        // the better source was failing.
        final forecast = await _openMeteo(place);
        return error.statusCode == 404
            ? forecast
            : forecast.withProblem(error.message);
      }
    }
    return _openMeteo(place);
  }

  Future<Forecast> _openMeteo(Place place) async {
    final json = await _json(
      Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': '${place.latitude}',
        'longitude': '${place.longitude}',
        'current': [
          'temperature_2m',
          'apparent_temperature',
          'relative_humidity_2m',
          'precipitation',
          'weather_code',
          'wind_speed_10m',
          'wind_direction_10m',
        ].join(','),
        'daily': [
          'weather_code',
          'temperature_2m_max',
          'temperature_2m_min',
          'precipitation_sum',
        ].join(','),
        'timezone': 'auto',
        'forecast_days': '$_days',
        'wind_speed_unit': 'ms',
      }),
    );
    try {
      return _parseForecast(place, json);
    } on FormatException {
      throw _unexpected;
    } on TypeError {
      throw _unexpected;
    }
  }

  Forecast _parseForecast(Place place, Map<String, Object?> json) {
    final current = json['current'] as Map<String, Object?>;
    final daily = json['daily'] as Map<String, Object?>;
    final dates = (daily['time'] as List).cast<String>();
    final codes = (daily['weather_code'] as List).cast<num>();
    final highs = (daily['temperature_2m_max'] as List).cast<num>();
    final lows = (daily['temperature_2m_min'] as List).cast<num>();
    final rain = (daily['precipitation_sum'] as List).cast<num>();
    final count = dates.length;
    if (count == 0 ||
        [codes, highs, lows, rain].any((list) => list.length != count)) {
      throw const FormatException('daily lists differ in length');
    }
    return Forecast(
      place: place,
      now: Conditions(
        temperature: (current['temperature_2m'] as num).toDouble(),
        feelsLike: (current['apparent_temperature'] as num).toDouble(),
        humidity: (current['relative_humidity_2m'] as num).round(),
        code: (current['weather_code'] as num).toInt(),
        windSpeed: (current['wind_speed_10m'] as num).toDouble(),
        windDirection: (current['wind_direction_10m'] as num).round(),
        precipitation: (current['precipitation'] as num).toDouble(),
      ),
      days: [
        for (var i = 0; i < count; i++)
          DayForecast(
            date: DateTime.parse(dates[i]),
            code: codes[i].toInt(),
            low: lows[i].toDouble(),
            high: highs[i].toDouble(),
            precipitation: rain[i].toDouble(),
          ),
      ],
    );
  }

  /// The saved home place, or null when none is saved or it cannot be read: a
  /// damaged setting is simply "not set".
  Future<Place?> home() async {
    try {
      final json = await _store.read(homeKey);
      return json == null ? null : Place.fromJson(json);
    } on LocalStoreException {
      return null;
    } on FormatException {
      return null;
    }
  }

  /// Throws [LocalStoreException] when it could not be saved.
  Future<void> setHome(Place place) => _store.write(homeKey, place.toJson());

  Future<void> clearHome() => _store.delete(homeKey);

  Future<Map<String, Object?>> _json(Uri url) async {
    final body = await _fetcher.get(url);
    try {
      final json = jsonDecode(body);
      if (json is Map<String, Object?>) return json;
    } on FormatException {
      // Falls through to the error below.
    }
    throw _unexpected;
  }

  Object? _field(Object? result, String key, {bool optional = false}) {
    if (result is Map && result[key] != null) return result[key];
    if (optional) return null;
    throw const FormatException('geocoding result is missing a field');
  }

  NetworkException get _unexpected =>
      const NetworkException('open-meteo.com sent an answer I could not read');
}

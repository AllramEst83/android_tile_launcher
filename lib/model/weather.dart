/// A named place on the map.
class Place {
  const Place({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.region,
    this.country,
  });

  final String name;

  /// County, state or the like, when the geocoder knows it.
  final String? region;
  final String? country;
  final double latitude;
  final double longitude;

  /// `Gothenburg, Västra Götaland County, Sweden`: enough to tell two places
  /// with the same name apart.
  String get label => [name, ?region, ?country].join(', ');

  Map<String, Object> toJson() => {
    'name': name,
    'region': ?region,
    'country': ?country,
    'latitude': latitude,
    'longitude': longitude,
  };

  /// Throws [FormatException] for anything [toJson] would not have written.
  factory Place.fromJson(Object? json) {
    if (json is! Map) throw const FormatException('place is not an object');
    final name = json['name'];
    final latitude = json['latitude'];
    final longitude = json['longitude'];
    final region = json['region'];
    final country = json['country'];
    if (name is! String ||
        latitude is! num ||
        longitude is! num ||
        (region != null && region is! String) ||
        (country != null && country is! String)) {
      throw const FormatException('place has missing or mistyped fields');
    }
    return Place(
      name: name,
      region: region as String?,
      country: country as String?,
      latitude: latitude.toDouble(),
      longitude: longitude.toDouble(),
    );
  }
}

/// Weather right now. Metric: °C, m/s, mm.
class Conditions {
  const Conditions({
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.code,
    required this.windSpeed,
    required this.windDirection,
    required this.precipitation,
  });

  final double temperature;
  final double feelsLike;

  /// Percent.
  final int humidity;

  /// WMO weather code; see `describeWeather`.
  final int code;
  final double windSpeed;

  /// Degrees the wind blows *from*, 0 = north.
  final int windDirection;
  final double precipitation;
}

class DayForecast {
  const DayForecast({
    required this.date,
    required this.code,
    required this.low,
    required this.high,
    required this.precipitation,
  });

  final DateTime date;
  final int code;
  final double low;
  final double high;

  /// Total for the day, mm.
  final double precipitation;
}

class Forecast {
  const Forecast({
    required this.place,
    required this.now,
    required this.days,
    this.source = 'Open-Meteo',
    this.station,
    this.problem,
  });

  final Place place;
  final Conditions now;

  /// Today first.
  final List<DayForecast> days;

  /// Who the figures are from, which the report must credit: `SMHI`,
  /// `Open-Meteo`.
  final String source;

  /// Where the current conditions were measured, when they were (`Göteborg A,
  /// 2 km`), instead of taken from the forecast.
  final String? station;

  /// Why the preferred source was not used, when it should have been (it broke,
  /// as opposed to simply not covering the place). Shown, so a fallback is
  /// never silent about something that is wrong.
  final String? problem;

  /// This forecast with [problem] added.
  Forecast withProblem(String problem) => Forecast(
    place: place,
    now: now,
    days: days,
    source: source,
    station: station,
    problem: problem,
  );
}

/// What the sky looks like, however it is worded: the picture that goes with a
/// WMO weather code.
enum WeatherKind {
  clear,
  partlyCloudy,
  cloudy,
  fog,
  drizzle,
  rain,
  snow,
  thunder,
}

/// The picture that goes with [code]. A code not listed is taken for cloud,
/// the safe middle.
WeatherKind weatherKind(int code) => switch (code) {
  0 || 1 => WeatherKind.clear,
  2 => WeatherKind.partlyCloudy,
  45 || 48 => WeatherKind.fog,
  >= 51 && <= 57 => WeatherKind.drizzle,
  >= 61 && <= 67 || >= 80 && <= 82 => WeatherKind.rain,
  >= 71 && <= 77 || 85 || 86 => WeatherKind.snow,
  // Sleet has no picture of its own: wet snow is the nearest.
  68 || 69 || 83 || 84 => WeatherKind.snow,
  >= 95 && <= 99 => WeatherKind.thunder,
  _ => WeatherKind.cloudy,
};

/// Plain-words descriptions of WMO weather codes, as Open-Meteo reports them
/// (plus the sleet ones SMHI's symbols map to). Upper case and short, for a
/// tile.
const _descriptions = {
  0: 'CLEAR',
  1: 'MOSTLY CLEAR',
  2: 'PARTLY CLOUDY',
  3: 'OVERCAST',
  45: 'FOG',
  48: 'RIME FOG',
  51: 'LIGHT DRIZZLE',
  53: 'DRIZZLE',
  55: 'HEAVY DRIZZLE',
  56: 'FREEZING DRIZZLE',
  57: 'FREEZING DRIZZLE',
  61: 'LIGHT RAIN',
  63: 'RAIN',
  65: 'HEAVY RAIN',
  66: 'FREEZING RAIN',
  67: 'FREEZING RAIN',
  68: 'LIGHT SLEET',
  69: 'HEAVY SLEET',
  71: 'LIGHT SNOW',
  73: 'SNOW',
  75: 'HEAVY SNOW',
  77: 'SNOW GRAINS',
  80: 'LIGHT SHOWERS',
  81: 'SHOWERS',
  82: 'HEAVY SHOWERS',
  83: 'SLEET SHOWERS',
  84: 'HEAVY SLEET',
  85: 'SNOW SHOWERS',
  86: 'HEAVY SNOW SHOWERS',
  95: 'THUNDERSTORM',
  96: 'THUNDER AND HAIL',
  99: 'THUNDER AND HAIL',
};

/// What [code] means, or a placeholder naming it for a code not listed.
String describeWeather(int code) => _descriptions[code] ?? 'WEATHER $code';

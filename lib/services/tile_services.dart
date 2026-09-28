import 'package:android_tile_launcher/services/agenda_repository.dart';
import 'package:android_tile_launcher/services/device_repository.dart';
import 'package:android_tile_launcher/services/system_control_service.dart';
import 'package:android_tile_launcher/services/weather_repository.dart';

/// The platform-backed collaborators live tiles read from, bundled so a new
/// tile kind's service is one more field here instead of one more parameter
/// through every widget between `main()` and `tileContent`.
class TileServices {
  const TileServices({
    required this.systemControl,
    required this.device,
    required this.weather,
    required this.agenda,
  });

  final SystemControlService systemControl;
  final DeviceRepository device;
  final WeatherRepository weather;
  final AgendaRepository agenda;
}

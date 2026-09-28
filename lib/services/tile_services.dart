import 'package:android_tile_launcher/services/agenda_repository.dart';
import 'package:android_tile_launcher/services/alarm_service.dart';
import 'package:android_tile_launcher/services/app_repository.dart';
import 'package:android_tile_launcher/services/clipboard_service.dart';
import 'package:android_tile_launcher/services/contacts_repository.dart';
import 'package:android_tile_launcher/services/device_repository.dart';
import 'package:android_tile_launcher/services/home_role_service.dart';
import 'package:android_tile_launcher/services/mail_service.dart';
import 'package:android_tile_launcher/services/phone_service.dart';
import 'package:android_tile_launcher/services/rates_repository.dart';
import 'package:android_tile_launcher/services/shade_service.dart';
import 'package:android_tile_launcher/services/sms_service.dart';
import 'package:android_tile_launcher/services/system_control_service.dart';
import 'package:android_tile_launcher/services/text_tv_repository.dart';
import 'package:android_tile_launcher/services/wallpaper_service.dart';
import 'package:android_tile_launcher/services/weather_repository.dart';
import 'package:android_tile_launcher/services/whatsapp_service.dart';

/// The platform-backed collaborators live tiles read from, bundled so a new
/// tile kind's service is one more field here instead of one more parameter
/// through every widget between `main()` and `tileContent`.
class TileServices {
  const TileServices({
    required this.systemControl,
    required this.device,
    required this.weather,
    required this.agenda,
    required this.contacts,
    required this.phone,
    required this.sms,
    required this.whatsApp,
    required this.mail,
    required this.textTv,
    required this.rates,
    required this.alarm,
    required this.homeRole,
    required this.clipboard,
    required this.shade,
    required this.wallpaper,
    required this.icons,
  });

  final SystemControlService systemControl;
  final DeviceRepository device;
  final WeatherRepository weather;
  final AgendaRepository agenda;
  final ContactsRepository contacts;
  final PhoneService phone;
  final SmsService sms;
  final WhatsAppService whatsApp;
  final MailService mail;
  final TextTvRepository textTv;
  final RatesRepository rates;
  final AlarmService alarm;

  /// Not for tiles: what the settings screen asks the phone.
  final HomeRoleService homeRole;
  final ClipboardService clipboard;

  /// Not for tiles either: what a swipe on Home can pull down.
  final ShadeService shade;

  /// Nor is this: the wallpaper the settings screen puts on the phone.
  final WallpaperService wallpaper;

  /// Where an app's tile gets its icon from (`AppRepository.icon`).
  final AppIconLoader icons;
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'services/android_alarm_service.dart';
import 'services/android_app_repository.dart';
import 'services/android_attachment_download_service.dart';
import 'services/android_calendar_service.dart';
import 'services/android_camera_service.dart';
import 'services/android_contacts_service.dart';
import 'services/android_device_repository.dart';
import 'services/android_files_service.dart';
import 'services/android_home_role_service.dart';
import 'services/android_link_service.dart';
import 'services/android_location_service.dart';
import 'services/android_media_service.dart';
import 'services/android_permission_service.dart';
import 'services/android_phone_service.dart';
import 'services/android_shade_service.dart';
import 'services/android_sms_service.dart';
import 'services/android_system_control_service.dart';
import 'services/android_wallpaper_service.dart';
import 'services/android_whatsapp_service.dart';
import 'services/cached_mail_service.dart';
import 'services/currency_rates.dart';
import 'services/first_run.dart';
import 'services/flutter_secret_store.dart';
import 'services/grid_state.dart';
import 'services/imap_mail_service.dart';
import 'services/io_http_fetcher.dart';
import 'services/launch_stats.dart';
import 'services/live_agenda_repository.dart';
import 'services/live_contacts_repository.dart';
import 'services/live_rates_repository.dart';
import 'services/live_text_tv_repository.dart';
import 'services/live_weather_repository.dart';
import 'services/mail_account.dart';
import 'services/settings_state.dart';
import 'services/shared_preferences_local_store.dart';
import 'services/smhi.dart';
import 'services/system_clipboard_service.dart';
import 'services/text_tv.dart';
import 'services/tile_services.dart';
import 'services/weather.dart';

const String _ownPackage = 'com.codedbykay.android_tile_launcher';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
  // Portrait only, here and in the manifest (which stops the rotation from
  // ever starting).
  unawaited(
    SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.portraitUp,
    ]),
  );

  final SharedPreferencesLocalStore store = SharedPreferencesLocalStore();
  final GridState gridState = GridState(store: store);
  await gridState.load();
  final SettingsState settingsState = SettingsState(store: store);
  await settingsState.load();
  final FirstRun firstRun = FirstRun(store: store);
  await firstRun.load();
  final LaunchStats launchStats = LaunchStats(store: store);
  await launchStats.load();
  final IoHttpFetcher fetcher = IoHttpFetcher();

  final AndroidAppRepository appRepository = AndroidAppRepository(
    ownPackage: _ownPackage,
  );

  runApp(
    TileLauncherApp(
      appRepository: appRepository,
      gridState: gridState,
      settingsState: settingsState,
      firstRun: firstRun,
      launchStats: launchStats,
      services: TileServices(
        systemControl: const AndroidSystemControlService(),
        device: const AndroidDeviceRepository(),
        contacts: const LiveContactsRepository(
          contacts: AndroidContactsService(),
          permissions: AndroidPermissionService(),
        ),
        phone: const AndroidPhoneService(
          permissions: AndroidPermissionService(),
        ),
        sms: const AndroidSmsService(permissions: AndroidPermissionService()),
        whatsApp: const AndroidWhatsAppService(),
        textTv: LiveTextTvRepository(textTv: TextTv(fetcher: fetcher)),
        alarm: const AndroidAlarmService(),
        homeRole: const AndroidHomeRoleService(),
        clipboard: const SystemClipboardService(),
        shade: const AndroidShadeService(),
        wallpaper: const AndroidWallpaperService(),
        icons: appRepository.icon,
        files: AndroidFilesService(),
        attachmentDownload: const AndroidAttachmentDownloadService(),
        camera: AndroidCameraService(
          permissions: const AndroidPermissionService(),
        ),
        link: const AndroidLinkService(),
        media: const AndroidMediaService(),
        rates: LiveRatesRepository(
          currencyRates: CurrencyRates(fetcher: fetcher, store: store),
        ),
        mail: CachedMailService(
          inner: ImapMailService(
            accounts: MailAccountStore(FlutterSecretStore()),
          ),
        ),
        agenda: LiveAgendaRepository(
          calendar: const AndroidCalendarService(
            permissions: AndroidPermissionService(),
          ),
          permissions: const AndroidPermissionService(),
        ),
        weather: LiveWeatherRepository(
          weather: Weather(
            fetcher: fetcher,
            store: store,
            preferred: Smhi(fetcher: fetcher),
          ),
          location: const AndroidLocationService(
            permissions: AndroidPermissionService(),
          ),
        ),
      ),
    ),
  );
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'services/android_app_repository.dart';
import 'services/android_calendar_service.dart';
import 'services/android_contacts_service.dart';
import 'services/android_device_repository.dart';
import 'services/android_location_service.dart';
import 'services/android_permission_service.dart';
import 'services/android_phone_service.dart';
import 'services/android_sms_service.dart';
import 'services/android_system_control_service.dart';
import 'services/android_whatsapp_service.dart';
import 'services/cached_mail_service.dart';
import 'services/flutter_secret_store.dart';
import 'services/grid_state.dart';
import 'services/imap_mail_service.dart';
import 'services/io_http_fetcher.dart';
import 'services/live_agenda_repository.dart';
import 'services/live_contacts_repository.dart';
import 'services/live_weather_repository.dart';
import 'services/mail_account.dart';
import 'services/shared_preferences_local_store.dart';
import 'services/smhi.dart';
import 'services/tile_services.dart';
import 'services/weather.dart';
import 'ui/theme.dart';

const String _ownPackage = 'com.codedbykay.android_tile_launcher';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: TileColors.canvas,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  final SharedPreferencesLocalStore store = SharedPreferencesLocalStore();
  final GridState gridState = GridState(store: store);
  await gridState.load();
  final IoHttpFetcher fetcher = IoHttpFetcher();

  runApp(
    TileLauncherApp(
      appRepository: AndroidAppRepository(ownPackage: _ownPackage),
      gridState: gridState,
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
        mail: CachedMailService(
          inner: ImapMailService(
            accounts: MailAccountStore(FlutterSecretStore()),
          ),
        ),
        agenda: LiveAgendaRepository(
          calendar: const AndroidCalendarService(),
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

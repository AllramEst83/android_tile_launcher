import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'services/android_app_repository.dart';
import 'services/android_device_repository.dart';
import 'services/android_system_control_service.dart';
import 'services/grid_state.dart';
import 'services/shared_preferences_local_store.dart';
import 'services/tile_services.dart';
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

  final GridState gridState = GridState(store: SharedPreferencesLocalStore());
  await gridState.load();

  runApp(
    TileLauncherApp(
      appRepository: AndroidAppRepository(ownPackage: _ownPackage),
      gridState: gridState,
      services: const TileServices(
        systemControl: AndroidSystemControlService(),
        device: AndroidDeviceRepository(),
      ),
    ),
  );
}

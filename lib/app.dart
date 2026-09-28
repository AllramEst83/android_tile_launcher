import 'package:flutter/material.dart';

import 'messages.dart';
import 'services/app_repository.dart';
import 'services/grid_state.dart';
import 'services/tile_services.dart';
import 'ui/home_shell.dart';
import 'ui/theme.dart';

class TileLauncherApp extends StatelessWidget {
  const TileLauncherApp({
    super.key,
    required this.appRepository,
    required this.gridState,
    required this.services,
  });

  final AppRepository appRepository;
  final GridState gridState;
  final TileServices services;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Messages.appTitle,
      debugShowCheckedModeBanner: false,
      theme: tileLauncherTheme(),
      home: HomeShell(
        appRepository: appRepository,
        gridState: gridState,
        services: services,
      ),
    );
  }
}

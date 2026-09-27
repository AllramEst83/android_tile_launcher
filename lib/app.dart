import 'package:flutter/material.dart';

import 'messages.dart';
import 'ui/home_shell.dart';
import 'ui/theme.dart';

class TileLauncherApp extends StatelessWidget {
  const TileLauncherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Messages.appTitle,
      debugShowCheckedModeBanner: false,
      theme: tileLauncherTheme(),
      home: const HomeShell(),
    );
  }
}

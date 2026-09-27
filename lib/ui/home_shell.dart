import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/services/app_info.dart';
import 'package:android_tile_launcher/services/app_repository.dart';
import 'package:android_tile_launcher/ui/app_tile_grid.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';

/// What Android shows when Home is pressed.
///
/// Back must never leave a launcher (there is nowhere to go), so the whole
/// shell is wrapped in a `PopScope` that refuses to pop. The boot screen is
/// also the loading and error state for the tile mosaic.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.appRepository});

  final AppRepository appRepository;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late Future<List<AppInfo>> _apps;

  @override
  void initState() {
    super.initState();
    _apps = widget.appRepository.listApps();
  }

  Future<void> _refresh() async {
    final Future<List<AppInfo>> next = widget.appRepository.listApps(
      refresh: true,
    );
    setState(() {
      _apps = next;
    });
    // Swallowed here: the FutureBuilder below is already watching `next` and
    // renders the error state itself once it completes.
    await next.then((_) {}, onError: (_) {});
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const RainbowRule(),
              Expanded(
                child: FutureBuilder<List<AppInfo>>(
                  future: _apps,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const _BootScreen(error: true);
                    }
                    final List<AppInfo>? apps = snapshot.data;
                    if (apps == null) return const _BootScreen();
                    return AppTileGrid(
                      apps: apps,
                      onLaunch: widget.appRepository.launch,
                      onRefresh: _refresh,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BootScreen extends StatelessWidget {
  const _BootScreen({this.error = false});

  final bool error;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(TileMetrics.margin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(Messages.bootBanner, style: text.bodyMedium),
          const SizedBox(height: TileMetrics.gutter),
          Text(Messages.bootMemory, style: text.bodyMedium),
          const SizedBox(height: TileMetrics.gutter * 2),
          Text(
            error ? Messages.appListError : Messages.bootReady,
            style: text.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// The Commodore stripe, drawn as five stacked bars.
class RainbowRule extends StatelessWidget {
  const RainbowRule({super.key, this.barHeight = 3});

  final double barHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final Color color in C64.rainbow)
          Container(height: barHeight, color: color),
      ],
    );
  }
}

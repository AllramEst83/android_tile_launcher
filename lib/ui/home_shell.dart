import 'package:flutter/material.dart';

import '../messages.dart';
import 'theme.dart';

/// What Android shows when Home is pressed.
///
/// Back must never leave a launcher (there is nowhere to go), so the whole
/// shell is wrapped in a `PopScope` that refuses to pop. The tile mosaic
/// replaces the boot screen in a later phase.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(TileMetrics.margin),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const RainbowRule(),
                const SizedBox(height: TileMetrics.gutter * 2),
                Text(Messages.bootBanner, style: text.bodyMedium),
                const SizedBox(height: TileMetrics.gutter),
                Text(Messages.bootMemory, style: text.bodyMedium),
                const SizedBox(height: TileMetrics.gutter * 2),
                Text(Messages.bootReady, style: text.bodyMedium),
              ],
            ),
          ),
        ),
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

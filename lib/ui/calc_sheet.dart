import 'dart:math' as math;

import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/services/rates_repository.dart';
import 'package:android_tile_launcher/ui/calc_pad.dart';
import 'package:android_tile_launcher/ui/convert_pad.dart';
import 'package:android_tile_launcher/ui/pad_key.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';

/// Keys so tests can find the parts.
const Key calcTabCalcKey = ValueKey<String>('calc-tab-calc');
const Key calcTabConvertKey = ValueKey<String>('calc-tab-convert');
const Key calcCloseKey = ValueKey<String>('calc-close');

/// What a tap on the calc tile opens: a sheet with a calculator and a
/// converter for units and money, a tab each, and a close key. Both keep what
/// was keyed while the other is showing.
Future<void> showCalcSheet(
  BuildContext context, {
  required RatesRepository rates,
  bool convert = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: TileColors.canvas,
    isScrollControlled: true,
    // Laid out below the status bar.
    useSafeArea: true,
    builder: (BuildContext sheetContext) {
      final MediaQueryData media = MediaQuery.of(sheetContext);
      return SizedBox(
        height: math.min(
          media.size.height * 0.92,
          media.size.height - media.padding.top - TileMetrics.margin,
        ),
        child: _CalcSheet(rates: rates, convert: convert),
      );
    },
  );
}

class _CalcSheet extends StatefulWidget {
  const _CalcSheet({required this.rates, required this.convert});

  final RatesRepository rates;
  final bool convert;

  @override
  State<_CalcSheet> createState() => _CalcSheetState();
}

class _CalcSheetState extends State<_CalcSheet> {
  late bool _convert = widget.convert;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(TileMetrics.margin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: PadKey(
                    key: calcTabCalcKey,
                    label: Messages.calcTabCalc,
                    selected: !_convert,
                    height: 44,
                    fontSize: 12,
                    onTap: () => setState(() => _convert = false),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: PadKey(
                    key: calcTabConvertKey,
                    label: Messages.calcTabConvert,
                    selected: _convert,
                    height: 44,
                    fontSize: 12,
                    onTap: () => setState(() => _convert = true),
                  ),
                ),
                const SizedBox(width: TileMetrics.gutter),
                SizedBox(
                  width: 48,
                  child: PadKey(
                    key: calcCloseKey,
                    label: 'X',
                    height: 44,
                    fontSize: 12,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: TileMetrics.gutter),
            Expanded(
              child: SingleChildScrollView(
                // Both pads stay built, so switching tabs keeps what was keyed.
                child: IndexedStack(
                  index: _convert ? 1 : 0,
                  children: <Widget>[
                    const CalcPad(),
                    ConvertPad(rates: widget.rates),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

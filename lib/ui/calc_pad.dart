import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/calc_entry.dart';
import 'package:android_tile_launcher/ui/pad_key.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';

/// Keys so tests can find the parts.
Key calcKey(String key) => ValueKey<String>('calc-key-$key');
const Key calcExpressionKey = ValueKey<String>('calc-expression');
const Key calcPreviewKey = ValueKey<String>('calc-preview');
const Key calcErrorKey = ValueKey<String>('calc-error');

/// The functions and constants, in a strip above the number keys. A function's
/// key types its opening bracket with it.
const List<String> calcFunctionKeys = <String>[
  '^',
  '%',
  'pi',
  'e',
  'sqrt(',
  'abs(',
  'sin(',
  'cos(',
  'tan(',
  'ln(',
  'log(',
  'exp(',
  'floor(',
  'ceil(',
  'round(',
  'asin(',
  'acos(',
  'atan(',
];

/// The calculator: what has been keyed, the answer so far under it, and the
/// keys. All the rules are in [CalcEntry]; this only draws it and passes keys.
class CalcPad extends StatefulWidget {
  const CalcPad({super.key});

  @override
  State<CalcPad> createState() => _CalcPadState();
}

class _CalcPadState extends State<CalcPad> {
  CalcEntry _entry = const CalcEntry();

  void _press(String key) => setState(() {
    _entry = switch (key) {
      'C' => _entry.clear(),
      'DEL' => _entry.backspace(),
      '=' => _entry.equals(),
      _ => _entry.press(key),
    };
  });

  Widget _key(String label, {String? key, bool accent = false}) => PadKey(
    key: calcKey(key ?? label),
    label: label,
    accent: accent,
    onTap: () => _press(key ?? label),
  );

  @override
  Widget build(BuildContext context) {
    final String? error = _entry.error;
    final String? preview = _entry.preview;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          height: 96,
          padding: const EdgeInsets.symmetric(vertical: TileMetrics.gutter),
          alignment: Alignment.bottomRight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  _entry.isEmpty ? '0' : _entry.expression,
                  key: calcExpressionKey,
                  style: TextStyle(
                    fontFamily: kPixelFontFamily,
                    fontSize: 24,
                    color: _entry.isEmpty
                        ? TileColors.textDim
                        : TileColors.textBright,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              if (error != null)
                Text(
                  error.toUpperCase(),
                  key: calcErrorKey,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontFamily: kPixelFontFamily,
                    fontSize: 8,
                    color: C64.lightRed,
                  ),
                )
              else if (preview != null)
                Text(
                  '= $preview',
                  key: calcPreviewKey,
                  style: const TextStyle(
                    fontFamily: kPixelFontFamily,
                    fontSize: 12,
                    color: C64.cyan,
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 44,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                for (final String key in calcFunctionKeys) ...<Widget>[
                  PadKey(
                    key: calcKey(key),
                    label: key.replaceAll('(', ''),
                    height: 40,
                    fontSize: 10,
                    accent: true,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    onTap: () => _press(key),
                  ),
                  const SizedBox(width: 4),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        PadRow(
          keys: <(Widget, int)>[
            (_key(Messages.calcClear, accent: true), 1),
            (_key('('), 1),
            (_key(')'), 1),
            (_key('/'), 1),
          ],
        ),
        PadRow(
          keys: <(Widget, int)>[
            (_key('7'), 1),
            (_key('8'), 1),
            (_key('9'), 1),
            (_key('*'), 1),
          ],
        ),
        PadRow(
          keys: <(Widget, int)>[
            (_key('4'), 1),
            (_key('5'), 1),
            (_key('6'), 1),
            (_key('-'), 1),
          ],
        ),
        PadRow(
          keys: <(Widget, int)>[
            (_key('1'), 1),
            (_key('2'), 1),
            (_key('3'), 1),
            (_key('+'), 1),
          ],
        ),
        PadRow(
          keys: <(Widget, int)>[
            (_key('0'), 1),
            (_key('.'), 1),
            (_key(Messages.calcDelete, accent: true), 1),
            (_key(Messages.calcEquals, accent: true), 1),
          ],
        ),
      ],
    );
  }
}

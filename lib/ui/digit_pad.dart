import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/ui/pad_key.dart';
import 'package:flutter/material.dart';

/// A number pad, 1 to 9 then C, 0 and DEL, for keying a length of time or a
/// time of day. [keyPrefix] names its keys (`<prefix>-1` ... `<prefix>-clear`,
/// `<prefix>-delete`) so two pads built at once can be told apart.
class DigitPad extends StatelessWidget {
  const DigitPad({
    super.key,
    required this.keyPrefix,
    required this.onDigit,
    required this.onDelete,
    required this.onClear,
  });

  final String keyPrefix;
  final ValueChanged<int> onDigit;
  final VoidCallback onDelete;
  final VoidCallback onClear;

  /// The key for digit [digit] on the pad named [keyPrefix].
  static Key digitKey(String keyPrefix, int digit) =>
      ValueKey<String>('$keyPrefix-$digit');
  static Key clearKey(String keyPrefix) => ValueKey<String>('$keyPrefix-clear');
  static Key deleteKey(String keyPrefix) =>
      ValueKey<String>('$keyPrefix-delete');

  Widget _digit(int digit) => PadKey(
    key: digitKey(keyPrefix, digit),
    label: '$digit',
    onTap: () => onDigit(digit),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final int row in <int>[0, 1, 2])
          PadRow(
            keys: <(Widget, int)>[
              for (final int d in <int>[row * 3 + 1, row * 3 + 2, row * 3 + 3])
                (_digit(d), 1),
            ],
          ),
        PadRow(
          keys: <(Widget, int)>[
            (
              PadKey(
                key: clearKey(keyPrefix),
                label: Messages.calcClear,
                accent: true,
                onTap: onClear,
              ),
              1,
            ),
            (_digit(0), 1),
            (
              PadKey(
                key: deleteKey(keyPrefix),
                label: Messages.calcDelete,
                accent: true,
                fontSize: 12,
                onTap: onDelete,
              ),
              1,
            ),
          ],
        ),
      ],
    );
  }
}

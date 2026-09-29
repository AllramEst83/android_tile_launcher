import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';

/// A small "X" that clears a search field — a fixed-size trailing sibling
/// (a `Row`'s last child, beside the field itself, not an `InputDecoration
/// .suffixIcon`: the decorator's own suffix slot crowded out the field's
/// entered text in practice, an explicit size here does not), shown only
/// while the caller says there is something to clear. This app's own
/// plain-text glyph convention (`PadKey`'s "X" close button), not a platform
/// icon, so it reads as part of the same launcher rather than a borrowed
/// control.
class ClearFieldButton extends StatelessWidget {
  const ClearFieldButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: Text(
            'X',
            style: TextStyle(
              fontFamily: kPixelFontFamily,
              fontSize: 14,
              color: TileColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}

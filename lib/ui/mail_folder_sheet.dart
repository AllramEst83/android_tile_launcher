import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/mail.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';

/// Keys so tests can find the parts.
Key mailFolderChoiceKey(String name) => ValueKey<String>('mail-folder-$name');

/// The account's folders to pick from; the one tapped, or null if the sheet
/// was dismissed. The inbox is always offered, even when the server listed no
/// folders.
Future<MailFolder?> showMailFolderSheet(
  BuildContext context, {
  required List<MailFolder> folders,
  required MailFolder current,
}) {
  final List<MailFolder> shown =
      folders.any((MailFolder f) => f.kind == MailFolderKind.inbox)
      ? folders
      : <MailFolder>[
          const MailFolder(
            name: '',
            label: 'INBOX',
            kind: MailFolderKind.inbox,
          ),
          ...folders,
        ];
  return showModalBottomSheet<MailFolder>(
    context: context,
    backgroundColor: TileColors.canvas,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext sheetContext) {
      final TextTheme text = Theme.of(sheetContext).textTheme;
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.7,
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(TileMetrics.margin),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: TileMetrics.gutter),
                Text(
                  Messages.mailFolders,
                  style: text.bodyMedium?.copyWith(
                    color: TileColors.textBright,
                  ),
                ),
                const SizedBox(height: 4),
                Container(height: 2, color: TileColors.bezel),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: <Widget>[
                      for (final MailFolder f in shown)
                        InkWell(
                          key: mailFolderChoiceKey(f.name),
                          onTap: () => Navigator.of(sheetContext).pop(f),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: TileColors.bezel),
                              ),
                            ),
                            child: Text(
                              '${f.name == current.name ? '> ' : '  '}${f.label}',
                              style: text.bodySmall?.copyWith(
                                fontSize: 12,
                                color: f.name == current.name
                                    ? TileColors.highlight
                                    : TileColors.textBright,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

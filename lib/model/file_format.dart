import 'package:android_tile_launcher/model/clock_format.dart';

/// When a file or folder was last modified, short: `14:32` if today, else
/// `28 SEP`; empty if it is unknown. The same shape `formatMailDate` uses,
/// kept as its own copy rather than a shared import — files and mail stay
/// decoupled.
String formatFileDate(DateTime? modified, DateTime now) {
  if (modified == null) return '';
  final bool today =
      modified.year == now.year &&
      modified.month == now.month &&
      modified.day == now.day;
  if (today) return formatClockTime(modified);
  // `FRI 27 SEP` without the weekday.
  return formatClockDate(modified).substring(4);
}

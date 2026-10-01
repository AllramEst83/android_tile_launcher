/// A tile's footprint on the mosaic, in whole columns and base rows. The
/// [columns] are for the default four-column mosaic; [spanIn] says how many a
/// tile takes on the mosaic that is really drawn (four or six columns).
///
/// The eight original named sizes (small/flat/tall/medium/broad/wide/tower/
/// large) keep their names — layouts already saved under those names must
/// keep reading back the same shape. Every other width (1–4 columns) by
/// height (1–6 rows) combination the user asked for by name in Phase 35
/// ("1x1, 1x2, ... 2x1, 3x1, 4x1, and so on") is filled in alongside them
/// under a systematic `sizeCxR` name, since none of them needs a word: the
/// resize picker (`ui/tile_size_grid_picker.dart`) already labels every size
/// from its plain `columns`/`rows` numbers, not its enum name.
///
/// Phase 42 added a further 12: columns 5 and 6, still by 1–6 rows, once the
/// user pointed out that a 6-column mosaic (`LauncherSettings.columnChoices`)
/// could only ever reach its own two extra columns through `wide`/`large`
/// stretching to fill them, never as an ordinary, non-stretched tile width —
/// these are that. Only meaningful on a 6-column mosaic; on a 4-column one
/// [spanIn] clamps them to 4, the same as any tile wider than the mosaic
/// showing it, already true for these two columns before this phase existed
/// to make a size that wide reachable in the first place.
///
/// [size4x2] and [size4x4] share their shape with [wide] and [large] but are
/// plain 4-column tiles: on a 6-column mosaic the picker's fourth column used
/// to resolve to [wide]/[large], which stretch to all 6, so the tile came out
/// full width while the picker showed 4. [of] returns these instead.
enum TileSize {
  small(columns: 1, rows: 1),
  flat(columns: 2, rows: 1),
  tall(columns: 1, rows: 2),
  medium(columns: 2, rows: 2),
  broad(columns: 3, rows: 2),
  wide(columns: 4, rows: 2, fullWidth: true),
  tower(columns: 2, rows: 4),
  large(columns: 4, rows: 4, fullWidth: true),

  size1x3(columns: 1, rows: 3),
  size1x4(columns: 1, rows: 4),
  size1x5(columns: 1, rows: 5),
  size1x6(columns: 1, rows: 6),
  size2x3(columns: 2, rows: 3),
  size2x5(columns: 2, rows: 5),
  size2x6(columns: 2, rows: 6),
  size3x1(columns: 3, rows: 1),
  size3x3(columns: 3, rows: 3),
  size3x4(columns: 3, rows: 4),
  size3x5(columns: 3, rows: 5),
  size3x6(columns: 3, rows: 6),
  size4x1(columns: 4, rows: 1),
  size4x3(columns: 4, rows: 3),
  size4x5(columns: 4, rows: 5),
  size4x6(columns: 4, rows: 6),

  size5x1(columns: 5, rows: 1),
  size5x2(columns: 5, rows: 2),
  size5x3(columns: 5, rows: 3),
  size5x4(columns: 5, rows: 4),
  size5x5(columns: 5, rows: 5),
  size5x6(columns: 5, rows: 6),
  size6x1(columns: 6, rows: 1),
  size6x2(columns: 6, rows: 2),
  size6x3(columns: 6, rows: 3),
  size6x4(columns: 6, rows: 4),
  size6x5(columns: 6, rows: 5),
  size6x6(columns: 6, rows: 6),

  size4x2(columns: 4, rows: 2),
  size4x4(columns: 4, rows: 4);

  const TileSize({
    required this.columns,
    required this.rows,
    this.fullWidth = false,
  });

  final int columns;
  final int rows;

  /// Whether this size always spans the full width of the mosaic, however
  /// many columns that is, rather than keeping its own [columns] count. Only
  /// [wide] and [large] do this — they are hero bands, not fixed-width tiles.
  final bool fullWidth;

  /// How many columns this size takes on a mosaic of [gridColumns]: its own
  /// [columns], clamped to the grid's width, or the grid's full width if
  /// [fullWidth].
  int spanIn(int gridColumns) =>
      fullWidth ? gridColumns : (columns < gridColumns ? columns : gridColumns);

  /// The size that is exactly [columns] by [rows] — every 1–6 by 1–6
  /// combination has one, Phase 37's grid picker's whole premise (widened to
  /// 6 columns in Phase 42), so this never returns `null` for an in-range
  /// request. Never a [fullWidth] size: a picked or flipped shape must keep
  /// the width it was picked at, whatever the mosaic's column count. Out of range (a picker bug, not a real tile) falls back to
  /// [small] rather than throwing, the same never-crash-the-editor spirit as
  /// the rest of this app's UI code.
  static TileSize of(int columns, int rows) => values.firstWhere(
    (TileSize size) =>
        !size.fullWidth && size.columns == columns && size.rows == rows,
    orElse: () => small,
  );
}

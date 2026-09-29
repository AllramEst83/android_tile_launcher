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
/// resize picker (`tile_inspector.dart`'s `_SizeButton`) already labels every
/// size from its plain `columns`/`rows` numbers, not its enum name.
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
  size4x6(columns: 4, rows: 6);

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
}

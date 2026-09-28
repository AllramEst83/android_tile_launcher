/// A tile's footprint on the mosaic, in whole columns and base rows. The
/// [columns] are for the default four-column mosaic; [spanIn] says how many a
/// tile takes on the mosaic that is really drawn (four or six columns).
enum TileSize {
  small(columns: 1, rows: 1),
  flat(columns: 2, rows: 1),
  tall(columns: 1, rows: 2),
  medium(columns: 2, rows: 2),
  broad(columns: 3, rows: 2),
  wide(columns: 4, rows: 2, fullWidth: true),
  tower(columns: 2, rows: 4),
  large(columns: 4, rows: 4, fullWidth: true);

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

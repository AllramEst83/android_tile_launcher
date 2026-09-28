/// A tile's footprint on the mosaic, in whole columns and base rows. The
/// [columns] are for the default four-column mosaic; [spanIn] says how many a
/// tile takes on the mosaic that is really drawn (four or six columns).
enum TileSize {
  small(columns: 1, rows: 1),
  medium(columns: 2, rows: 2),
  wide(columns: 4, rows: 2),
  large(columns: 4, rows: 4);

  const TileSize({required this.columns, required this.rows});

  final int columns;
  final int rows;

  /// How many columns this size takes on a mosaic of [gridColumns]: a small
  /// tile one, a medium two, and a wide or large one the full width, however
  /// many columns that is.
  int spanIn(int gridColumns) => switch (this) {
    TileSize.small => 1,
    TileSize.medium => columns < gridColumns ? columns : gridColumns,
    TileSize.wide || TileSize.large => gridColumns,
  };
}

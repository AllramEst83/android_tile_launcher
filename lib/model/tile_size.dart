/// A tile's footprint on the 4-column mosaic, in whole columns and base rows.
enum TileSize {
  small(columns: 1, rows: 1),
  medium(columns: 2, rows: 2),
  wide(columns: 4, rows: 2),
  large(columns: 4, rows: 4);

  const TileSize({required this.columns, required this.rows});

  final int columns;
  final int rows;
}

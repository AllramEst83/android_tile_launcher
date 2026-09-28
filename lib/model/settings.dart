/// How the launcher looks: the screen it draws on.
enum ThemeVariant {
  /// The C64 power-on screen: light blue on blue. The default.
  c64('C64'),

  /// A pitch-black canvas, so an OLED screen lights only what is drawn.
  oled('OLED'),

  /// The beige hardware of the C64's case: dark brown on beige.
  beige('BEIGE');

  const ThemeVariant(this.label);

  final String label;
}

/// The space between tiles on the home mosaic.
enum GridGap {
  tight(4, 'TIGHT'),
  normal(8, 'NORMAL'),
  relaxed(14, 'RELAXED');

  const GridGap(this.pixels, this.label);

  final double pixels;
  final String label;
}

/// What a swipe on the home screen does.
enum GestureAction {
  none('NOTHING'),

  /// Pull down to read the list of installed apps again (the default).
  refreshApps('REFRESH APPS'),

  /// Pull down the notification shade.
  notifications('NOTIFICATIONS'),

  /// Pull down the quick settings.
  quickSettings('QUICK SETTINGS'),

  /// The app drawer with its search field ready to type in.
  searchApps('SEARCH APPS'),

  /// The app drawer.
  allApps('ALL APPS');

  const GestureAction(this.label);

  final String label;
}

/// The choices the settings screen offers, and what each is set to until it is
/// changed.
class LauncherSettings {
  const LauncherSettings({
    this.theme = ThemeVariant.c64,
    this.columns = 4,
    this.gap = GridGap.normal,
    this.swipeDown = GestureAction.refreshApps,
    this.swipeUp = GestureAction.none,
  });

  final ThemeVariant theme;

  /// Columns on the home mosaic: 4 or 6.
  final int columns;
  final GridGap gap;

  /// What pulling down at the top of home does, and what pushing up at the
  /// bottom of it does.
  final GestureAction swipeDown;
  final GestureAction swipeUp;

  /// The column counts the settings screen offers.
  static const List<int> columnChoices = <int>[4, 6];

  /// What a swipe down may be set to, and a swipe up.
  static const List<GestureAction> swipeDownChoices = <GestureAction>[
    GestureAction.refreshApps,
    GestureAction.notifications,
    GestureAction.quickSettings,
    GestureAction.none,
  ];
  static const List<GestureAction> swipeUpChoices = <GestureAction>[
    GestureAction.none,
    GestureAction.searchApps,
    GestureAction.allApps,
  ];

  LauncherSettings copyWith({
    ThemeVariant? theme,
    int? columns,
    GridGap? gap,
    GestureAction? swipeDown,
    GestureAction? swipeUp,
  }) => LauncherSettings(
    theme: theme ?? this.theme,
    columns: columns ?? this.columns,
    gap: gap ?? this.gap,
    swipeDown: swipeDown ?? this.swipeDown,
    swipeUp: swipeUp ?? this.swipeUp,
  );

  Map<String, Object?> toJson() => <String, Object?>{
    'theme': theme.name,
    'columns': columns,
    'gap': gap.name,
    'swipeDown': swipeDown.name,
    'swipeUp': swipeUp.name,
  };

  /// Settings from what [toJson] wrote. Never throws: a choice that is missing,
  /// malformed or not one the screen offers keeps its default, so a damaged
  /// saved value costs one setting, never the launcher.
  static LauncherSettings fromJson(Object? json) {
    const LauncherSettings defaults = LauncherSettings();
    if (json is! Map) return defaults;
    T pick<T extends Enum>(List<T> values, Object? name, T fallback) {
      for (final T value in values) {
        if (value.name == name) return value;
      }
      return fallback;
    }

    final Object? columns = json['columns'];
    final GestureAction down = pick(
      GestureAction.values,
      json['swipeDown'],
      defaults.swipeDown,
    );
    final GestureAction up = pick(
      GestureAction.values,
      json['swipeUp'],
      defaults.swipeUp,
    );
    return LauncherSettings(
      theme: pick(ThemeVariant.values, json['theme'], defaults.theme),
      columns: columnChoices.contains(columns)
          ? columns! as int
          : defaults.columns,
      gap: pick(GridGap.values, json['gap'], defaults.gap),
      swipeDown: swipeDownChoices.contains(down) ? down : defaults.swipeDown,
      swipeUp: swipeUpChoices.contains(up) ? up : defaults.swipeUp,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is LauncherSettings &&
      other.theme == theme &&
      other.columns == columns &&
      other.gap == gap &&
      other.swipeDown == swipeDown &&
      other.swipeUp == swipeUp;

  @override
  int get hashCode => Object.hash(theme, columns, gap, swipeDown, swipeUp);

  @override
  String toString() =>
      'LauncherSettings($theme, $columns columns, $gap, down: $swipeDown, up: $swipeUp)';
}

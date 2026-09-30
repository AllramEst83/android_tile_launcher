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

/// How large every text style in the launcher is drawn, as a multiplier on
/// top of whatever the phone's own accessibility text size already asks for
/// (so this setting only ever makes text bigger or smaller than that, never
/// overrides it outright).
enum FontScale {
  small(0.9, 'SMALL'),
  normal(1.0, 'NORMAL'),
  large(1.15, 'LARGE'),
  extraLarge(1.3, 'EXTRA LARGE');

  const FontScale(this.factor, this.label);

  final double factor;
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
    this.fontScale = FontScale.normal,
    this.swipeDown = GestureAction.refreshApps,
    this.swipeUp = GestureAction.none,
    this.haptics = true,
    this.effects = true,
    this.appIcons = true,
    this.agendaWeekView = false,
    this.agendaGridView = false,
  });

  final ThemeVariant theme;

  /// Columns on the home mosaic: 4 or 6.
  final int columns;
  final GridGap gap;
  final FontScale fontScale;

  /// What pulling down at the top of home does, and what pushing up at the
  /// bottom of it does.
  final GestureAction swipeDown;
  final GestureAction swipeUp;

  /// A short buzz on a tile or key press and on long-press.
  final bool haptics;

  /// The faint scanlines, shine and dithered shade drawn over every tile.
  final bool effects;

  /// Each app's own icon on its home tile and its drawer row.
  final bool appIcons;

  /// The agenda sheet's last-chosen tab: `false` for DAY, `true` for WEEK.
  /// Not offered on the settings screen — it is remembered UI state, not a
  /// deliberate preference — but it rides along in the same saved blob
  /// rather than inventing a second store for one bool.
  final bool agendaWeekView;

  /// Whether the week tab last showed as the time-grid ("WEEK:GRID") rather
  /// than the list. Meaningless while [agendaWeekView] is false; remembered
  /// UI state the same way that is.
  final bool agendaGridView;

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
    FontScale? fontScale,
    GestureAction? swipeDown,
    GestureAction? swipeUp,
    bool? haptics,
    bool? effects,
    bool? appIcons,
    bool? agendaWeekView,
    bool? agendaGridView,
  }) => LauncherSettings(
    theme: theme ?? this.theme,
    columns: columns ?? this.columns,
    gap: gap ?? this.gap,
    fontScale: fontScale ?? this.fontScale,
    swipeDown: swipeDown ?? this.swipeDown,
    swipeUp: swipeUp ?? this.swipeUp,
    haptics: haptics ?? this.haptics,
    effects: effects ?? this.effects,
    appIcons: appIcons ?? this.appIcons,
    agendaWeekView: agendaWeekView ?? this.agendaWeekView,
    agendaGridView: agendaGridView ?? this.agendaGridView,
  );

  Map<String, Object?> toJson() => <String, Object?>{
    'theme': theme.name,
    'columns': columns,
    'gap': gap.name,
    'fontScale': fontScale.name,
    'swipeDown': swipeDown.name,
    'swipeUp': swipeUp.name,
    'haptics': haptics,
    'effects': effects,
    'appIcons': appIcons,
    'agendaWeekView': agendaWeekView,
    'agendaGridView': agendaGridView,
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
      fontScale: pick(FontScale.values, json['fontScale'], defaults.fontScale),
      swipeDown: swipeDownChoices.contains(down) ? down : defaults.swipeDown,
      swipeUp: swipeUpChoices.contains(up) ? up : defaults.swipeUp,
      haptics: json['haptics'] is bool
          ? json['haptics']! as bool
          : defaults.haptics,
      effects: json['effects'] is bool
          ? json['effects']! as bool
          : defaults.effects,
      appIcons: json['appIcons'] is bool
          ? json['appIcons']! as bool
          : defaults.appIcons,
      agendaWeekView: json['agendaWeekView'] is bool
          ? json['agendaWeekView']! as bool
          : defaults.agendaWeekView,
      agendaGridView: json['agendaGridView'] is bool
          ? json['agendaGridView']! as bool
          : defaults.agendaGridView,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is LauncherSettings &&
      other.theme == theme &&
      other.columns == columns &&
      other.gap == gap &&
      other.fontScale == fontScale &&
      other.swipeDown == swipeDown &&
      other.swipeUp == swipeUp &&
      other.haptics == haptics &&
      other.effects == effects &&
      other.appIcons == appIcons &&
      other.agendaWeekView == agendaWeekView &&
      other.agendaGridView == agendaGridView;

  @override
  int get hashCode => Object.hash(
    theme,
    columns,
    gap,
    fontScale,
    swipeDown,
    swipeUp,
    haptics,
    effects,
    appIcons,
    agendaWeekView,
    agendaGridView,
  );

  @override
  String toString() =>
      'LauncherSettings($theme, $columns columns, $gap, $fontScale, down: $swipeDown, up: $swipeUp, haptics: $haptics, effects: $effects, appIcons: $appIcons, agendaWeekView: $agendaWeekView, agendaGridView: $agendaGridView)';
}

/// One of the Scene tile's short, continuously looping animations — the
/// simplest kind of "fun" visual this app draws: a handful of fixed ASCII
/// frames swapped on a timer, in the tile's own single ink colour like every
/// other tile (never a second colour or a picture asset), so it reads as one
/// more C64 screen rather than a different kind of graphic. More arrive the
/// same way these three did: a case here and a frame list below.
enum SceneAnimation {
  rocket('ROCKET LAUNCH'),
  palmTree('PALM TREE'),
  flower('FLOWER');

  const SceneAnimation(this.label);

  final String label;
}

/// [animation]'s frames, each the same number of lines so the tile never
/// changes size as it loops. Looked up rather than carried on the enum
/// itself (unlike every other enum's own `.label` elsewhere in `model/`)
/// because block art this size reads far better as its own top-level
/// constant than crammed into an enum constructor call.
List<List<String>> framesOf(SceneAnimation animation) => switch (animation) {
  SceneAnimation.rocket => _rocketFrames,
  SceneAnimation.palmTree => _palmTreeFrames,
  SceneAnimation.flower => _flowerFrames,
};

/// A flickering engine flame under an otherwise still rocket — simpler than
/// animating actual lift-off, and reads just as well at tile size.
const List<List<String>> _rocketFrames = <List<String>>[
  <String>[
    '   /\\',
    '  /  \\',
    ' |    |',
    ' | () |',
    ' |    |',
    ' /----\\',
    '   ^^',
  ],
  <String>[
    '   /\\',
    '  /  \\',
    ' |    |',
    ' | () |',
    ' |    |',
    ' /----\\',
    '  ^^^^',
  ],
  <String>[
    '   /\\',
    '  /  \\',
    ' |    |',
    ' | () |',
    ' |    |',
    ' /----\\',
    ' ^^^^^^',
  ],
  <String>[
    '   /\\',
    '  /  \\',
    ' |    |',
    ' | () |',
    ' |    |',
    ' /----\\',
    '  ^^^^',
  ],
];

/// The shoreline washing in and out while the trunk leans a little with it —
/// two things moving, but each just a one-character shift.
const List<List<String>> _palmTreeFrames = <List<String>>[
  <String>[
    '   @@@@',
    '  @@@@@@',
    '    ||',
    '    ||',
    '    ||',
    '~~~~~~~~~~',
    ' ~~~~~~~~',
  ],
  <String>[
    '  @@@@',
    ' @@@@@@',
    '   ||',
    '    \\',
    '    \\',
    ' ~~~~~~~~~',
    '~~~~~~~~~~',
  ],
  <String>[
    '   @@@@',
    '  @@@@@@',
    '    ||',
    '    ||',
    '    ||',
    '~~~~~~~~~~',
    ' ~~~~~~~~',
  ],
  <String>[
    '    @@@@',
    '   @@@@@@',
    '     ||',
    '    /',
    '   /',
    '~~~~~~~~~ ',
    ' ~~~~~~~~~',
  ],
];

/// A flower head rocking side to side on its stem, the whole plant leaning
/// with it — the same one-character-shift idea as the other two.
const List<List<String>> _flowerFrames = <List<String>>[
  <String>[' (@)', '  |', '  |', ' ==='],
  <String>['  (@)', '   |', '  |', ' ==='],
  <String>[' (@)', '  |', '  |', ' ==='],
  <String>['(@)', ' |', '  |', ' ==='],
];

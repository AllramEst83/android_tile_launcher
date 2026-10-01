/// One of the Scene tile's short, continuously looping animations — ASCII
/// art, in the tile's own single ink colour like every other tile (never a
/// second colour or a picture asset), animated with smooth, eased, forever-
/// repeating motion (`flutter_animate`, in `scene_tile_view.dart`) rather
/// than a hand-ticked sequence of discrete frames. More arrive the same way
/// these three did: a case in `scene_tile_view.dart`'s `_sceneOf` and a
/// block of art constants below.
enum SceneAnimation {
  rocket('ROCKET LAUNCH'),
  palmTree('PALM TREE'),
  flower('FLOWER');

  const SceneAnimation(this.label);

  final String label;
}

// --- rocket -----------------------------------------------------------

/// The hull: never moves on its own, only bobs gently as part of the whole
/// rocket (see `_Rocket` in `scene_tile_view.dart`).
const List<String> rocketHull = <String>[
  '   /\\',
  '  /  \\',
  ' |    |',
  ' | () |',
  ' |    |',
  ' /----\\',
];

/// The engine flame under the hull — the one piece that flickers (scales
/// and fades) on its own, independent of the hull's slow bob.
const String rocketFlame = '^^^^';

// --- palm tree ----------------------------------------------------------

/// The fronds and trunk together, one rigid piece that sways from its own
/// base (see `_PalmTree`'s `alignment: Alignment.bottomCenter` rotation).
const List<String> palmTree = <String>[
  '  @@@@',
  ' @@@@@@',
  '   ||',
  '   ||',
  '   ||',
];

/// The shoreline under the tree — drifts gently side to side on its own.
const String palmWaves = '~~~~~~~~~~';

// --- flower ---------------------------------------------------------------

/// The bloom — sways with [flowerStem] as one piece, but also breathes
/// (scales) a little faster and independently of that sway.
const String flowerHead = '(@)';

/// The stalk under the bloom; part of the same swaying piece as the head.
const List<String> flowerStem = <String>['|', '|'];

/// The ground line under the flower — never moves.
const String flowerGround = '===';

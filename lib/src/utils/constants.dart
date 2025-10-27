import 'dart:ui';

class GameColors {
  GameColors._();

  static const Map<String, Color> namedColors = {
    'red': Color(0xFFE57373),
    'blue': Color(0xFF64B5F6),
    'green': Color(0xFF81C784),
    'yellow': Color(0xFFFFF176),
    'orange': Color(0xFFFFB74D),
    'purple': Color(0xFF9575CD),
    'teal': Color(0xFF4DB6AC),
    'pink': Color(0xFFF06292),
    'brown': Color(0xFF8D6E63),
    'cyan': Color(0xFF4DD0E1),
    'magenta': Color(0xFFBA68C8),
    'lime': Color(0xFFC0CA33),
    'indigo': Color(0xFF5C6BC0),
    'maroon': Color(0xFF8E2430),
    'navy': Color(0xFF3949AB),
    'peach': Color(0xFFFFCC80),
    'mint': Color(0xFF80CBC4),
    'lavender': Color(0xFFB39DDB),
    'turquoise': Color(0xFF26C6DA),
    'coral': Color(0xFFFF8A65),
  };

  static Color fromName(String name) {
    final color = namedColors[name.toLowerCase()];
    if (color == null) {
      throw ArgumentError('Unknown color name: $name');
    }
    return color;
  }
}

class AssetPaths {
  AssetPaths._();

  static const String levels = 'assets/levels';
  static const String audioPour = 'pour.wav';
  static const String audioInvalid = 'correct.wav';
  static const String audioWin = 'win.mp3';
  static const String audioButtonSplash = 'button_splash.wav';
  static const String audioConfetti = 'confetti_pop.wav';
  static const String audioOutOfMoves = 'out_of_moves.wav';
  static const String audioAmbient = 'ambient_water.wav';
}

class LevelSets {
  LevelSets._();

  static final List<String> defaultLevelIds =
      List<String>.generate(300, (index) => (index + 1).toString().padLeft(3, '0'));
}

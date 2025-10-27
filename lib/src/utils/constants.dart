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
  static const String audioPour = 'audio/pour.wav';
  static const String audioInvalid = 'audio/correct.wav';
  static const String audioWin = 'audio/win.mp3';
}

class LevelSets {
  LevelSets._();

  static const List<String> defaultLevelIds = [
    '001',
    '002',
    '003',
    '004',
    '005',
    '006',
    '007',
    '008',
    '009',
    '010',
  ];
}

import 'dart:math' as math;
import 'dart:ui';

class GameColors {
  GameColors._();

  static const List<Color> _masterPalette = [
    Color(0xFFED2A2A),
    Color(0xFF2A80ED),
    Color(0xFFEDE12A),
    Color(0xFF8CED2A),
    Color(0xFF2AEDED),
    Color(0xFF8C2AED),
    Color(0xFFED4F2A),
    Color(0xFF67ED2A),
    Color(0xFF2AC9ED),
    Color(0xFFB02AED),
    Color(0xFFED732A),
    Color(0xFF43ED2A),
    Color(0xFF2AA4ED),
    Color(0xFFD52AED),
    Color(0xFFED982A),
    Color(0xFF2AED36),
    Color(0xFFED2AE1),
    Color(0xFFEDBD2A),
    Color(0xFF2AED5B),
    Color(0xFF2A5BED),
    Color(0xFFED2ABD),
    Color(0xFF2AED80),
    Color(0xFF2A36ED),
    Color(0xFFED2A98),
    Color(0xFFD5ED2A),
    Color(0xFF2AEDA4),
    Color(0xFF432AED),
    Color(0xFFED2A73),
    Color(0xFFB0ED2A),
    Color(0xFF2AEDC9),
    Color(0xFF672AED),
    Color(0xFFED2A4F),
  ];

  static List<Color> paletteForLevel(int levelNumber) {
    final safeIndex = (levelNumber - 1).clamp(0, 299).toInt();
    final unlocked = math.min(_masterPalette.length, 3 + safeIndex ~/ 5);
    final palette = _masterPalette.take(unlocked).toList(growable: false);
    if (palette.isEmpty) {
      return const <Color>[];
    }
    if (levelNumber >= 300 && unlocked == _masterPalette.length) {
      final shuffled = List<Color>.from(palette);
      shuffled.shuffle(math.Random(levelNumber));
      return shuffled;
    }
    return palette;
  }

  static Map<String, Color> colorMapForLevel(List<List<String>> tubes, int levelNumber) {
    final palette = paletteForLevel(levelNumber);
    if (palette.isEmpty) {
      return <String, Color>{};
    }
    final seen = <String>{};
    final orderedNames = <String>[];
    for (final tube in tubes) {
      for (final rawName in tube) {
        final normalized = rawName.trim().toLowerCase();
        if (normalized.isEmpty || seen.contains(normalized)) {
          continue;
        }
        seen.add(normalized);
        orderedNames.add(normalized);
      }
    }

    final mapping = <String, Color>{};
    for (var i = 0; i < orderedNames.length; i++) {
      mapping[orderedNames[i]] = palette[i % palette.length];
    }
    return mapping;
  }

  static Color fallbackColor(String name, int levelNumber) {
    final palette = paletteForLevel(levelNumber);
    if (palette.isEmpty) {
      return const Color(0xFFFFFFFF);
    }
    final index = name.trim().toLowerCase().hashCode.abs() % palette.length;
    return palette[index];
  }

  static List<Color> get masterPalette => _masterPalette;
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

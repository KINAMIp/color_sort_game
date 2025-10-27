import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/services.dart' show rootBundle;

import '../utils/constants.dart';

class Level {
  Level({
    required this.id,
    required this.title,
    required this.tubeCapacity,
    required this.tubes,
    this.movesLimit,
    required this.hints,
  });

  factory Level.fromJson(Map<String, dynamic> json) {
    final tubesJson = json['tubes'] as List<dynamic>?;
    return Level(
      id: json['id'] as String,
      title: json['title'] as String,
      tubeCapacity: json['tube_capacity'] as int,
      tubes: tubesJson
              ?.map((tube) => List<String>.from(tube as List<dynamic>))
              .toList() ??
          <List<String>>[],
      movesLimit: json['moves_limit'] as int?,
      hints: (json['hints'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final String title;
  final int tubeCapacity;
  final List<List<String>> tubes;
  final int? movesLimit;
  final int hints;

  List<List<Color>> buildColorStacks() {
    if (tubes.isEmpty) {
      return const <List<Color>>[];
    }

    final levelNumber = int.tryParse(id) ?? 1;
    final colorMap = GameColors.colorMapForLevel(tubes, levelNumber);
    final colorPool = <String>[];
    final emptyIndices = <int>[];
    for (var i = 0; i < tubes.length; i++) {
      final tube = tubes[i];
      if (tube.isEmpty) {
        emptyIndices.add(i);
      } else {
        colorPool.addAll(tube);
      }
    }

    if (colorPool.isEmpty) {
      return tubes
          .map(
            (tube) =>
                tube
                    .map(
                      (name) =>
                          colorMap[name.trim().toLowerCase()] ??
                          GameColors.fallbackColor(name, levelNumber),
                    )
                    .toList(),
          )
          .toList(growable: false);
    }

    final totalTubes = tubes.length;
    final chosenEmptyIndex = emptyIndices.isNotEmpty ? emptyIndices.first : totalTubes - 1;
    final targetLengths = List<int>.filled(totalTubes, 0);
    final playableIndices = <int>[];
    for (var i = 0; i < totalTubes; i++) {
      if (i == chosenEmptyIndex) {
        continue;
      }
      playableIndices.add(i);
    }

    var segmentsRemaining = colorPool.length;
    for (final index in playableIndices) {
      if (segmentsRemaining == 0) {
        break;
      }
      targetLengths[index] = 1;
      segmentsRemaining -= 1;
    }

    while (segmentsRemaining > 0) {
      var distributed = false;
      for (final index in playableIndices) {
        if (segmentsRemaining == 0) {
          break;
        }
        if (targetLengths[index] >= tubeCapacity) {
          continue;
        }
        targetLengths[index] += 1;
        segmentsRemaining -= 1;
        distributed = true;
      }
      if (!distributed) {
        break;
      }
    }

    final random = math.Random(id.hashCode);
    colorPool.shuffle(random);

    final stacks = List<List<Color>>.generate(totalTubes, (_) => <Color>[]);
    var cursor = 0;
    for (var i = 0; i < totalTubes; i++) {
      final length = targetLengths[i];
      for (var j = 0; j < length; j++) {
        if (cursor >= colorPool.length) {
          break;
        }
        final colorName = colorPool[cursor++];
        final color =
            colorMap[colorName.trim().toLowerCase()] ?? GameColors.fallbackColor(colorName, levelNumber);
        stacks[i].add(color);
      }
    }

    _enforceMixedStacks(stacks, playableIndices, random);

    return stacks;
  }

  void _enforceMixedStacks(
    List<List<Color>> stacks,
    List<int> playableIndices,
    math.Random random,
  ) {
    if (playableIndices.length <= 1) {
      return;
    }

    for (final index in playableIndices) {
      final stack = stacks[index];
      if (stack.length <= 1) {
        continue;
      }
      final uniqueColors = stack.toSet();
      if (uniqueColors.length > 1) {
        continue;
      }

      final currentColor = stack.first;
      final candidates = playableIndices
          .where((other) =>
              other != index &&
              stacks[other].isNotEmpty &&
              stacks[other].any((color) => color != currentColor))
          .toList();

      if (candidates.isEmpty) {
        final alternative = playableIndices
            .where((other) => other != index && stacks[other].isNotEmpty)
            .toList();
        if (alternative.isEmpty) {
          continue;
        }
        final otherIndex = alternative[random.nextInt(alternative.length)];
        final otherStack = stacks[otherIndex];
        final swapPos = random.nextInt(otherStack.length);
        final temp = stack[0];
        stack[0] = otherStack[swapPos];
        otherStack[swapPos] = temp;
        continue;
      }

      final otherIndex = candidates[random.nextInt(candidates.length)];
      final otherStack = stacks[otherIndex];
      var swapPos = otherStack.indexWhere((color) => color != currentColor);
      if (swapPos == -1) {
        swapPos = 0;
      }
      final temp = stack[0];
      stack[0] = otherStack[swapPos];
      otherStack[swapPos] = temp;
    }
  }

  bool isSolved(List<List<Color>> stacks) {
    return stacks.every((stack) {
      if (stack.isEmpty) {
        return true;
      }
      if (stack.length != tubeCapacity) {
        return false;
      }
      final first = stack.first;
      return stack.every((color) => color == first);
    });
  }
}

class LevelBundle {
  LevelBundle({required this.levels});

  final List<Level> levels;

  Level getById(String id) =>
      levels.firstWhere((level) => level.id == id, orElse: () => levels.first);

  static Future<LevelBundle> loadDefault() async {
    final futures = LevelSets.defaultLevelIds.map(loadLevel).toList();
    final results = await Future.wait(futures);
    return LevelBundle(levels: results);
  }

  static Future<Level> loadLevel(String id) async {
    final raw = await rootBundle
        .loadString('${AssetPaths.levels}/level_${id.padLeft(3, '0')}.json');
    final jsonMap = jsonDecode(raw) as Map<String, dynamic>;
    return Level.fromJson(jsonMap);
  }
}

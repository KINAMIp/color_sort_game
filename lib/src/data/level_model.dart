import 'dart:convert';
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
    return tubes
        .map((tube) => tube.map(GameColors.fromName).toList())
        .toList(growable: false);
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

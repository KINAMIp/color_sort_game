import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/game.dart';

import '../data/level_model.dart';
import '../services/audio_service.dart';
import '../state/app_state.dart';
import 'components/tube_component.dart';
import 'components/tube_style.dart';
import 'systems/pour_system.dart';

class CrayonGame extends FlameGame {
  CrayonGame({
    required this.level,
    required this.appState,
    required this.audioService,
    required this.onShowOverlay,
    required this.onHideOverlay,
  });

  final Level level;
  final AppState appState;
  final AudioService audioService;
  final void Function(String overlayName) onShowOverlay;
  final void Function(String overlayName) onHideOverlay;

  late PourSystem pourSystem;
  final List<TubeComponent> tubes = [];
  int? selectedTubeIndex;
  int movesMade = 0;
  final ValueNotifier<int> movesNotifier = ValueNotifier<int>(0);
  bool get isLevelComplete => level.isSolved(_currentStacks);

  static const String pauseOverlay = 'pauseOverlay';
  static const String hudOverlay = 'hudOverlay';
  static const String levelCompleteOverlay = 'levelCompleteOverlay';

  List<List<Color>> get _currentStacks =>
      tubes.map((tube) => tube.segments.map((segment) => segment.color).toList()).toList();

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    pourSystem = PourSystem(
      audioService: audioService,
    );
    _loadLevel();
  }

  void _loadLevel() {
    movesMade = 0;
    movesNotifier.value = 0;
    selectedTubeIndex = null;
    removeAll(tubes);
    tubes.clear();
    overlays.remove(hudOverlay);
    onHideOverlay(hudOverlay);
    final colorStacks = level.buildColorStacks();
    final levelNumber = int.tryParse(level.id) ?? 0;
    final tubeStyle = TubeVisualStyle.forLevel(levelNumber);
    for (var i = 0; i < colorStacks.length; i++) {
      final tube = TubeComponent(
        index: i,
        capacity: level.tubeCapacity,
        initialColors: colorStacks[i],
        style: tubeStyle,
        onTapped: _handleTubeTap,
      );
      tubes.add(tube);
      add(tube);
    }
    _layoutTubes();
    overlays.add(hudOverlay);
    onShowOverlay(hudOverlay);
  }

  void _layoutTubes() {
    if (tubes.isEmpty || size.x == 0) {
      return;
    }
    final padding = 40.0;
    final availableWidth = size.x - padding * 2;
    final spacing = tubes.length > 1
        ? availableWidth / (tubes.length - 1)
        : 0;
    for (var i = 0; i < tubes.length; i++) {
      final tube = tubes[i];
      tube.position = Vector2(padding + spacing * i - tube.size.x / 2, size.y * 0.6 - tube.size.y / 2);
    }
  }

  void _handleTubeTap(TubeComponent tube) {
    if (pourSystem.isPouring) {
      return;
    }
    if (selectedTubeIndex == null) {
      selectedTubeIndex = tube.index;
      tube.isSelected = true;
      return;
    }
    final previouslySelected = tubes[selectedTubeIndex!];
    if (previouslySelected.index == tube.index) {
      previouslySelected.isSelected = false;
      selectedTubeIndex = null;
      return;
    }
    _performPour(previouslySelected, tube);
  }

  Future<void> _performPour(TubeComponent source, TubeComponent destination) async {
    final success = await pourSystem.tryPour(source: source, destination: destination);
    source.isSelected = false;
    destination.isSelected = false;
    selectedTubeIndex = null;
    if (success) {
      movesMade += 1;
      movesNotifier.value = movesMade;
      if (isLevelComplete) {
        audioService.playWin();
        overlays.add(levelCompleteOverlay);
        onShowOverlay(levelCompleteOverlay);
        await appState.markLevelComplete(level.id, 3);
      }
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _layoutTubes();
  }

  void pauseGame() {
    pauseEngine();
    overlays.add(pauseOverlay);
    onShowOverlay(pauseOverlay);
  }

  void resumeGame() {
    resumeEngine();
    overlays.remove(pauseOverlay);
    onHideOverlay(pauseOverlay);
  }

  void resetLevel() {
    overlays.remove(levelCompleteOverlay);
    onHideOverlay(levelCompleteOverlay);
    _loadLevel();
  }

  @override
  void onRemove() {
    movesNotifier.dispose();
    super.onRemove();
  }
}

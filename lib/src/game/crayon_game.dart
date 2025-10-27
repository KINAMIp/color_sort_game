import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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
  int _movesLimit = 0;
  bool get isLevelComplete => level.isSolved(_currentStacks);

  static const String pauseOverlay = 'pauseOverlay';
  static const String hudOverlay = 'hudOverlay';
  static const String levelCompleteOverlay = 'levelCompleteOverlay';
  static const String outOfMovesOverlay = 'outOfMovesOverlay';

  List<List<Color>> get _currentStacks =>
      tubes.map((tube) => tube.segments.map((segment) => segment.color).toList()).toList();

  bool get hasMoveLimit => _movesLimit > 0;

  int get movesLimit => _movesLimit;

  int get movesRemaining => hasMoveLimit ? math.max(0, _movesLimit - movesMade) : 0;

  double get movesProgress => hasMoveLimit && _movesLimit > 0
      ? movesRemaining / _movesLimit
      : 1.0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    pourSystem = PourSystem(
      audioService: audioService,
      game: this,
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
    overlays.remove(outOfMovesOverlay);
    onHideOverlay(outOfMovesOverlay);
    final colorStacks = level.buildColorStacks();
    final levelNumber = int.tryParse(level.id) ?? 1;
    _movesLimit = level.movesLimit ??
        _calculateMoveLimit(
          colorStacks: colorStacks,
          levelNumber: levelNumber,
        );
    movesMade = 0;
    movesNotifier.value = hasMoveLimit ? _movesLimit : 0;
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
    final targetColumns = math.min(tubes.length, 8);
    final targetRows = (tubes.length / targetColumns).ceil();
    final horizontalPaddingFactor = targetColumns >= 6 ? 0.03 : 0.05;
    final minHorizontalPadding = targetColumns >= 6 ? 12.0 : 24.0;
    final horizontalPadding =
        math.max(minHorizontalPadding, size.x * horizontalPaddingFactor);
    final topPaddingFactor = targetRows >= 2 ? 0.14 : 0.1;
    final bottomPaddingFactor = targetRows >= 2 ? 0.09 : 0.07;
    final topPadding = math.max(64.0, size.y * topPaddingFactor);
    final bottomPadding = math.max(48.0, size.y * bottomPaddingFactor);
    final availableWidth = math.max(0.0, size.x - horizontalPadding * 2);
    final availableHeight = math.max(0.0, size.y - topPadding - bottomPadding);
    const baseHorizontalGap = 18.0;
    const baseVerticalGap = 24.0;
    const minHorizontalGap = 6.0;
    const minVerticalGap = 10.0;

    final baseWidth = tubes.first.style.width;
    final baseHeight = tubes.first.style.height;

    var layoutScale = 1.0;
    if (targetColumns > 0) {
      final requiredWidth =
          targetColumns * baseWidth + (targetColumns - 1) * baseHorizontalGap;
      if (requiredWidth > availableWidth && requiredWidth > 0) {
        layoutScale = math.min(layoutScale, availableWidth / requiredWidth);
      }
    }
    if (targetRows > 0) {
      final requiredHeight =
          targetRows * baseHeight + (targetRows - 1) * baseVerticalGap;
      if (requiredHeight > availableHeight && requiredHeight > 0) {
        layoutScale = math.min(layoutScale, availableHeight / requiredHeight);
      }
    }
    if (tubes.length <= 8 && availableWidth > 0) {
      final gapCount = math.max(0, tubes.length - 1);
      final spacingAllowance = math.max(0.0, availableWidth - gapCount * minHorizontalGap);
      if (spacingAllowance > 0) {
        final singleRowScale = (spacingAllowance / (tubes.length * baseWidth)).clamp(0.3, 1.0);
        layoutScale = math.min(layoutScale, singleRowScale);
      }
    }
    layoutScale = layoutScale.clamp(0.3, 1.0);

    for (final tube in tubes) {
      tube.updateLayoutScale(layoutScale);
    }

    final tubeWidth = tubes.first.size.x;
    final tubeHeight = tubes.first.size.y;
    final maxColumns = math.min(tubes.length, 8);
    final effectiveMinHorizontalGap = math.max(minHorizontalGap, baseHorizontalGap * layoutScale);
    final effectiveMinVerticalGap = math.max(minVerticalGap, baseVerticalGap * layoutScale);

    var bestColumns = 1;
    var bestScore = double.negativeInfinity;
    final columnCandidates =
        List<int>.generate(maxColumns, (index) => maxColumns - index);
    for (final columns in columnCandidates) {
      final rows = (tubes.length / columns).ceil();
      final horizontalGap = columns > 1
          ? (availableWidth - columns * tubeWidth) / (columns - 1)
          : availableWidth;
      final verticalGap = rows > 1
          ? (availableHeight - rows * tubeHeight) / (rows - 1)
          : availableHeight;
      if (columns > 1 && horizontalGap < effectiveMinHorizontalGap) {
        continue;
      }
      if (rows > 1 && verticalGap < effectiveMinVerticalGap) {
        continue;
      }
      final score = math.min(horizontalGap, verticalGap);
      final preferSingleRow = tubes.length <= 8 && columns == tubes.length;
      if (preferSingleRow && score.isFinite) {
        bestColumns = columns;
        bestScore = score;
        break;
      }
      if (score > bestScore) {
        bestScore = score;
        bestColumns = columns;
      }
    }

    if (bestScore == double.negativeInfinity) {
      bestColumns = maxColumns;
    }

    final rowCount = (tubes.length / bestColumns).ceil();
    final horizontalGap = bestColumns > 1
        ? (availableWidth - bestColumns * tubeWidth) / (bestColumns - 1)
        : 0.0;
    final clampedHorizontalGap = bestColumns > 1
        ? math.max(effectiveMinHorizontalGap, horizontalGap)
        : 0.0;
    final usedWidth = bestColumns * tubeWidth + (bestColumns - 1) * clampedHorizontalGap;
    final startX = horizontalPadding + math.max(0, (availableWidth - usedWidth) / 2);

    final verticalGap = rowCount > 1
        ? (availableHeight - rowCount * tubeHeight) / (rowCount - 1)
        : 0.0;
    final clampedVerticalGap = rowCount > 1
        ? math.max(effectiveMinVerticalGap, verticalGap)
        : 0.0;
    final usedHeight = rowCount * tubeHeight + (rowCount - 1) * clampedVerticalGap;
    final startY = topPadding + math.max(0, (availableHeight - usedHeight) / 2);

    var index = 0;
    for (var row = 0; row < rowCount; row++) {
      final count = math.min(bestColumns, tubes.length - index);
      final rowUsedWidth = count * tubeWidth + (count - 1) * clampedHorizontalGap;
      final rowStartX = startX + (usedWidth - rowUsedWidth) / 2;
      for (var i = 0; i < count; i++) {
        final tube = tubes[index++];
        final dx = rowStartX + i * (tubeWidth + clampedHorizontalGap);
        final dy = startY + row * (tubeHeight + clampedVerticalGap);
        tube.position = Vector2(dx, dy);
      }
    }
  }

  void _handleTubeTap(TubeComponent tube) {
    if (pourSystem.isPouring) {
      return;
    }
    if (selectedTubeIndex == null) {
      selectedTubeIndex = tube.index;
      tube.isSelected = true;
      HapticFeedback.selectionClick();
      return;
    }
    final previouslySelected = tubes[selectedTubeIndex!];
    if (previouslySelected.index == tube.index) {
      previouslySelected.isSelected = false;
      selectedTubeIndex = null;
      HapticFeedback.selectionClick();
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
      if (hasMoveLimit) {
        movesNotifier.value = movesRemaining;
        if (movesRemaining <= 0 && !isLevelComplete) {
          pauseEngine();
          overlays.add(outOfMovesOverlay);
          onShowOverlay(outOfMovesOverlay);
          return;
        }
      } else {
        movesNotifier.value = movesMade;
      }
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
    overlays.remove(outOfMovesOverlay);
    onHideOverlay(outOfMovesOverlay);
    resumeEngine();
    _loadLevel();
  }

  @override
  void onRemove() {
    movesNotifier.dispose();
    super.onRemove();
  }

  int _calculateMoveLimit({
    required List<List<Color>> colorStacks,
    required int levelNumber,
  }) {
    final estimatedMoves = colorStacks.map((stack) {
      if (stack.isEmpty) {
        return 0;
      }
      var transitions = 0;
      for (var i = 0; i < stack.length - 1; i++) {
        if (stack[i] != stack[i + 1]) {
          transitions += 1;
        }
      }
      // Each transition represents a point where at least one pour is needed to
      // separate the colors. Adding one ensures that a perfectly sorted tube
      // still counts as a single move requirement.
      return math.max(1, transitions + 1);
    }).fold<int>(0, (sum, value) => sum + value);

    final colorVariety = colorStacks.expand((tube) => tube).toSet().length;
    final baseRequirement = math.max(estimatedMoves, colorVariety);
    final progressionBonus = math.max(0, levelNumber - 1);
    return math.max(1, baseRequirement + progressionBonus);
  }
}

import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';

import '../../services/audio_service.dart';
import '../components/liquid_stream_component.dart';
import '../components/tube_component.dart';
import '../crayon_game.dart';

class PourSystem {
  PourSystem({
    required this.audioService,
    required this.game,
  });

  final AudioService audioService;
  final CrayonGame game;

  bool _isPouring = false;

  bool get isPouring => _isPouring;

  Future<bool> tryPour({
    required TubeComponent source,
    required TubeComponent destination,
  }) async {
    if (_isPouring) {
      return false;
    }
    if (!source.canPourTo(destination)) {
      audioService.playInvalid();
      HapticFeedback.selectionClick();
      return false;
    }
    _isPouring = true;
    try {
      final movable = source.consecutiveTopCount;
      final space = destination.capacity - destination.segments.length;
      final moveCount = min(movable, space);
      final pourColor = source.topColor;
      final removed = source.takeTopSegments(moveCount);

      source.triggerRipple(strength: 0.4);
      audioService.playPour();

      await source.animatePourTo(
        destination,
        moveCount,
        onPour: () async {
          LiquidStreamComponent? stream;
          if (pourColor != null) {
            stream = LiquidStreamComponent(
              color: pourColor,
              start: source.getPourMouthPosition(),
              end: destination.getPourLandingPosition(incomingLayers: moveCount),
            );
            game.add(stream);
          }

          for (final segment in removed.reversed) {
            await Future<void>.delayed(const Duration(milliseconds: 90));
            destination.addSegments([segment]);
            destination.triggerRipple(strength: 1);
            destination.emitPourEffects(segment.color);
          }

          if (stream != null) {
            await stream.completed;
          } else {
            await Future<void>.delayed(const Duration(milliseconds: 240));
          }
        },
      );

      HapticFeedback.mediumImpact();
      return true;
    } finally {
      _isPouring = false;
    }
  }
}

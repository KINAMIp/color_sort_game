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
    this.game,
  });

  final AudioService audioService;
  final CrayonGame? game;

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
      if (destination.isFull && source.topColor != null) {
        destination.showOverflowEffect(
          segment: source.segments.isNotEmpty ? source.segments.last : null,
        );
      }
      source.triggerRipple(strength: 0.3);
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
      final pourSegment = source.segments.isNotEmpty ? source.segments.last : null;
      final removed = source.takeTopSegments(moveCount);

      source.triggerRipple(strength: 0.4);
      final viscosity = pourSegment?.viscosity ?? 0.5;
      final intensity = (moveCount / source.capacity).clamp(0.2, 1.0);
      audioService.playPour(intensity: intensity, viscosity: viscosity);

      LiquidStreamComponent? stream;
      if (pourColor != null && game != null) {
        stream = LiquidStreamComponent(
          color: pourColor,
          start: source.getPourMouthPosition(),
          end: destination.getPourLandingPosition(incomingLayers: moveCount),
          viscosity: viscosity,
          flowRate: intensity,
        );
        game!.add(stream);
      }

      await source.animatePourTo(destination, moveCount);

      if (stream != null) {
        await stream.completed;
      }

      for (final segment in removed.reversed) {
        await Future<void>.delayed(const Duration(milliseconds: 90));
        destination.addSegments([segment]);
        destination.triggerRipple(strength: 1);
        destination.emitPourEffects(segment.color);
      }

      HapticFeedback.mediumImpact();
      return true;
    } finally {
      _isPouring = false;
    }
  }
}

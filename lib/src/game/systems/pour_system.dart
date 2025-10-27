import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';

import '../../services/audio_service.dart';
import '../components/tube_component.dart';

class PourSystem {
  PourSystem({
    required this.audioService,
  });

  final AudioService audioService;

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
      final removed = source.takeTopSegments(moveCount);

      source.triggerRipple(strength: 0.4);
      audioService.playPour();

      await source.animatePourTo(destination, moveCount);

      for (final segment in removed.reversed) {
        await Future<void>.delayed(const Duration(milliseconds: 90));
        destination.addSegments([segment]);
        destination.triggerRipple(strength: 1);
      }

      HapticFeedback.mediumImpact();
      return true;
    } finally {
      _isPouring = false;
    }
  }
}

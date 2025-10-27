import 'dart:async';
import 'dart:math';

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
      return false;
    }
    _isPouring = true;

    final movable = source.consecutiveTopCount;
    final space = destination.capacity - destination.segments.length;
    final moveCount = min(movable, space);
    final removed = source.takeTopSegments(moveCount);

    await Future<void>.delayed(const Duration(milliseconds: 250));

    destination.addSegments(removed.reversed.toList());
    audioService.playPour();

    _isPouring = false;
    return true;
  }
}

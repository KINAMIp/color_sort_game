import 'dart:math' as math;

import 'package:flutter/material.dart';

class TubeState {
  TubeState(this.layers);

  final List<Color?> layers;

  bool get isEmpty => topColor == null;

  Color? get topColor {
    for (var i = layers.length - 1; i >= 0; i--) {
      final color = layers[i];
      if (color != null) {
        return color;
      }
    }
    return null;
  }

  int? get topColorIndex {
    for (var i = layers.length - 1; i >= 0; i--) {
      if (layers[i] != null) {
        return i;
      }
    }
    return null;
  }

  int? get nextFillSlot {
    for (var i = layers.length - 1; i >= 0; i--) {
      if (layers[i] == null) {
        return i;
      }
    }
    return null;
  }

  bool hasSpaceFor(Color? color) {
    if (color == null) {
      return false;
    }
    final slot = nextFillSlot;
    if (slot == null) {
      return false;
    }
    final currentTop = topColor;
    return currentTop == null || currentTop == color;
  }

  Color? removeTopColor() {
    final index = topColorIndex;
    if (index == null) {
      return null;
    }
    final color = layers[index];
    layers[index] = null;
    return color;
  }

  void restoreColor(Color color) {
    final slot = nextFillSlot;
    if (slot != null) {
      layers[slot] = color;
    }
  }

  void fillColor(Color color, {required int slotIndex}) {
    if (slotIndex < 0 || slotIndex >= layers.length) {
      return;
    }
    layers[slotIndex] = color;
  }
}

class GlassLevel {
  GlassLevel({
    required this.index,
    required this.allowedMoves,
    required this.tubes,
  });

  final int index;
  final int allowedMoves;
  final List<List<Color?>> tubes;
}

Color lighten(Color color, [double amount = 0.12]) {
  final hsl = HSLColor.fromColor(color);
  final lightened = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
  return lightened.toColor();
}

Color darken(Color color, [double amount = 0.18]) {
  final hsl = HSLColor.fromColor(color);
  final darkened = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
  return darkened.toColor();
}

Path createCurvedLayerPath({
  required Rect rect,
  required double curvature,
  required double waveAmplitude,
  required double wavePhase,
}) {
  final path = Path();
  final top = rect.top;
  final bottom = rect.bottom;
  final left = rect.left;
  final right = rect.right;
  final wave = math.sin(wavePhase) * waveAmplitude;

  path.moveTo(left, bottom);
  path.lineTo(right, bottom);
  final controlPoint = Offset(right, top + curvature + wave);
  final topPoint = Offset(right - rect.width * 0.08, top + wave);
  path.quadraticBezierTo(controlPoint.dx, controlPoint.dy, topPoint.dx, topPoint.dy);
  final topLeftPoint = Offset(left + rect.width * 0.08, top + wave);
  path.quadraticBezierTo(
    left,
    top + curvature + wave,
    topLeftPoint.dx,
    topLeftPoint.dy,
  );
  path.close();
  return path;
}

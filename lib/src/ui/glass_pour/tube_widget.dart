import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'models.dart';

class GlassTube extends StatelessWidget {
  const GlassTube({
    super.key,
    required this.width,
    required this.height,
    required this.shimmerValue,
    required this.tube,
    required this.isSelected,
    required this.waveProgress,
    this.incomingFillColor,
    this.incomingFillProgress = 0,
  });

  final double width;
  final double height;
  final double shimmerValue;
  final TubeState tube;
  final bool isSelected;
  final double waveProgress;
  final Color? incomingFillColor;
  final double incomingFillProgress;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.32),
            blurRadius: isSelected ? 32 : 20,
            spreadRadius: isSelected ? 8 : 4,
            offset: const Offset(0, 12),
          ),
        ],
        gradient: isSelected
            ? const LinearGradient(
                colors: [Color(0xFF40C4FF), Color(0xFFF06292)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : const LinearGradient(
                colors: [Color(0x2200ACC1), Color(0x2200ACC1)],
              ),
      ),
      child: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(
          painter: GlassTubePainter(
            tube: tube,
            shimmerValue: shimmerValue,
            waveProgress: waveProgress,
            incomingFillColor: incomingFillColor,
            incomingFillProgress: incomingFillProgress,
          ),
        ),
      ),
    );
  }
}

class GlassTubePainter extends CustomPainter {
  GlassTubePainter({
    required this.tube,
    required this.shimmerValue,
    required this.waveProgress,
    this.incomingFillColor,
    this.incomingFillProgress = 0,
  });

  final TubeState tube;
  final double shimmerValue;
  final double waveProgress;
  final Color? incomingFillColor;
  final double incomingFillProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final glassRect = Rect.fromLTWH(0, 0, size.width, size.height);
    _drawGlass(canvas, glassRect);
    _drawLiquid(canvas, glassRect.deflate(size.width * 0.14));
    _drawHighlights(canvas, glassRect);
  }

  void _drawGlass(Canvas canvas, Rect rect) {
    final outerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = rect.width * 0.06
      ..color = Colors.white.withOpacity(0.4);

    final outerRRect = RRect.fromRectAndRadius(rect, Radius.circular(rect.width * 0.32));
    canvas.drawRRect(outerRRect, outerPaint);

    final innerShadowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withOpacity(0.08),
          Colors.black.withOpacity(0.35),
        ],
      ).createShader(rect.deflate(rect.width * 0.05));

    canvas.drawRRect(outerRRect.deflate(rect.width * 0.05), innerShadowPaint);
  }

  void _drawLiquid(Canvas canvas, Rect rect) {
    final layerHeight = rect.height / tube.layers.length;
    final waveAmplitude = (math.sin(waveProgress * math.pi * 2) * 4).abs() * (1 - waveProgress);

    for (var i = 0; i < tube.layers.length; i++) {
      final color = tube.layers[i];
      final layerRect = Rect.fromLTWH(
        rect.left,
        rect.bottom - layerHeight * (i + 1),
        rect.width,
        layerHeight,
      );
      if (color == null) {
        _paintEmptyLayer(canvas, layerRect, waveAmplitude, i);
      } else {
        _paintLayer(canvas, layerRect, color, waveAmplitude, i);
      }
    }

    if (incomingFillColor != null && incomingFillProgress > 0) {
      final slotIndex = tube.nextFillSlot ?? tube.layers.length - 1;
      final targetRect = Rect.fromLTWH(
        rect.left,
        rect.bottom - layerHeight * (slotIndex + 1),
        rect.width,
        layerHeight * incomingFillProgress,
      );
      final color = incomingFillColor!;
      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [lighten(color, 0.18), darken(color, 0.12)],
      );
      final paint = Paint()..shader = gradient.createShader(targetRect);
      final path = Path()
        ..addRRect(RRect.fromRectAndCorners(
          targetRect,
          topLeft: Radius.circular(rect.width * 0.24),
          topRight: Radius.circular(rect.width * 0.24),
        ));
      canvas.drawPath(path, paint);
    }
  }

  void _paintLayer(
    Canvas canvas,
    Rect rect,
    Color color,
    double waveAmplitude,
    int index,
  ) {
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [lighten(color), darken(color)],
    );

    final path = createCurvedLayerPath(
      rect: rect,
      curvature: rect.height * 0.24,
      waveAmplitude: waveAmplitude * (1 / (index + 1.2)),
      wavePhase: waveProgress * math.pi * 2,
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);

    final glossPaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect.inflate(rect.width * 0.06));
    canvas.drawPath(path, glossPaint);
  }

  void _paintEmptyLayer(
    Canvas canvas,
    Rect rect,
    double waveAmplitude,
    int index,
  ) {
    final path = createCurvedLayerPath(
      rect: rect,
      curvature: rect.height * 0.2,
      waveAmplitude: waveAmplitude * (1 / (index + 1.5)),
      wavePhase: waveProgress * math.pi * 2,
    );

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0x22FFFFFF),
          const Color(0x11000000),
        ],
      ).createShader(rect);

    canvas.drawPath(path, paint);
  }

  void _drawHighlights(Canvas canvas, Rect rect) {
    final shimmerWidth = rect.width * 0.16;
    final shimmerOffset = rect.left + rect.width * (0.2 + shimmerValue * 0.4);
    final shimmerRect = Rect.fromLTWH(
      shimmerOffset,
      rect.top + rect.height * 0.1,
      shimmerWidth,
      rect.height * 0.72,
    );

    final shimmerPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(0.05),
          Colors.white.withOpacity(0.4),
          Colors.white.withOpacity(0.05),
        ],
        stops: const [0, 0.5, 1],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(shimmerRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(shimmerRect, Radius.circular(shimmerWidth)),
      shimmerPaint,
    );

    final rimPaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.white.withOpacity(0.7), Colors.white.withOpacity(0.05)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height * 0.12))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.left + rect.width * 0.08, rect.top + rect.height * 0.02,
            rect.width - rect.width * 0.16, rect.height * 0.12),
        Radius.circular(rect.width * 0.28),
      ),
      rimPaint,
    );
  }

  @override
  bool shouldRepaint(covariant GlassTubePainter oldDelegate) {
    final layersChanged = !listEquals(oldDelegate.tube.layers, tube.layers);
    return layersChanged ||
        oldDelegate.shimmerValue != shimmerValue ||
        oldDelegate.waveProgress != waveProgress ||
        oldDelegate.incomingFillColor != incomingFillColor ||
        oldDelegate.incomingFillProgress != incomingFillProgress;
  }
}

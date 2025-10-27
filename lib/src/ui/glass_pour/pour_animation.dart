import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'models.dart';

class PourPainter extends CustomPainter {
  PourPainter({
    required this.progress,
    required this.color,
    required this.start,
    required this.end,
  });

  final double progress;
  final Color color;
  final Offset start;
  final Offset end;

  @override
  void paint(Canvas canvas, Size size) {
    final liftHeight = 60.0;
    final liftPoint = start - Offset(0, liftHeight);
    final controlPoint = Offset(
      (start.dx + end.dx) / 2,
      math.min(start.dy, end.dy) - 160,
    );

    Offset currentPosition;
    if (progress < 0.25) {
      final t = progress / 0.25;
      currentPosition = Offset.lerp(start, liftPoint, Curves.easeInOut.transform(t))!;
    } else if (progress < 0.85) {
      final t = (progress - 0.25) / 0.6;
      final eased = Curves.easeInOutCubic.transform(t);
      currentPosition = _quadraticBezierPoint(liftPoint, controlPoint, end, eased);
    } else {
      final t = (progress - 0.85) / 0.15;
      final dropTarget = end + const Offset(0, 48);
      currentPosition = Offset.lerp(end, dropTarget, Curves.easeInOut.transform(t.clamp(0.0, 1.0)))!;
    }

    final pathPoints = <Offset>[];
    if (progress < 0.25) {
      pathPoints.add(start);
      pathPoints.add(currentPosition);
    } else {
      const sampleCount = 18;
      for (var i = 0; i <= sampleCount; i++) {
        final t = (i / sampleCount).clamp(0.0, 1.0);
        final sample = _quadraticBezierPoint(
          liftPoint,
          controlPoint,
          end,
          Curves.easeInOut.transform(t),
        );
        if (sample.dy <= currentPosition.dy) {
          pathPoints.add(sample);
        }
      }
      if (progress >= 0.85) {
        pathPoints.add(currentPosition);
      }
    }

    if (pathPoints.length >= 2) {
      final path = Path()..addPolygon(pathPoints, false);
      final pathPaint = Paint()
        ..shader = LinearGradient(
          colors: [lighten(color, 0.18), darken(color, 0.2)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromPoints(pathPoints.first, pathPoints.last))
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 14
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.8);
      canvas.drawPath(path, pathPaint);

      final corePaint = Paint()
        ..color = color.withOpacity(0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, corePaint);
    }

    final dropletPaint = Paint()
      ..shader = RadialGradient(
        colors: [lighten(color, 0.2), darken(color, 0.2)],
      ).createShader(Rect.fromCircle(center: currentPosition, radius: 12));

    canvas.drawCircle(currentPosition, 12, dropletPaint);

    if (progress > 0.8) {
      final splashT = ((progress - 0.8) / 0.2).clamp(0.0, 1.0);
      final rippleRadius = 18 + 26 * splashT;
      final rippleOpacity = (1 - splashT).clamp(0.0, 1.0);
      final ripplePaint = Paint()
        ..color = lighten(color, 0.3).withOpacity(0.4 * rippleOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawCircle(end, rippleRadius, ripplePaint);
      canvas.drawCircle(
        end,
        rippleRadius * 0.6,
        ripplePaint..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant PourPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.start != start ||
        oldDelegate.end != end;
  }

  Offset _quadraticBezierPoint(
    Offset start,
    Offset control,
    Offset end,
    double t,
  ) {
    final x = math.pow(1 - t, 2) * start.dx + 2 * (1 - t) * t * control.dx + math.pow(t, 2) * end.dx;
    final y = math.pow(1 - t, 2) * start.dy + 2 * (1 - t) * t * control.dy + math.pow(t, 2) * end.dy;
    return Offset(x.toDouble(), y.toDouble());
  }
}

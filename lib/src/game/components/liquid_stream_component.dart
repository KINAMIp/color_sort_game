import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class LiquidStreamComponent extends PositionComponent {
  LiquidStreamComponent({
    required Vector2 start,
    required Vector2 end,
    required Color color,
  })  : _start = start.toOffset(),
        _end = end.toOffset(),
        _color = color,
        super(priority: 50);

  final Offset _start;
  final Offset _end;
  final Color _color;
  final double _duration = 0.42;
  final Completer<void> _completer = Completer<void>();
  final List<double> _bubbleOffsets = List<double>.generate(6, (index) => index / 5);
  double _elapsed = 0;

  Future<void> get completed => _completer.future;

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed >= _duration && !_completer.isCompleted) {
      _completer.complete();
    }
    if (_elapsed >= _duration + 0.2) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final t = (_elapsed / _duration).clamp(0.0, 1.0);
    final eased = Curves.easeInOut.transform(t);
    final controlPoint = Offset.lerp(
      _start,
      _end,
      0.5,
    )! + Offset(0, (_end.dy - _start.dy) * 0.18 + 42 * (t - 0.5));

    final path = Path()
      ..moveTo(_start.dx, _start.dy)
      ..quadraticBezierTo(controlPoint.dx, controlPoint.dy, _end.dx, _end.dy);

    final strokeWidth = lerpDouble(12, 5, eased)!;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..shader = LinearGradient(
        colors: [
          _color.withOpacity(0.75),
          Color.lerp(_color, Colors.white, 0.5)!.withOpacity(0.95),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromPoints(_start, _end));

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 1.6
      ..color = _color.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);

    _drawBubbles(canvas, path, eased);
    _drawSplash(canvas, eased);
  }

  void _drawBubbles(Canvas canvas, Path path, double eased) {
    final metricsList = path.computeMetrics();
    if (metricsList.isEmpty) {
      return;
    }
    final metrics = metricsList.first;
    for (var i = 0; i < _bubbleOffsets.length; i++) {
      final travel = (eased + _bubbleOffsets[i]) % 1.0;
      final position = metrics.getTangentForOffset(metrics.length * travel);
      if (position == null) {
        continue;
      }
      final radius = lerpDouble(3, 6.5, travel) ?? 4;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withOpacity(0.8),
            _color.withOpacity(0.1),
          ],
        ).createShader(Rect.fromCircle(center: position.position, radius: radius));
      canvas.drawCircle(position.position, radius, paint);
    }
  }

  void _drawSplash(Canvas canvas, double eased) {
    if (eased < 0.92) {
      return;
    }
    final progress = (eased - 0.92) / 0.08;
    final baseRadius = lerpDouble(4, 12, progress.clamp(0.0, 1.0))!;
    final paint = Paint()
      ..color = _color.withOpacity(0.4 * (1 - progress))
      ..style = PaintingStyle.stroke
      ..strokeWidth = lerpDouble(5, 1.5, progress)!;
    for (var i = 0; i < 3; i++) {
      final angle = (math.pi * 2 / 3) * i;
      final offset = Offset(math.cos(angle), math.sin(angle)) * baseRadius;
      canvas.drawArc(
        Rect.fromCircle(center: _end + offset * 0.2, radius: baseRadius),
        angle - math.pi / 6,
        math.pi / 6,
        false,
        paint,
      );
    }
  }
}

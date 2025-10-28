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
    double viscosity = 0.5,
    double flowRate = 1,
  })  : _start = start.toOffset(),
        _end = end.toOffset(),
        _color = color,
        _viscosity = viscosity.clamp(0.1, 1.0),
        _flowRate = flowRate.clamp(0.2, 1.6),
        super(priority: 50);

  final Offset _start;
  final Offset _end;
  final Color _color;
  final double _viscosity;
  final double _flowRate;
  late final double _duration = lerpDouble(0.52, 0.34, _flowRate * (1 - _viscosity))!;
  final Completer<void> _completer = Completer<void>();
  final List<double> _bubbleOffsets = List<double>.generate(6, (index) => index / 5);
  final List<_StreamDroplet> _droplets = [];
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

    for (var i = _droplets.length - 1; i >= 0; i--) {
      final droplet = _droplets[i];
      droplet.elapsed += dt;
      droplet.velocity += Offset(0, 320 * dt);
      droplet.position += droplet.velocity * dt;
      if (droplet.elapsed >= droplet.lifetime) {
        _droplets.removeAt(i);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final t = (_elapsed / _duration).clamp(0.0, 1.0);
    final eased = Curves.easeInOut.transform(t);
    final curvature = lerpDouble(38, 72, 1 - _viscosity)!;
    final controlOffset = Offset(0, (_end.dy - _start.dy) * 0.18 + curvature * (t - 0.5));
    final controlPoint = Offset.lerp(_start, _end, 0.46)! + controlOffset;

    final path = Path()
      ..moveTo(_start.dx, _start.dy)
      ..quadraticBezierTo(controlPoint.dx, controlPoint.dy, _end.dx, _end.dy);

    final baseWidth = lerpDouble(10, 16, _flowRate * (1 - _viscosity))!;
    final tailWidth = lerpDouble(5, 9, _flowRate * (1 - _viscosity))!;
    final thickness = lerpDouble(baseWidth, tailWidth, eased)!;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = thickness
      ..shader = LinearGradient(
        colors: [
          _color.withOpacity(0.82),
          Color.lerp(_color, Colors.white, 0.58)!.withOpacity(0.96),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromPoints(_start, _end));

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness * lerpDouble(1.5, 2.2, 1 - _viscosity)!
      ..color = _color.withOpacity(0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);

    _drawBubbles(canvas, path, eased);
    _drawSplash(canvas, eased);
    _drawDroplets(canvas);
  }

  void _drawBubbles(Canvas canvas, Path path, double eased) {
    final metricsIterator = path.computeMetrics().iterator;
    if (!metricsIterator.moveNext()) {
      return;
    }
    final metrics = metricsIterator.current;
    if (metrics.length <= 0) {
      return;
    }
    for (var i = 0; i < _bubbleOffsets.length; i++) {
      final travel = (eased + _bubbleOffsets[i]) % 1.0;
      final position = metrics.getTangentForOffset(metrics.length * travel);
      if (position == null) {
        continue;
      }
      final radius = lerpDouble(3, 6.5, travel) ?? 4;
      final opacity = lerpDouble(0.3, 0.8, 1 - _viscosity)!;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withOpacity(opacity),
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
      ..color = _color.withOpacity(0.38 * (1 - progress))
      ..style = PaintingStyle.stroke
      ..strokeWidth = lerpDouble(5, 1.8, progress)!;
    final dropletCount = (_flowRate * (1 - _viscosity) * 3).clamp(2, 5).round();
    for (var i = 0; i < dropletCount; i++) {
      final angle = (math.pi * 2 / 3) * i;
      final offset = Offset(math.cos(angle), math.sin(angle)) * baseRadius;
      canvas.drawArc(
        Rect.fromCircle(center: _end + offset * 0.2, radius: baseRadius),
        angle - math.pi / 6,
        math.pi / 6,
        false,
        paint,
      );
      if (_droplets.length < 14) {
        _droplets.add(
          _StreamDroplet(
            position: _end + offset * 0.3,
            velocity: Offset(offset.dx * 60, -math.max(40, 120 * _flowRate)),
            color: _color,
            lifetime: lerpDouble(0.4, 0.9, 1 - _viscosity)!,
            radius: lerpDouble(2.6, 4.2, 1 - _viscosity)!,
          ),
        );
      }
    }
  }

  void _drawDroplets(Canvas canvas) {
    if (_droplets.isEmpty) {
      return;
    }
    for (final droplet in _droplets) {
      final fade = (1 - droplet.elapsed / droplet.lifetime).clamp(0.0, 1.0);
      final rect = Rect.fromCircle(center: droplet.position, radius: droplet.radius);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            droplet.color.withOpacity(0.6 * fade),
            droplet.color.withOpacity(0.0),
          ],
        ).createShader(rect);
      canvas.drawCircle(droplet.position, droplet.radius, paint);
    }
  }
}

class _StreamDroplet {
  _StreamDroplet({
    required this.position,
    required this.velocity,
    required this.color,
    required this.lifetime,
    required this.radius,
  });

  Offset position;
  Offset velocity;
  final Color color;
  final double lifetime;
  final double radius;
  double elapsed = 0;
}

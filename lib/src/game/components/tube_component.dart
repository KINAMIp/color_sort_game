import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/painting.dart';

import 'color_segment.dart';
import 'tube_style.dart';

class TubeComponent extends PositionComponent with TapCallbacks {
  TubeComponent({
    required this.index,
    required this.capacity,
    required List<Color> initialColors,
    required this.style,
    this.onTapped,
    Vector2? position,
    Vector2? size,
  })  : segments = initialColors.map(ColorSegment.new).toList(),
        super(position: position, size: size ?? Vector2(style.width, style.height));

  final int index;
  final int capacity;
  final TubeVisualStyle style;
  final List<ColorSegment> segments;
  final void Function(TubeComponent component)? onTapped;

  bool _selected = false;
  bool _isAnimatingPour = false;
  double _rippleProgress = 0;
  double _sparkleTimer = 0;
  final List<_SparkleParticle> _sparkles = [];
  static final math.Random _random = math.Random();

  bool get isSelected => _selected;

  set isSelected(bool value) {
    if (_selected != value) {
      _selected = value;
    }
  }

  bool get isEmpty => segments.isEmpty;

  bool get isFull => segments.length >= capacity;

  Color? get topColor => segments.isEmpty ? null : segments.last.color;

  bool get isSolved =>
      segments.length == capacity &&
      segments.every((segment) => segment.color == segments.first.color);

  int get consecutiveTopCount {
    if (segments.isEmpty) {
      return 0;
    }
    final top = segments.last.color;
    var count = 0;
    for (var i = segments.length - 1; i >= 0; i--) {
      if (segments[i].color == top) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  bool canPourTo(TubeComponent destination) {
    if (identical(this, destination)) {
      return false;
    }
    if (isEmpty || destination.isFull) {
      return false;
    }
    if (destination.isEmpty) {
      return true;
    }
    return destination.topColor == topColor;
  }

  List<ColorSegment> takeTopSegments(int amount) {
    final toTake = amount.clamp(0, segments.length);
    final removed = <ColorSegment>[];
    for (var i = 0; i < toTake; i++) {
      removed.add(segments.removeLast());
    }
    return removed;
  }

  void addSegments(List<ColorSegment> incoming) {
    segments.addAll(incoming);
  }

  bool containsPoint(Vector2 point) {
    final rect = Rect.fromLTWH(position.x, position.y, size.x, size.y);
    return rect.contains(point.toOffset());
  }

  List<ColorSegment> previewPourTo(TubeComponent destination) {
    if (!canPourTo(destination)) {
      return const <ColorSegment>[];
    }
    final movable = consecutiveTopCount;
    final space = destination.capacity - destination.segments.length;
    final moveCount = movable < space ? movable : space;
    return List<ColorSegment>.generate(
      moveCount,
      (_) => ColorSegment(topColor!),
    );
  }

  void handleTap() {
    onTapped?.call(this);
  }

  Future<void> animatePourTo(TubeComponent destination, int amount) async {
    if (_isAnimatingPour) {
      return;
    }
    _isAnimatingPour = true;
    final direction = destination.position.x >= position.x ? 1 : -1;
    final bend = direction > 0 ? -0.32 : 0.32;
    final controller = EffectController(
      duration: 0.26,
      reverseDuration: 0.24,
      curve: Curves.easeInOutCubic,
    );
    final previousAnchor = anchor;
    anchor = Anchor.bottomCenter;
    final rotateEffect = RotateEffect.by(
      bend,
      controller: controller,
    );
    add(rotateEffect);
    await rotateEffect.completed;
    anchor = previousAnchor;
    _isAnimatingPour = false;
  }

  void triggerRipple({double strength = 1}) {
    _rippleProgress = strength.clamp(0, 1);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_rippleProgress > 0) {
      _rippleProgress = math.max(0, _rippleProgress - dt * 1.6);
    }

    if (isSolved) {
      _sparkleTimer += dt;
      if (_sparkleTimer >= 0.24) {
        _sparkleTimer = 0;
        _sparkles.add(
          _SparkleParticle(
            position: Offset(
              _random.nextDouble(),
              (_random.nextDouble().clamp(0.1, 0.92)) as double,
            ),
            lifetime: lerpDouble(0.6, 1.1, _random.nextDouble())!,
            baseSize: lerpDouble(6, 11, _random.nextDouble())!,
          ),
        );
      }
    } else {
      _sparkles.clear();
      _sparkleTimer = 0;
    }

    for (var i = _sparkles.length - 1; i >= 0; i--) {
      final sparkle = _sparkles[i];
      sparkle.elapsed += dt;
      if (sparkle.elapsed >= sparkle.lifetime) {
        _sparkles.removeAt(i);
      }
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    handleTap();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final shapePath = _buildBottlePath();
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.strokeWidth
      ..color = _selected ? style.selectionColor : style.borderColor;
    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = style.innerColor;

    canvas.drawPath(shapePath, fillPaint);
    if (isSolved) {
      canvas.save();
      canvas.clipPath(shapePath);
      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            style.selectionColor.withOpacity(0.55),
            Colors.transparent,
          ],
        ).createShader(
          Rect.fromCircle(
            center: Offset(size.x / 2, size.y * 0.55),
            radius: size.x,
          ),
        );
      canvas.drawCircle(Offset(size.x / 2, size.y * 0.55), size.x, glowPaint);
      canvas.restore();
    }
    canvas.drawPath(shapePath, borderPaint);

    if (segments.isEmpty) {
      _renderRipple(canvas);
      return;
    }

    canvas.save();
    canvas.clipPath(shapePath);
    final availableHeight = size.y - style.topPadding - style.bottomPadding;
    final segmentHeight = availableHeight / capacity;
    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final progress = capacity <= 1 ? 0.0 : i / (capacity - 1);
      final inset = _horizontalInsetForProgress(progress);
      final rect = Rect.fromLTWH(
        inset,
        size.y - style.bottomPadding - (i + 1) * segmentHeight + style.segmentGap / 2,
        size.x - inset * 2,
        segmentHeight - style.segmentGap,
      );
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = segment.color;
      final borderRadius = Radius.circular(_segmentRadiusForProgress(progress));
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, borderRadius),
        paint,
      );
    }
    canvas.restore();

    _renderRipple(canvas);
    _renderSparkles(canvas);
  }

  Path _buildBottlePath() {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    switch (style.design) {
      case TubeDesign.classic:
        return Path()
          ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(24)));
      case TubeDesign.slender:
        return _buildCurvedBottlePath(
          neckWidthFactor: 0.42,
          shoulderWidthFactor: 0.7,
          bellyWidthFactor: 0.82,
          neckHeightFactor: 0.18,
          shoulderHeightFactor: 0.58,
          baseCurveFactor: 0.08,
        );
      case TubeDesign.potion:
        return _buildCurvedBottlePath(
          neckWidthFactor: 0.32,
          shoulderWidthFactor: 0.78,
          bellyWidthFactor: 0.92,
          neckHeightFactor: 0.2,
          shoulderHeightFactor: 0.48,
          baseCurveFactor: 0.05,
        );
      case TubeDesign.royal:
        return _buildCurvedBottlePath(
          neckWidthFactor: 0.5,
          shoulderWidthFactor: 0.9,
          bellyWidthFactor: 0.88,
          neckHeightFactor: 0.16,
          shoulderHeightFactor: 0.44,
          baseCurveFactor: 0.07,
        );
    }
  }

  Path _buildCurvedBottlePath({
    required double neckWidthFactor,
    required double shoulderWidthFactor,
    required double bellyWidthFactor,
    required double neckHeightFactor,
    required double shoulderHeightFactor,
    required double baseCurveFactor,
  }) {
    final w = size.x;
    final h = size.y;
    final neckWidth = w * neckWidthFactor;
    final shoulderWidth = w * shoulderWidthFactor;
    final bellyWidth = w * bellyWidthFactor;
    final neckHeight = h * neckHeightFactor;
    final shoulderHeight = h * shoulderHeightFactor;
    final baseCurveHeight = h * baseCurveFactor;

    final path = Path();
    path.moveTo((w - neckWidth) / 2, 0);
    path.lineTo((w + neckWidth) / 2, 0);
    path.cubicTo(
      (w + neckWidth) / 2,
      neckHeight * 0.4,
      (w + shoulderWidth) / 2,
      neckHeight + (shoulderHeight - neckHeight) * 0.35,
      (w + shoulderWidth) / 2,
      shoulderHeight,
    );
    path.cubicTo(
      (w + bellyWidth) / 2,
      h - baseCurveHeight,
      w * 0.5 + bellyWidth * 0.1,
      h,
      w * 0.5,
      h,
    );
    path.cubicTo(
      w * 0.5 - bellyWidth * 0.1,
      h,
      (w - bellyWidth) / 2,
      h - baseCurveHeight,
      (w - shoulderWidth) / 2,
      shoulderHeight,
    );
    path.cubicTo(
      (w - shoulderWidth) / 2,
      neckHeight + (shoulderHeight - neckHeight) * 0.35,
      (w - neckWidth) / 2,
      neckHeight * 0.4,
      (w - neckWidth) / 2,
      0,
    );
    path.close();
    return path;
  }

  double _horizontalInsetForProgress(double progress) {
    switch (style.design) {
      case TubeDesign.classic:
        return size.x * 0.12;
      case TubeDesign.slender:
        return size.x * (0.1 + 0.12 * progress);
      case TubeDesign.potion:
        return size.x * (0.18 - 0.08 * math.sin(progress * math.pi));
      case TubeDesign.royal:
        return size.x * (0.14 + 0.06 * math.cos(progress * math.pi));
    }
  }

  double _segmentRadiusForProgress(double progress) {
    switch (style.design) {
      case TubeDesign.classic:
        return 12;
      case TubeDesign.slender:
        return 11 - 3 * progress;
      case TubeDesign.potion:
        final delta = (progress - 0.5).abs();
        return 13 - 4 * delta;
      case TubeDesign.royal:
        return 14 - 5 * progress;
    }
  }

  void _renderRipple(Canvas canvas) {
    if (_rippleProgress <= 0) {
      return;
    }
    final availableHeight = size.y - style.topPadding - style.bottomPadding;
    final center = Offset(
      size.x / 2,
      size.y - style.bottomPadding - availableHeight * 0.18,
    );
    final radius = lerpDouble(size.x * 0.35, size.x * 0.7, 1 - _rippleProgress)!;
    final strokeWidth = lerpDouble(6, 1.6, 1 - _rippleProgress)!;
    final ripplePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = style.selectionColor.withOpacity(_rippleProgress * 0.7);
    canvas.drawCircle(center, radius, ripplePaint);
  }

  void _renderSparkles(Canvas canvas) {
    if (_sparkles.isEmpty) {
      return;
    }
    final availableHeight = size.y - style.topPadding - style.bottomPadding;
    for (final sparkle in _sparkles) {
      final t = (sparkle.elapsed / sparkle.lifetime).clamp(0.0, 1.0);
      final fade = 1 - t;
      final sparkleSize = sparkle.baseSize * (1 + t * 0.6);
      final dx = lerpDouble(
        style.width * 0.2,
        style.width * 0.8,
        sparkle.position.dx,
      )!;
      final dy = size.y - style.bottomPadding - availableHeight * sparkle.position.dy;
      final center = Offset(dx, dy - t * 12);
      final sparklePaint = Paint()
        ..color = Colors.white.withOpacity(0.65 * fade)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      _drawSparkle(canvas, center, sparkleSize, sparklePaint);
    }
  }

  void _drawSparkle(Canvas canvas, Offset center, double size, Paint paint) {
    final half = size / 2;
    final path = Path()
      ..moveTo(center.dx, center.dy - half)
      ..lineTo(center.dx + half * 0.5, center.dy)
      ..lineTo(center.dx, center.dy + half)
      ..lineTo(center.dx - half * 0.5, center.dy)
      ..close();
    canvas.drawPath(path, paint);
  }
}

class _SparkleParticle {
  _SparkleParticle({
    required this.position,
    required this.lifetime,
    required this.baseSize,
  });

  final Offset position;
  final double lifetime;
  final double baseSize;
  double elapsed = 0;
}

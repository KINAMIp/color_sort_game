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
  final List<_BubbleParticle> _floatingBubbles = [];
  final List<_SplashRipple> _splashRipples = [];
  static final math.Random _random = math.Random();
  double _layoutScale = 1;

  bool get isSelected => _selected;

  set isSelected(bool value) {
    if (_selected != value) {
      _selected = value;
    }
  }

  double get layoutScale => _layoutScale;

  void updateLayoutScale(double scale) {
    final clamped = scale.clamp(0.3, 1.0);
    if ((_layoutScale - clamped).abs() < 0.001) {
      return;
    }
    _layoutScale = clamped;
    size = Vector2(style.width * _layoutScale, style.height * _layoutScale);
  }

  double get _widthScale => size.x / style.width;

  double get _heightScale => size.y / style.height;

  double get _strokeWidth => style.strokeWidth * _widthScale;

  double get _topPadding => style.topPadding * _heightScale;

  double get _bottomPadding => style.bottomPadding * _heightScale;

  double get _segmentGap => style.segmentGap * _heightScale;

  double get _availableHeight => size.y - _topPadding - _bottomPadding;

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
    // Mixing colors is allowed as long as there is space available in the
    // destination tube. The end goal is still to sort the colors, but we do not
    // restrict players from experimenting with different combinations.
    return true;
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

  Future<void> animatePourTo(
    TubeComponent destination,
    int amount, {
    Future<void> Function()? onPour,
  }) async {
    if (_isAnimatingPour) {
      return;
    }
    _isAnimatingPour = true;
    final originalPosition = position.clone();
    final previousAnchor = anchor;
    anchor = Anchor.bottomCenter;
    final horizontalDelta = destination.position.x - position.x;
    final verticalDelta = destination.position.y - position.y;
    final approachOffset = Vector2(
      horizontalDelta * 0.45,
      (verticalDelta * 0.25) - size.y * 0.12,
    );
    final maxLift = -size.y * 0.36;
    final maxDrop = size.y * 0.24;
    final clampedYOffset = approachOffset.y.clamp(maxLift, maxDrop).toDouble();
    final approachPosition = Vector2(
      originalPosition.x + approachOffset.x,
      originalPosition.y + clampedYOffset,
    );
    final bendDirection = horizontalDelta >= 0 ? 1 : -1;
    final bendAmount = bendDirection > 0 ? -0.38 : 0.38;
    final defaultPourDuration = Duration(milliseconds: 220 + (amount * 70));

    final moveForward = MoveEffect.to(
      approachPosition,
      EffectController(
        duration: 0.28,
        curve: Curves.easeInOutCubic,
      ),
    );
    final tiltForward = RotateEffect.by(
      bendAmount,
      EffectController(
        duration: 0.26,
        curve: Curves.easeInOutCubic,
      ),
    );

    add(moveForward);
    add(tiltForward);

    try {
      await Future.wait([moveForward.completed, tiltForward.completed]);

      await Future<void>.delayed(const Duration(milliseconds: 80));

      if (onPour != null) {
        await onPour();
      } else {
        await Future<void>.delayed(defaultPourDuration);
      }

      final settleTilt = RotateEffect.by(
        bendAmount * -0.12,
        EffectController(
          duration: 0.18,
          curve: Curves.easeOutCubic,
        ),
      );
      add(settleTilt);
      await settleTilt.completed;

      final moveBack = MoveEffect.to(
        originalPosition,
        EffectController(
          duration: 0.34,
          curve: Curves.easeInOutCubic,
        ),
      );
      final tiltBack = RotateEffect.by(
        -bendAmount * 0.88,
        EffectController(
          duration: 0.32,
          curve: Curves.easeInOutCubic,
        ),
      );
      add(moveBack);
      add(tiltBack);
      await Future.wait([moveBack.completed, tiltBack.completed]);
    } finally {
      angle = 0;
      position = originalPosition;
      anchor = previousAnchor;
      _isAnimatingPour = false;
    }
  }

  void triggerRipple({double strength = 1}) {
    _rippleProgress = strength.clamp(0, 1);
  }

  void emitPourEffects(Color color) {
    final layerIndex = segments.isEmpty ? 0.0 : segments.length - 0.5;
    final startProgress = (layerIndex / capacity).clamp(0.0, 1.0);
    for (var i = 0; i < 5; i++) {
      _floatingBubbles.add(
        _BubbleParticle(
          color: color,
          baseProgress: startProgress,
          progress: startProgress + lerpDouble(-0.03, 0.03, _random.nextDouble())!,
          speed: lerpDouble(0.22, 0.36, _random.nextDouble())!,
          horizontalShift: lerpDouble(-0.18, 0.18, _random.nextDouble())!,
          radius: lerpDouble(3, 6.5, _random.nextDouble())!,
          lifetime: lerpDouble(0.85, 1.4, _random.nextDouble())!,
        ),
      );
    }
    _splashRipples.add(
      _SplashRipple(
        color: color,
        baseProgress: startProgress,
        lifetime: 0.6,
      ),
    );
  }

  Vector2 getPourMouthPosition() {
    return Vector2(
      position.x + size.x / 2,
      position.y + _topPadding,
    );
  }

  Vector2 getPourLandingPosition({required int incomingLayers}) {
    final availableHeight = _availableHeight;
    final segmentHeight = availableHeight / capacity;
    final targetIndex = segments.length + incomingLayers - 0.5;
    final y = position.y + size.y - _bottomPadding - targetIndex * segmentHeight;
    return Vector2(position.x + size.x / 2, y);
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

    for (var i = _floatingBubbles.length - 1; i >= 0; i--) {
      final bubble = _floatingBubbles[i];
      bubble.elapsed += dt;
      bubble.progress += dt * bubble.speed;
      if (bubble.elapsed >= bubble.lifetime || bubble.progress >= 1.08) {
        _floatingBubbles.removeAt(i);
      }
    }

    for (var i = _splashRipples.length - 1; i >= 0; i--) {
      final splash = _splashRipples[i];
      splash.elapsed += dt;
      if (splash.elapsed >= splash.lifetime) {
        _splashRipples.removeAt(i);
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
      ..strokeWidth = _strokeWidth
      ..color = _selected ? style.selectionColor : style.borderColor;
    final fillPaint = _buildFillPaint();

    canvas.drawPath(shapePath, fillPaint);
    _renderNeonGlassHighlights(canvas, shapePath);
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
    _renderNeonRim(canvas);

    if (segments.isEmpty) {
      _renderRipple(canvas);
      return;
    }

    canvas.save();
    canvas.clipPath(shapePath);
    final availableHeight = _availableHeight;
    final segmentHeight = availableHeight / capacity;
    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final progress = capacity <= 1 ? 0.0 : i / (capacity - 1);
      final inset = _horizontalInsetForProgress(progress);
      final gap = _segmentGap * 0.3;
      final rect = Rect.fromLTWH(
        inset,
        size.y - _bottomPadding - (i + 1) * segmentHeight + gap / 2,
        size.x - inset * 2,
        segmentHeight - gap,
      );
      final path = _buildLiquidSegmentPath(
        rect,
        progress: progress,
        isTopSegment: i == segments.length - 1,
        isBottomSegment: i == 0,
      );
      final paint = _buildSegmentPaint(rect, segment.color);
      canvas.drawPath(path, paint);
      _renderLiquidHighlights(
        canvas,
        path,
        rect,
        isTopSegment: i == segments.length - 1,
      );
    }
    canvas.restore();

    _renderFloatingBubbles(canvas, shapePath);
    _renderRipple(canvas);
    _renderSparkles(canvas);
    _renderSplashRipples(canvas);
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
      case TubeDesign.neon:
        return _buildNeonBottlePath();
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
      case TubeDesign.neon:
        return size.x * 0.16;
    }
  }

  Paint _buildFillPaint() {
    final paint = Paint()..style = PaintingStyle.fill;
    if (style.design == TubeDesign.neon) {
      final bounds = Rect.fromLTWH(0, 0, size.x, size.y);
      paint.shader = LinearGradient(
        colors: [
          style.innerColor.withOpacity(0.94),
          Color.lerp(style.innerColor, Colors.black, 0.3)!,
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(bounds);
    } else {
      paint.color = style.innerColor;
    }
    return paint;
  }

  Paint _buildSegmentPaint(Rect rect, Color color) {
    final top = Color.lerp(color, Colors.white, 0.22)!;
    final bottom = Color.lerp(color, Colors.black, 0.16)!;
    return Paint()
      ..shader = LinearGradient(
        colors: [top, bottom],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect);
  }

  Path _buildLiquidSegmentPath(
    Rect rect, {
    required double progress,
    required bool isTopSegment,
    required bool isBottomSegment,
  }) {
    final left = rect.left;
    final right = rect.right;
    final top = rect.top;
    final bottom = rect.bottom;
    final width = rect.width;
    final height = rect.height;
    final topWaveHeight = height * (isTopSegment ? 0.36 : 0.2);
    final bottomCurve = height * (isBottomSegment ? 0.46 : 0.28);
    final crestOffset = lerpDouble(0.32, 0.18, progress.clamp(0.0, 1.0))!;
    final controlWidth = width * (0.32 + 0.12 * (1 - progress));

    final path = Path();
    path.moveTo(left + bottomCurve * 0.6, bottom);
    path.quadraticBezierTo(left, bottom, left, bottom - bottomCurve * 0.6);

    if (isTopSegment) {
      final crestY = top + topWaveHeight * crestOffset;
      final troughY = top - topWaveHeight * 0.3;
      final midX = rect.center.dx;
      path.cubicTo(
        left + controlWidth * 0.38,
        crestY,
        midX - controlWidth * 0.32,
        troughY,
        midX,
        crestY + topWaveHeight * 0.12,
      );
      path.cubicTo(
        midX + controlWidth * 0.32,
        crestY + topWaveHeight * 0.42,
        right - controlWidth * 0.38,
        crestY + topWaveHeight * 0.24,
        right,
        crestY + topWaveHeight * 0.68,
      );
    } else {
      final topCurve = height * (0.28 - 0.12 * (1 - progress));
      final peakY = top + topCurve * 0.2;
      path.quadraticBezierTo(left, peakY, left + width * 0.12, top + topCurve * 0.08);
      path.quadraticBezierTo(
        rect.center.dx,
        top - topCurve * 0.22,
        right - width * 0.12,
        top + topCurve * 0.08,
      );
      path.quadraticBezierTo(right, peakY, right, top + topCurve * 0.62);
    }

    path.quadraticBezierTo(right, bottom, right - bottomCurve * 0.6, bottom);
    path.close();
    return path;
  }

  void _renderLiquidHighlights(
    Canvas canvas,
    Path segmentPath,
    Rect rect, {
    required bool isTopSegment,
  }) {
    canvas.save();
    canvas.clipPath(segmentPath);

    final highlightRect = Rect.fromLTWH(
      rect.left + rect.width * 0.58,
      rect.top + rect.height * 0.12,
      rect.width * 0.24,
      rect.height * 0.78,
    );
    final highlightPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(0.24),
          Colors.white.withOpacity(0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(highlightRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(highlightRect, Radius.circular(rect.width * 0.18)),
      highlightPaint,
    );

    if (isTopSegment) {
      final sheenPath = Path()
        ..moveTo(rect.left + rect.width * 0.16, rect.top + rect.height * 0.2)
        ..quadraticBezierTo(
          rect.center.dx,
          rect.top - rect.height * 0.08,
          rect.right - rect.width * 0.16,
          rect.top + rect.height * 0.2,
        )
        ..lineTo(rect.right - rect.width * 0.2, rect.top + rect.height * 0.34)
        ..quadraticBezierTo(
          rect.center.dx,
          rect.top + rect.height * 0.12,
          rect.left + rect.width * 0.2,
          rect.top + rect.height * 0.34,
        )
        ..close();
      final sheenPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withOpacity(0.28),
            Colors.white.withOpacity(0.0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(rect);
      canvas.drawPath(sheenPath, sheenPaint);
    }

    if (style.design == TubeDesign.neon) {
      final neonGlow = Rect.fromLTWH(
        rect.left + rect.width * 0.66,
        rect.top + rect.height * 0.1,
        rect.width * 0.2,
        rect.height * 0.82,
      );
      final neonPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withOpacity(0.55),
            Colors.white.withOpacity(0.0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(neonGlow);
      canvas.drawRRect(
        RRect.fromRectAndRadius(neonGlow, Radius.circular(rect.width * 0.2)),
        neonPaint,
      );
    }

    canvas.restore();
  }

  void _renderNeonGlassHighlights(Canvas canvas, Path shapePath) {
    if (style.design != TubeDesign.neon) {
      return;
    }
    canvas.save();
    canvas.clipPath(shapePath);
    final innerHighlight = Rect.fromLTWH(
      size.x * 0.12,
      size.y * 0.08,
      size.x * 0.28,
      size.y * 0.62,
    );
    final innerPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(0.36),
          Colors.white.withOpacity(0.02),
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(innerHighlight);
    canvas.drawRRect(
      RRect.fromRectAndRadius(innerHighlight, Radius.circular(size.x * 0.18)),
      innerPaint,
    );

    final sideGlow = Rect.fromLTWH(
      size.x * 0.62,
      size.y * 0.12,
      size.x * 0.18,
      size.y * 0.72,
    );
    final sidePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(0.42),
          Colors.white.withOpacity(0.0),
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(sideGlow);
    canvas.drawRRect(
      RRect.fromRectAndRadius(sideGlow, Radius.circular(size.x * 0.22)),
      sidePaint,
    );
    canvas.restore();

    final baseGlowRect = Rect.fromLTWH(
      size.x * 0.18,
      size.y - _bottomPadding - size.x * 0.26,
      size.x * 0.64,
      size.x * 0.3,
    );
    final basePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          style.selectionColor.withOpacity(0.32),
          Colors.transparent,
        ],
      ).createShader(baseGlowRect);
    canvas.drawOval(baseGlowRect, basePaint);
  }

  void _renderNeonRim(Canvas canvas) {
    if (style.design != TubeDesign.neon) {
      return;
    }
    final rimRect = Rect.fromLTWH(
      size.x * 0.08,
      -_strokeWidth * 0.4,
      size.x * 0.84,
      _strokeWidth * 2.2,
    );
    final rimPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(0.85),
          style.borderColor.withOpacity(0.9),
          Colors.white.withOpacity(0.75),
        ],
        stops: const [0.0, 0.48, 1.0],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rimRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rimRect, Radius.circular(size.x * 0.22)),
      rimPaint,
    );
  }

  Path _buildNeonBottlePath() {
    final w = size.x;
    final h = size.y;
    final neckWidth = w * 0.68;
    final shoulderWidth = w * 0.9;
    final bellyWidth = w * 0.94;
    final neckHeight = h * 0.12;
    final shoulderHeight = h * 0.42;
    final baseCurveHeight = h * 0.12;

    final path = Path();
    path.moveTo((w - neckWidth) / 2, 0);
    path.lineTo((w + neckWidth) / 2, 0);
    path.cubicTo(
      (w + shoulderWidth) / 2,
      neckHeight * 0.6,
      (w + bellyWidth) / 2,
      shoulderHeight,
      (w + bellyWidth * 0.82) / 2,
      h - baseCurveHeight,
    );
    path.quadraticBezierTo(
      w * 0.5,
      h,
      (w - bellyWidth * 0.82) / 2,
      h - baseCurveHeight,
    );
    path.cubicTo(
      (w - bellyWidth) / 2,
      shoulderHeight,
      (w - shoulderWidth) / 2,
      neckHeight * 0.6,
      (w - neckWidth) / 2,
      0,
    );
    path.close();
    return path;
  }

  void _renderRipple(Canvas canvas) {
    if (_rippleProgress <= 0) {
      return;
    }
    final availableHeight = _availableHeight;
    final center = Offset(
      size.x / 2,
      size.y - _bottomPadding - availableHeight * 0.18,
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
    final availableHeight = _availableHeight;
    for (final sparkle in _sparkles) {
      final t = (sparkle.elapsed / sparkle.lifetime).clamp(0.0, 1.0);
      final fade = 1 - t;
      final sparkleSize = sparkle.baseSize * (1 + t * 0.6);
      final dx = lerpDouble(
        style.width * 0.2,
        style.width * 0.8,
        sparkle.position.dx,
      )!;
      final dy = size.y - _bottomPadding - availableHeight * sparkle.position.dy;
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

  void _renderFloatingBubbles(Canvas canvas, Path shapePath) {
    if (_floatingBubbles.isEmpty) {
      return;
    }
    final availableHeight = _availableHeight;
    canvas.save();
    canvas.clipPath(shapePath);
    for (final bubble in _floatingBubbles) {
      final fade = 1 - (bubble.elapsed / bubble.lifetime).clamp(0.0, 1.0);
      final x = size.x / 2 + bubble.horizontalShift * size.x * 0.45;
      final y = size.y - _bottomPadding - availableHeight * bubble.progress;
      final radius = bubble.radius * (1 + (1 - fade) * 0.25);
      final rect = Rect.fromCircle(center: Offset(x, y), radius: radius);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withOpacity(0.75 * fade),
            bubble.color.withOpacity(0.15 * fade),
          ],
        ).createShader(rect);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
    canvas.restore();
  }

  void _renderSplashRipples(Canvas canvas) {
    if (_splashRipples.isEmpty) {
      return;
    }
    final availableHeight = _availableHeight;
    for (final splash in _splashRipples) {
      final t = (splash.elapsed / splash.lifetime).clamp(0.0, 1.0);
      final center = Offset(
        size.x / 2,
        size.y - _bottomPadding - availableHeight * splash.baseProgress,
      );
      final radius = lerpDouble(size.x * 0.18, size.x * 0.36, t)!;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = lerpDouble(4, 1.2, t)!
        ..color = splash.color.withOpacity(0.4 * (1 - t));
      canvas.drawCircle(center, radius, paint);
    }
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

class _BubbleParticle {
  _BubbleParticle({
    required this.color,
    required this.baseProgress,
    required this.progress,
    required this.speed,
    required this.horizontalShift,
    required this.radius,
    required this.lifetime,
  });

  final Color color;
  final double baseProgress;
  double progress;
  final double speed;
  final double horizontalShift;
  final double radius;
  final double lifetime;
  double elapsed = 0;
}

class _SplashRipple {
  _SplashRipple({
    required this.color,
    required this.baseProgress,
    required this.lifetime,
  });

  final Color color;
  final double baseProgress;
  final double lifetime;
  double elapsed = 0;
}

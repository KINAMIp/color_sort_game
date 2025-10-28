import 'dart:math' as math;
import 'dart:ui' show lerpDouble, PathMetric, Tangent;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/audio_service.dart';
import '../../state/app_state.dart';

class WaterPouringAnimation extends StatefulWidget {
  const WaterPouringAnimation({super.key});

  @override
  State<WaterPouringAnimation> createState() => _WaterPouringAnimationState();
}

class _WaterPouringAnimationState extends State<WaterPouringAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _tilt;
  late final Animation<double> _pourProgress;
  late final Animation<double> _foamProgress;
  late final Animation<double> _settleProgress;
  late final Animation<double> _wavePhase;
  bool _audioTriggered = false;
  AudioService? _audioService;

  static const List<_SegmentRecipe> _sourceRecipes = <_SegmentRecipe>[
    _SegmentRecipe(
      color: Color(0xFFFF85C2),
      volume: 0.2,
      viscosity: 0.58,
      opacity: 0.9,
    ),
    _SegmentRecipe(
      color: Color(0xFFB893FF),
      volume: 0.18,
      viscosity: 0.36,
      opacity: 0.92,
    ),
    _SegmentRecipe(
      color: Color(0xFF68DDFE),
      volume: 0.16,
      viscosity: 0.28,
      opacity: 0.86,
    ),
    _SegmentRecipe(
      color: Color(0xFFFFD884),
      volume: 0.12,
      viscosity: 0.68,
      opacity: 0.9,
    ),
  ];

  static const List<_SegmentRecipe> _destinationBase = <_SegmentRecipe>[
    _SegmentRecipe(
      color: Color(0xFF7FE9B6),
      volume: 0.2,
      viscosity: 0.48,
      opacity: 0.9,
    ),
    _SegmentRecipe(
      color: Color(0xFF62C7FF),
      volume: 0.16,
      viscosity: 0.34,
      opacity: 0.92,
    ),
  ];

  static final double _sourceTotalVolume =
      _sourceRecipes.fold(0.0, (double sum, _SegmentRecipe recipe) => sum + recipe.volume);
  static final double _destinationBaseVolume = _destinationBase.fold(
    0.0,
    (double sum, _SegmentRecipe recipe) => sum + recipe.volume,
  );

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 3600),
      vsync: this,
    );

    _tilt = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.26, curve: Curves.easeInOutCubic),
    );

    _pourProgress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.18, 0.86, curve: Curves.easeInOutCubic),
    );

    _foamProgress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.32, 0.96, curve: Curves.easeOutQuad),
    );

    _settleProgress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.72, 1.0, curve: Curves.easeOutCubic),
    );

    _wavePhase = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.linear),
      ),
    );

    _controller.addListener(_handleTick);
    _controller.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        _audioTriggered = false;
        if (mounted) {
          _controller.forward(from: 0.0);
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.forward(from: 0.0);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _audioService ??= Provider.of<AppState>(context, listen: false).audioService;
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTick);
    _controller.dispose();
    super.dispose();
  }

  void _handleTick() {
    if (!_audioTriggered && _pourProgress.value > 0.08) {
      final double viscosity = _sourceRecipes.first.viscosity;
      final double intensity = math.max(0.42, _pourProgress.value);
      _audioService?.playPour(intensity: intensity, viscosity: viscosity);
      _audioTriggered = true;
    }
    setState(() {});
  }

  void _startPouring() {
    _audioTriggered = false;
    _controller.forward(from: 0.0);
  }

  List<_SegmentState> _buildSourceStack(double progress) {
    final double pouredVolume = _sourceTotalVolume * progress;
    double remaining = pouredVolume;
    final List<_SegmentState> resultTopToBottom = <_SegmentState>[];
    for (final _SegmentRecipe recipe in _sourceRecipes) {
      final double drained = remaining > 0 ? math.min(recipe.volume, remaining) : 0.0;
      final double currentVolume = (recipe.volume - drained).clamp(0.0, recipe.volume);
      remaining = math.max(0, remaining - recipe.volume);
      if (currentVolume > 0.0008) {
        resultTopToBottom.add(recipe.toState(currentVolume));
      }
    }
    return resultTopToBottom.reversed.toList(growable: false);
  }

  List<_SegmentState> _buildDestinationStack(double progress) {
    final double pouredVolume = _sourceTotalVolume * progress;
    double remaining = pouredVolume;
    final List<_SegmentState> result = <_SegmentState>[];
    for (final _SegmentRecipe recipe in _destinationBase) {
      result.add(recipe.toState(recipe.volume));
    }
    for (final _SegmentRecipe recipe in _sourceRecipes) {
      if (remaining <= 0) {
        break;
      }
      final double added = math.min(recipe.volume, remaining);
      if (added > 0.0006) {
        result.add(recipe.toState(added));
      }
      remaining -= added;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _startPouring,
      behavior: HitTestBehavior.opaque,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double width = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : 360;
          final double height = math.min(constraints.maxHeight.isFinite ? constraints.maxHeight : 320, 320);
          final List<_SegmentState> sourceStack =
              _buildSourceStack(_pourProgress.value.clamp(0.0, 1.0));
          final List<_SegmentState> destinationStack =
              _buildDestinationStack(_pourProgress.value.clamp(0.0, 1.0));
          final double transfer = (_sourceTotalVolume * _pourProgress.value).clamp(0.0, _sourceTotalVolume);
          final double destinationFill = _destinationBaseVolume + transfer;
          final double overflow = math.max(0, destinationFill - 1.0);
          final double streamVisibility = Curves.easeIn.transform(_pourProgress.value.clamp(0.0, 1.0));
          final double leftTilt = -_tilt.value * 0.34;
          final double rightTilt = _settleProgress.value * 0.06 * math.sin(_wavePhase.value * 0.5);
          return SizedBox(
            width: width,
            height: height,
            child: CustomPaint(
              painter: _WaterPainter(
                leftTilt: leftTilt,
                rightTilt: rightTilt,
                wavePhase: _wavePhase.value,
                pourVisibility: streamVisibility,
                sourceStack: sourceStack,
                destinationStack: destinationStack,
                overflow: overflow,
                foamLevel: _foamProgress.value,
                receiveSettle: _settleProgress.value,
                sourceViscosity: _sourceRecipes.first.viscosity,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WaterPainter extends CustomPainter {
  _WaterPainter({
    required this.leftTilt,
    required this.rightTilt,
    required this.wavePhase,
    required this.pourVisibility,
    required this.sourceStack,
    required this.destinationStack,
    required this.overflow,
    required this.foamLevel,
    required this.receiveSettle,
    required this.sourceViscosity,
  });

  final double leftTilt;
  final double rightTilt;
  final double wavePhase;
  final double pourVisibility;
  final List<_SegmentState> sourceStack;
  final List<_SegmentState> destinationStack;
  final double overflow;
  final double foamLevel;
  final double receiveSettle;
  final double sourceViscosity;

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width.clamp(240.0, 520.0);
    final double height = size.height.clamp(220.0, 340.0);
    final double horizontalPadding = (size.width - width) / 2;
    final double baseY = height - 24;
    final double tubeWidth = math.min(118, width * 0.28);
    final double tubeHeight = math.min(240, height * 0.76);
    final double spacing = math.max(40, width * 0.14);

    final Rect leftRect = Rect.fromLTWH(
      horizontalPadding + (width - (tubeWidth * 2 + spacing)) / 2,
      baseY - tubeHeight,
      tubeWidth,
      tubeHeight,
    );
    final Rect rightRect = Rect.fromLTWH(
      leftRect.right + spacing,
      baseY - tubeHeight,
      tubeWidth,
      tubeHeight,
    );

    _drawBaseShadow(canvas, leftRect);
    _drawBaseShadow(canvas, rightRect);

    final RRect leftOuter = RRect.fromRectAndRadius(leftRect, Radius.circular(tubeWidth * 0.26));
    final RRect leftInner = leftOuter.deflate(tubeWidth * 0.06);
    final RRect rightOuter = RRect.fromRectAndRadius(rightRect, Radius.circular(tubeWidth * 0.26));
    final RRect rightInner = rightOuter.deflate(tubeWidth * 0.06);

    canvas.save();
    _applyTilt(canvas, leftOuter.outerRect, leftTilt);
    _drawGlass(canvas, leftOuter, leftInner, emphasize: true);
    _drawLiquidStack(
      canvas,
      leftInner,
      sourceStack,
      lean: leftTilt / 0.34,
      wave: wavePhase,
      foam: 0,
      settle: 0,
    );
    canvas.restore();

    canvas.save();
    _applyTilt(canvas, rightOuter.outerRect, rightTilt);
    _drawGlass(canvas, rightOuter, rightInner, emphasize: false);
    _drawLiquidStack(
      canvas,
      rightInner,
      destinationStack,
      lean: rightTilt / 0.18,
      wave: wavePhase + receiveSettle * 0.8,
      foam: foamLevel,
      settle: receiveSettle,
      isReceiving: true,
    );
    if (overflow > 0.0001) {
      _drawOverflow(canvas, rightInner, overflow, wavePhase);
    }
    canvas.restore();

    final Offset streamStart = _rotatePoint(
      Offset(leftInner.center.dx, leftInner.top + leftInner.height * 0.08),
      Offset(leftOuter.center.dx, leftOuter.bottom),
      leftTilt,
    );
    final Offset streamEnd = _rotatePoint(
      Offset(rightInner.center.dx, rightInner.top + rightInner.height * (0.12 + 0.08 * pourVisibility)),
      Offset(rightOuter.center.dx, rightOuter.bottom),
      rightTilt,
    );
    _drawStream(canvas, streamStart, streamEnd);
  }

  void _drawBaseShadow(Canvas canvas, Rect rect) {
    final Rect shadowRect = Rect.fromCenter(
      center: Offset(rect.center.dx, rect.bottom + 12),
      width: rect.width * 1.2,
      height: rect.width * 0.38,
    );
    final Paint paint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF0C1C2B).withOpacity(0.2),
          Colors.transparent,
        ],
      ).createShader(shadowRect);
    canvas.drawOval(shadowRect, paint);
  }

  void _applyTilt(Canvas canvas, Rect rect, double angle) {
    final Offset pivot = Offset(rect.center.dx, rect.bottom);
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(angle);
    canvas.translate(-pivot.dx, -pivot.dy);
  }

  Offset _rotatePoint(Offset point, Offset pivot, double angle) {
    final double sinAngle = math.sin(angle);
    final double cosAngle = math.cos(angle);
    final Offset translated = point - pivot;
    final double rotatedX = translated.dx * cosAngle - translated.dy * sinAngle;
    final double rotatedY = translated.dx * sinAngle + translated.dy * cosAngle;
    return Offset(rotatedX, rotatedY) + pivot;
  }

  void _drawGlass(Canvas canvas, RRect outer, RRect inner, {required bool emphasize}) {
    final Path glassBody = Path.combine(
      PathOperation.difference,
      Path()..addRRect(outer),
      Path()..addRRect(inner),
    );
    final Paint glassPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(0.18),
          Colors.white.withOpacity(0.04),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(outer.outerRect)
      ..blendMode = BlendMode.srcOver;
    canvas.drawPath(glassBody, glassPaint);

    final Paint innerFill = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF1D3557).withOpacity(0.08),
          const Color(0xFF1D3557).withOpacity(0.02),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(inner.outerRect);
    canvas.drawRRect(inner, innerFill);

    final Paint borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = inner.width * 0.05
      ..color = Colors.white.withOpacity(0.55);
    canvas.drawRRect(inner, borderPaint);

    final Rect rimRect = Rect.fromLTWH(
      inner.left,
      inner.top - inner.width * 0.08,
      inner.width,
      inner.width * 0.18,
    );
    final Paint rimPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(0.8),
          Colors.white.withOpacity(0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rimRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rimRect, Radius.circular(inner.width * 0.12)),
      rimPaint,
    );

    canvas.save();
    canvas.clipPath(Path()..addRRect(outer));
    final Rect highlightRect = Rect.fromLTWH(
      inner.left + inner.width * 0.68,
      inner.top + inner.height * 0.12,
      inner.width * 0.2,
      inner.height * 0.72,
    );
    final Paint highlightPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(emphasize ? 0.34 : 0.24),
          Colors.white.withOpacity(0.0),
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(highlightRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(highlightRect, Radius.circular(inner.width * 0.18)),
      highlightPaint,
    );
    canvas.restore();
  }

  void _drawLiquidStack(
    Canvas canvas,
    RRect bounds,
    List<_SegmentState> segments, {
    required double lean,
    required double wave,
    required double foam,
    required double settle,
    bool isReceiving = false,
  }) {
    if (segments.isEmpty) {
      return;
    }
    final Path clipPath = Path()..addRRect(bounds);
    canvas.save();
    canvas.clipPath(clipPath);

    final double availableHeight = bounds.height;
    final double baseY = bounds.bottom;
    final double inset = bounds.width * 0.1;
    final double leftX = bounds.left + inset;
    final double rightX = bounds.right - inset;
    double currentBottom = baseY;
    for (int index = 0; index < segments.length; index++) {
      final _SegmentState segment = segments[index];
      final double segmentHeight = availableHeight * segment.volume;
      if (segmentHeight <= 0.01) {
        continue;
      }
      final double bottomY = currentBottom;
      final double topY = bottomY - segmentHeight;
      currentBottom = topY;
      final double waveFactor = math.sin(wave * (1 + index * 0.14) + index * 0.9);
      final double viscosity = segment.viscosity;
      final double amplitude = bounds.width * 0.08 * (1 - viscosity * 0.7);
      final double leanOffset = lean * bounds.width * 0.16;
      final double settleLift = isReceiving ? math.sin((wave + index) * 0.6) * settle * 6 : 0;
      final double topLeftY = topY + waveFactor * amplitude + leanOffset + settleLift;
      final double topRightY = topY - waveFactor * amplitude + settleLift - leanOffset;

      final Path segmentPath = Path()
        ..moveTo(leftX, bottomY)
        ..lineTo(leftX, topLeftY)
        ..cubicTo(
          lerpDouble(leftX, rightX, 0.32)!,
          topLeftY - amplitude * 0.6,
          lerpDouble(leftX, rightX, 0.68)!,
          topRightY - amplitude * 0.6,
          rightX,
          topRightY,
        )
        ..lineTo(rightX, bottomY)
        ..close();

      final Rect boundsRect = segmentPath.getBounds();
      final Color baseColor = segment.color.withOpacity(segment.opacity);
      final Paint segmentPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            Color.lerp(baseColor, Colors.white, 0.2)!,
            Color.lerp(baseColor, Colors.black, 0.14)!,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(boundsRect);
      canvas.drawPath(segmentPath, segmentPaint);

      final Rect highlightRect = Rect.fromLTWH(
        boundsRect.left + boundsRect.width * 0.56,
        boundsRect.top + boundsRect.height * 0.12,
        boundsRect.width * 0.26,
        boundsRect.height * 0.78,
      );
      final Paint highlightPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withOpacity(lerpDouble(0.08, 0.32, 1 - viscosity)!),
            Colors.white.withOpacity(0.0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(highlightRect);
      canvas.save();
      canvas.clipPath(segmentPath);
      canvas.drawRRect(
        RRect.fromRectAndRadius(highlightRect, Radius.circular(boundsRect.width * 0.2)),
        highlightPaint,
      );
      canvas.restore();
    }

    if (isReceiving && foam > 0 && segments.isNotEmpty) {
      final double foamHeight = availableHeight * 0.045 * foam.clamp(0.0, 1.0);
      final double foamTop = currentBottom + bounds.height * 0.01;
      final Path foamPath = Path()..moveTo(leftX, foamTop);
      const int foamSegments = 5;
      for (int i = 0; i <= foamSegments; i++) {
        final double t = i / foamSegments;
        final double dx = lerpDouble(leftX, rightX, t)!;
        final double waveOffset = math.sin(wave * 1.3 + t * math.pi * 2) * foamHeight * 0.35;
        foamPath.lineTo(dx, foamTop - foamHeight + waveOffset);
      }
      foamPath
        ..lineTo(rightX, foamTop)
        ..close();
      final Paint foamPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withOpacity(0.62 * foam),
            Colors.white.withOpacity(0.0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTRB(leftX, foamTop - foamHeight, rightX, foamTop));
      canvas.drawPath(foamPath, foamPaint);
    }

    canvas.restore();
  }

  void _drawStream(Canvas canvas, Offset start, Offset end) {
    if (pourVisibility <= 0) {
      return;
    }
    final double t = pourVisibility.clamp(0.0, 1.0);
    final double curvature = lerpDouble(48, 72, 1 - sourceViscosity)!;
    final Offset controlPoint = Offset.lerp(start, end, 0.45)! +
        Offset(0, curvature * (0.4 - t * 0.6));
    final Path path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(controlPoint.dx, controlPoint.dy, end.dx, end.dy);

    final double baseWidth = lerpDouble(7, 15, t)!;
    final Paint glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = baseWidth * lerpDouble(1.4, 2.1, 1 - sourceViscosity)!
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF68DDFE).withOpacity(0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawPath(path, glowPaint);

    final Paint streamPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = baseWidth
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF68DDFE).withOpacity(0.82),
          Colors.white.withOpacity(0.95),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromPoints(start, end));
    canvas.drawPath(path, streamPaint);

    final Iterator<PathMetric> iterator = path.computeMetrics().iterator;
    if (iterator.moveNext()) {
      final PathMetric metric = iterator.current;
      for (int i = 0; i < 4; i++) {
        final double travel = (t * 0.6 + i / 4) % 1.0;
        final Tangent? tangent = metric.getTangentForOffset(metric.length * travel);
        if (tangent == null) {
          continue;
        }
        final double radius = lerpDouble(3, 6, travel)!;
        final Paint dropletPaint = Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white.withOpacity(lerpDouble(0.3, 0.75, 1 - sourceViscosity)! * t),
              Colors.white.withOpacity(0.0),
            ],
          ).createShader(Rect.fromCircle(center: tangent.position, radius: radius));
        canvas.drawCircle(tangent.position, radius, dropletPaint);
      }
    }
  }

  void _drawOverflow(Canvas canvas, RRect bounds, double overflowAmount, double wave) {
    final double t = overflowAmount.clamp(0.0, 0.24);
    final double startY = bounds.top + bounds.height * 0.08;
    final double endY = startY + bounds.height * (0.22 + 0.3 * t);
    final Path path = Path()
      ..moveTo(bounds.right, startY)
      ..quadraticBezierTo(
        bounds.right + bounds.width * 0.18,
        (startY + endY) / 2 + math.sin(wave * 1.4) * 6,
        bounds.right - bounds.width * 0.04,
        endY,
      );
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = bounds.width * 0.08 * (0.4 + t)
      ..shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(0.32 + t * 0.4),
          Colors.white.withOpacity(0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTRB(
        bounds.right - bounds.width * 0.2,
        startY,
        bounds.right + bounds.width * 0.24,
        endY + bounds.width * 0.18,
      ));
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WaterPainter oldDelegate) {
    return oldDelegate.leftTilt != leftTilt ||
        oldDelegate.rightTilt != rightTilt ||
        oldDelegate.wavePhase != wavePhase ||
        oldDelegate.pourVisibility != pourVisibility ||
        oldDelegate.overflow != overflow ||
        oldDelegate.foamLevel != foamLevel ||
        oldDelegate.receiveSettle != receiveSettle ||
        oldDelegate.sourceStack != sourceStack ||
        oldDelegate.destinationStack != destinationStack;
  }
}

class _SegmentRecipe {
  const _SegmentRecipe({
    required this.color,
    required this.volume,
    required this.viscosity,
    this.opacity = 0.9,
  });

  final Color color;
  final double volume;
  final double viscosity;
  final double opacity;

  _SegmentState toState(double volume) {
    return _SegmentState(
      color: color,
      volume: volume,
      viscosity: viscosity,
      opacity: opacity,
    );
  }
}

class _SegmentState {
  const _SegmentState({
    required this.color,
    required this.volume,
    required this.viscosity,
    required this.opacity,
  });

  final Color color;
  final double volume;
  final double viscosity;
  final double opacity;
}


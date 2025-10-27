import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({
    super.key,
    required this.colors,
    required this.child,
    this.beginAlignment = Alignment.topLeft,
    this.endAlignment = Alignment.bottomRight,
    this.opacity = 0.18,
    this.darkOverlay = false,
    this.showWaterBalloons = false,
    this.showBubbles = true,
  });

  final List<Color> colors;
  final Widget child;
  final Alignment beginAlignment;
  final Alignment endAlignment;
  final double opacity;
  final bool darkOverlay;
  final bool showWaterBalloons;
  final bool showBubbles;

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_FloatingBubble> _bubbles;
  late final List<_WaterBalloon> _balloons;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
    _generateFloatingElements();
  }

  void _generateFloatingElements() {
    _bubbles = List.generate(26, (index) {
      return _FloatingBubble(
        origin: Offset(_random.nextDouble(), _random.nextDouble()),
        radiusFactor: lerpDouble(0.012, 0.05, _random.nextDouble())!,
        verticalSpeed: lerpDouble(0.12, 0.28, _random.nextDouble())!,
        sway: lerpDouble(0.004, 0.02, _random.nextDouble())!,
        phase: _random.nextDouble() * 2 * math.pi,
        opacity: lerpDouble(0.2, 0.55, _random.nextDouble())!,
      );
    });
    _balloons = widget.showWaterBalloons
        ? List.generate(8, (index) {
            final size = lerpDouble(0.06, 0.12, _random.nextDouble())!;
            return _WaterBalloon(
              origin: Offset(_random.nextDouble(), _random.nextDouble()),
              sizeFactor: size,
              verticalSpeed: lerpDouble(0.04, 0.08, _random.nextDouble())!,
              waveIntensity: lerpDouble(0.018, 0.04, _random.nextDouble())!,
              hueShift: _random.nextDouble(),
              phase: _random.nextDouble() * 2 * math.pi,
            );
          })
        : const <_WaterBalloon>[];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradient = LinearGradient(
      colors: widget.colors,
      begin: widget.beginAlignment,
      end: widget.endAlignment,
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox.expand(
          child: CustomPaint(
            painter: _WaterBackgroundPainter(
              progress: _controller.value,
              gradient: gradient,
              opacity: widget.opacity,
              darkOverlay: widget.darkOverlay,
              bubbles: widget.showBubbles ? _bubbles : const [],
              balloons: widget.showWaterBalloons ? _balloons : const [],
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _WaterBackgroundPainter extends CustomPainter {
  _WaterBackgroundPainter({
    required this.progress,
    required this.gradient,
    required this.opacity,
    required this.darkOverlay,
    required this.bubbles,
    required this.balloons,
  });

  final double progress;
  final Gradient gradient;
  final double opacity;
  final bool darkOverlay;
  final List<_FloatingBubble> bubbles;
  final List<_WaterBalloon> balloons;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);

    if (darkOverlay) {
      final overlay = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.black.withOpacity(0.35),
            Colors.black.withOpacity(0.55),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(rect);
      canvas.drawRect(rect, overlay);
    }

    _drawLiquidWave(canvas, size);
    _drawBubbles(canvas, size);
    _drawBalloons(canvas, size);
  }

  void _drawLiquidWave(Canvas canvas, Size size) {
    final waveHeight = size.height * 0.18;
    final baseY = size.height * 0.82;
    final waveProgress = progress * 2 * math.pi;
    final path = Path()..moveTo(0, size.height);

    for (var x = 0.0; x <= size.width; x += size.width / 24) {
      final normalized = x / size.width;
      final primary = math.sin((normalized * 2 * math.pi) + waveProgress);
      final secondary = math.sin((normalized * 4 * math.pi) + waveProgress * 1.3);
      final tertiary = math.cos((normalized * 1.5 * math.pi) + waveProgress * 0.7);
      final y = baseY - primary * waveHeight * 0.18 - secondary * waveHeight * 0.14 - tertiary * waveHeight * 0.08;
      path.lineTo(x, y);
    }

    path
      ..lineTo(size.width, size.height)
      ..close();

    final rect = Offset.zero & size;
    final wavePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(opacity + 0.1),
          Colors.white.withOpacity(opacity * 0.45),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect);

    canvas.drawPath(path, wavePaint);

    final sparklePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withOpacity(opacity * 1.6);
    for (var i = 0; i < 12; i++) {
      final offsetX = (i / 11) * size.width;
      final wobble = math.sin(waveProgress + i) * 12;
      final sparkleY = baseY - 12 + wobble;
      final sparkleRect = Rect.fromCenter(
        center: Offset(offsetX, sparkleY),
        width: 8,
        height: 22,
      );
      canvas.save();
      canvas.translate(sparkleRect.center.dx, sparkleRect.center.dy);
      canvas.rotate((math.sin(waveProgress * 1.4 + i) + 1) * 0.08);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: sparkleRect.width, height: sparkleRect.height),
          const Radius.circular(6),
        ),
        sparklePaint,
      );
      canvas.restore();
    }
  }

  void _drawBubbles(Canvas canvas, Size size) {
    if (bubbles.isEmpty) {
      return;
    }

    final bubblePaint = Paint()..style = PaintingStyle.fill;
    final outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (final bubble in bubbles) {
      final travel = (progress * bubble.verticalSpeed + bubble.phase / (2 * math.pi)) % 1.0;
      final bubbleY = size.height * (1 - travel);
      final sway = math.sin(progress * 2 * math.pi + bubble.phase) * bubble.sway * size.width;
      final bubbleX = bubble.origin.dx * size.width + sway;
      final radius = bubble.radiusFactor * size.width;
      final center = Offset(bubbleX, bubbleY);

      bubblePaint.color = Colors.white.withOpacity(bubble.opacity * 0.8);
      outlinePaint.color = Colors.white.withOpacity(bubble.opacity);
      canvas.drawCircle(center, radius, bubblePaint);
      canvas.drawCircle(center, radius, outlinePaint);

      final highlightOffset = Offset(radius * -0.3, radius * -0.4);
      canvas.drawCircle(
        center + highlightOffset,
        radius * 0.35,
        Paint()..color = Colors.white.withOpacity(bubble.opacity + 0.1),
      );
    }
  }

  void _drawBalloons(Canvas canvas, Size size) {
    if (balloons.isEmpty) {
      return;
    }
    for (final balloon in balloons) {
      final travel = (progress * balloon.verticalSpeed + balloon.phase / (2 * math.pi)) % 1.0;
      final baseY = size.height * (1.1 - travel);
      final wave = math.sin(progress * 2 * math.pi + balloon.phase) * balloon.waveIntensity * size.width;
      final x = (balloon.origin.dx * size.width) + wave;
      final y = baseY - math.sin(progress * 2 * math.pi * 0.6 + balloon.phase) * size.height * 0.04;
      final balloonSize = size.shortestSide * balloon.sizeFactor;

      _drawBalloon(canvas, Offset(x, y), balloonSize, balloon.hueShift);
    }
  }

  void _drawBalloon(Canvas canvas, Offset center, double size, double hueShift) {
    final path = Path();
    final width = size;
    final height = size * 1.35;
    final top = center.translate(0, -height * 0.5);
    final bottom = center.translate(0, height * 0.5);

    path.moveTo(bottom.dx, bottom.dy - height * 0.08);
    path.cubicTo(
      bottom.dx + width * 0.22,
      bottom.dy - height * 0.26,
      top.dx + width * 0.3,
      top.dy + height * 0.2,
      top.dx,
      top.dy,
    );
    path.cubicTo(
      top.dx - width * 0.3,
      top.dy + height * 0.2,
      bottom.dx - width * 0.22,
      bottom.dy - height * 0.26,
      bottom.dx,
      bottom.dy - height * 0.08,
    );
    path.close();

    final gradient = RadialGradient(
      center: Alignment.topCenter,
      radius: 1.1,
      colors: [
        HSLColor.fromAHSL(1, (210 + hueShift * 90) % 360, 0.7, 0.72).toColor(),
        HSLColor.fromAHSL(1, (190 + hueShift * 120) % 360, 0.75, 0.58).toColor(),
      ],
    );

    final tail = Path()
      ..moveTo(bottom.dx, bottom.dy - height * 0.05)
      ..quadraticBezierTo(
        bottom.dx + width * 0.1,
        bottom.dy + height * 0.04,
        bottom.dx,
        bottom.dy + height * 0.12,
      )
      ..quadraticBezierTo(
        bottom.dx - width * 0.1,
        bottom.dy + height * 0.04,
        bottom.dx,
        bottom.dy - height * 0.05,
      );

    final tailPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(0.4),
          Colors.white.withOpacity(0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(tail.getBounds());

    canvas.drawPath(tail, tailPaint);

    final balloonPaint = Paint()..shader = gradient.createShader(path.getBounds());
    canvas.drawPath(path, balloonPaint);

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withOpacity(0.35),
    );

    final highlight = Path()
      ..moveTo(top.dx + width * 0.12, top.dy + height * 0.22)
      ..quadraticBezierTo(
        top.dx + width * 0.24,
        top.dy + height * 0.28,
        top.dx + width * 0.16,
        top.dy + height * 0.5,
      );

    canvas.drawPath(
      highlight,
      Paint()
        ..color = Colors.white.withOpacity(0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _WaterBackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.gradient != gradient ||
        oldDelegate.darkOverlay != darkOverlay ||
        oldDelegate.balloons.length != balloons.length ||
        oldDelegate.bubbles.length != bubbles.length;
  }
}

class _FloatingBubble {
  _FloatingBubble({
    required this.origin,
    required this.radiusFactor,
    required this.verticalSpeed,
    required this.sway,
    required this.phase,
    required this.opacity,
  });

  final Offset origin;
  final double radiusFactor;
  final double verticalSpeed;
  final double sway;
  final double phase;
  final double opacity;
}

class _WaterBalloon {
  const _WaterBalloon({
    required this.origin,
    required this.sizeFactor,
    required this.verticalSpeed,
    required this.waveIntensity,
    required this.hueShift,
    required this.phase,
  });

  final Offset origin;
  final double sizeFactor;
  final double verticalSpeed;
  final double waveIntensity;
  final double hueShift;
  final double phase;
}

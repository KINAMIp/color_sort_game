import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

class DarkPatternBackground extends StatefulWidget {
  const DarkPatternBackground({
    super.key,
    required this.child,
    this.animate = true,
  });

  final Widget child;
  final bool animate;

  @override
  State<DarkPatternBackground> createState() => _DarkPatternBackgroundState();
}

class _DarkPatternBackgroundState extends State<DarkPatternBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_PatternGlyph> _glyphs;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    );
    if (widget.animate) {
      _controller.repeat();
    }
    _glyphs = List.generate(18, (index) {
      final random = math.Random(index * 73 + 11);
      final type = _GlyphType.values[index % _GlyphType.values.length];
      return _PatternGlyph(
        anchor: Offset(random.nextDouble(), random.nextDouble()),
        size: lerpDouble(64, 104, random.nextDouble())!,
        rotation: lerpDouble(-0.45, 0.45, random.nextDouble())!,
        driftSpeed: lerpDouble(0.02, 0.08, random.nextDouble())!,
        phase: random.nextDouble() * math.pi * 2,
        opacity: lerpDouble(0.05, 0.16, random.nextDouble())!,
        type: type,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _DarkPatternPainter(
              progress: widget.animate ? _controller.value : 0,
              glyphs: _glyphs,
            ),
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

class _DarkPatternPainter extends CustomPainter {
  _DarkPatternPainter({
    required this.progress,
    required this.glyphs,
  });

  final double progress;
  final List<_PatternGlyph> glyphs;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final gradientShader = const LinearGradient(
      colors: [Color(0xFF070711), Color(0xFF121327), Color(0xFF050507)],
      stops: [0.0, 0.55, 1.0],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(rect);
    canvas.drawRect(rect, Paint()..shader = gradientShader);

    final vignetteShader = RadialGradient(
      colors: [Colors.transparent, Colors.black.withOpacity(0.52)],
      stops: const [0.62, 1.0],
      center: Alignment.center,
      radius: 1.1,
    ).createShader(rect);
    canvas.drawRect(rect, Paint()..shader = vignetteShader);

    for (final glyph in glyphs) {
      glyph.paint(canvas, size, progress);
    }
  }

  @override
  bool shouldRepaint(covariant _DarkPatternPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.glyphs != glyphs;
  }
}

class _PatternGlyph {
  _PatternGlyph({
    required this.anchor,
    required this.size,
    required this.rotation,
    required this.driftSpeed,
    required this.phase,
    required this.opacity,
    required this.type,
  });

  final Offset anchor;
  final double size;
  final double rotation;
  final double driftSpeed;
  final double phase;
  final double opacity;
  final _GlyphType type;

  void paint(Canvas canvas, Size size, double progress) {
    final double wave = math.sin(progress * 2 * math.pi + phase) * 18;
    final double offsetX = anchor.dx * size.width + wave;
    final double offsetY =
        (anchor.dy * size.height + progress * driftSpeed * size.height) %
            size.height;

    for (var tileX = -1; tileX <= 1; tileX++) {
      for (var tileY = -1; tileY <= 1; tileY++) {
        final position = Offset(
          offsetX + tileX * size.width,
          offsetY + tileY * size.height,
        );
        if (position.dx < -this.size ||
            position.dx > size.width + this.size ||
            position.dy < -this.size ||
            position.dy > size.height + this.size) {
          continue;
        }
        canvas.save();
        canvas.translate(position.dx, position.dy);
        canvas.rotate(rotation + math.sin(progress * 2 * math.pi + phase) * 0.08);
        _drawGlyph(canvas, this.size, opacity, type);
        canvas.restore();
      }
    }
  }

  void _drawGlyph(
    Canvas canvas,
    double glyphSize,
    double opacity,
    _GlyphType type,
  ) {
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withOpacity(opacity)
      ..strokeWidth = glyphSize * 0.06
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    switch (type) {
      case _GlyphType.tube:
        final bodyHeight = glyphSize * 0.82;
        final radius = glyphSize * 0.26;
        final rect = Rect.fromCenter(
          center: Offset(0, glyphSize * 0.02),
          width: glyphSize * 0.52,
          height: bodyHeight,
        );
        final path = Path()
          ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
        canvas.drawPath(path, strokePaint);
        final rim = Rect.fromCenter(
          center: Offset(0, -bodyHeight / 2 - glyphSize * 0.06),
          width: rect.width * 0.96,
          height: glyphSize * 0.26,
        );
        canvas.drawOval(rim, strokePaint..strokeWidth = glyphSize * 0.05);
        break;
      case _GlyphType.crown:
        final path = Path()
          ..moveTo(-glyphSize * 0.4, glyphSize * 0.34)
          ..lineTo(-glyphSize * 0.22, -glyphSize * 0.2)
          ..lineTo(0, glyphSize * 0.16)
          ..lineTo(glyphSize * 0.22, -glyphSize * 0.2)
          ..lineTo(glyphSize * 0.4, glyphSize * 0.34)
          ..close();
        canvas.drawPath(path, strokePaint);
        canvas.drawCircle(
          Offset(-glyphSize * 0.24, -glyphSize * 0.22),
          glyphSize * 0.06,
          strokePaint,
        );
        canvas.drawCircle(
          Offset(glyphSize * 0.24, -glyphSize * 0.22),
          glyphSize * 0.06,
          strokePaint,
        );
        canvas.drawCircle(
          Offset(0, -glyphSize * 0.3),
          glyphSize * 0.065,
          strokePaint,
        );
        break;
      case _GlyphType.droplet:
        final path = Path()
          ..moveTo(0, -glyphSize * 0.42)
          ..cubicTo(
            glyphSize * 0.32,
            -glyphSize * 0.12,
            glyphSize * 0.28,
            glyphSize * 0.26,
            0,
            glyphSize * 0.38,
          )
          ..cubicTo(
            -glyphSize * 0.28,
            glyphSize * 0.26,
            -glyphSize * 0.32,
            -glyphSize * 0.12,
            0,
            -glyphSize * 0.42,
          );
        canvas.drawPath(path, strokePaint);
        break;
      case _GlyphType.star:
        final path = Path();
        const points = 5;
        for (var i = 0; i <= points; i++) {
          final angle = (math.pi * 2 * i) / points - math.pi / 2;
          final radius = i.isEven ? glyphSize * 0.4 : glyphSize * 0.18;
          final point = Offset(
            math.cos(angle) * radius,
            math.sin(angle) * radius,
          );
          if (i == 0) {
            path.moveTo(point.dx, point.dy);
          } else {
            path.lineTo(point.dx, point.dy);
          }
        }
        path.close();
        canvas.drawPath(path, strokePaint);
        break;
    }
  }
}

enum _GlyphType { tube, crown, droplet, star }

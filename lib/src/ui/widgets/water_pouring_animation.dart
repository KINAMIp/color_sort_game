import 'dart:math' as math;

import 'package:flutter/material.dart';

class WaterPouringAnimation extends StatefulWidget {
  const WaterPouringAnimation({super.key});

  @override
  State<WaterPouringAnimation> createState() => _WaterPouringAnimationState();
}

class _WaterPouringAnimationState extends State<WaterPouringAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pourProgress;
  late final Animation<double> _wavePhase;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2800),
      vsync: this,
    );

    _pourProgress = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );

    _wavePhase = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.linear),
      ),
    );

    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startPouring() {
    if (_controller.isAnimating) {
      return;
    }
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _startPouring,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : 360;
          const double height = 260;
          return SizedBox(
            width: width,
            height: height,
            child: CustomPaint(
              size: Size(width, height),
              painter: _WaterPainter(
                pourProgress: _pourProgress.value,
                wavePhase: _wavePhase.value,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WaterPainter extends CustomPainter {
  _WaterPainter({required this.pourProgress, required this.wavePhase});

  final double pourProgress;
  final double wavePhase;

  final Paint _tubePaint = Paint()
    ..color = Colors.white.withOpacity(0.6)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.0
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.4);

  final Paint _waterPaint = Paint()
    ..shader = const LinearGradient(
      colors: [Color(0xFF72E1FF), Color(0xFF1EAEFF)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(const Rect.fromLTWH(0, 0, 140, 240));

  final Paint _streamPaint = Paint()
    ..color = const Color(0xAA72E1FF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 14
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.4);

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width.clamp(0.0, 420.0);
    final double horizontalPadding = (size.width - width) / 2;
    final double tubeWidth = math.min(110, width * 0.28);
    final double tubeHeight = 200;
    final double baseY = size.height - 30;

    final Rect leftTube = Rect.fromLTWH(
      horizontalPadding + 30,
      baseY - tubeHeight,
      tubeWidth,
      tubeHeight,
    );
    final Rect rightTube = Rect.fromLTWH(
      size.width - horizontalPadding - tubeWidth - 30,
      baseY - tubeHeight,
      tubeWidth,
      tubeHeight,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(leftTube, const Radius.circular(22)),
      _tubePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rightTube, const Radius.circular(22)),
      _tubePaint,
    );

    _drawWater(canvas, leftTube, _levelForLeftTube(leftTube.height));
    _drawWater(canvas, rightTube, _levelForRightTube(rightTube.height));
    _drawStream(canvas, leftTube, rightTube);
  }

  double _levelForLeftTube(double height) {
    const double startFill = 0.78;
    const double endFill = 0.12;
    return _lerp(startFill, endFill, pourProgress) * height;
  }

  double _levelForRightTube(double height) {
    const double startFill = 0.16;
    const double endFill = 0.88;
    return _lerp(startFill, endFill, pourProgress) * height;
  }

  void _drawWater(Canvas canvas, Rect rect, double fillHeight) {
    final double waveAmplitude = 6 + 6 * math.sin(pourProgress * math.pi);
    final double top = rect.bottom - fillHeight;
    final Path path = Path()
      ..moveTo(rect.left, rect.bottom)
      ..lineTo(rect.left, top);

    const int segments = 28;
    for (int i = 0; i <= segments; i++) {
      final double t = i / segments;
      final double dx = rect.left + rect.width * t;
      final double dy = top + math.sin((t * math.pi * 2) + wavePhase) * waveAmplitude;
      path.lineTo(dx, dy);
    }

    path
      ..lineTo(rect.right, rect.bottom)
      ..close();

    final Paint paint = _waterPaint
      ..shader = const LinearGradient(
        colors: [Color(0xFF8EE7FF), Color(0xFF279BFF)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect);

    canvas.drawPath(path, paint);

    final Paint highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final Path highlight = Path();
    final double highlightY = top + rect.height * 0.08;
    highlight.moveTo(rect.left + rect.width * 0.18, highlightY);
    highlight.quadraticBezierTo(
      rect.left + rect.width * 0.48,
      highlightY - 6,
      rect.left + rect.width * 0.82,
      highlightY,
    );
    canvas.drawPath(highlight, highlightPaint);
  }

  void _drawStream(Canvas canvas, Rect from, Rect to) {
    final double streamStartProgress = 0.1;
    final double streamEndProgress = 0.92;
    final double t = ((pourProgress - streamStartProgress) /
            (streamEndProgress - streamStartProgress))
        .clamp(0.0, 1.0);
    if (t <= 0) {
      return;
    }

    final Offset start = Offset(from.center.dx, from.top + 18);
    final Offset end = Offset(to.center.dx, to.top + 48);
    final double controlOffsetY = 80 + 40 * (1 - t);
    final Offset control1 = Offset(
      start.dx + _lerp(0, (to.left - from.right) * 0.3, t),
      start.dy + controlOffsetY,
    );
    final Offset control2 = Offset(
      end.dx - _lerp(0, (to.left - from.right) * 0.2, t),
      end.dy - controlOffsetY * 0.6,
    );

    final Path streamPath = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(
        control1.dx,
        control1.dy,
        control2.dx,
        control2.dy,
        _lerp(start.dx, end.dx, t),
        _lerp(start.dy, end.dy, t),
      );

    canvas.drawPath(streamPath, _streamPaint);
  }

  @override
  bool shouldRepaint(covariant _WaterPainter oldDelegate) {
    return oldDelegate.pourProgress != pourProgress ||
        oldDelegate.wavePhase != wavePhase;
  }
}

double _lerp(double a, double b, double t) => a + (b - a) * t;

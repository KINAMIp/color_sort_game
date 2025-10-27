import 'dart:math' as math;
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
  });

  final List<Color> colors;
  final Widget child;
  final Alignment beginAlignment;
  final Alignment endAlignment;
  final double opacity;
  final bool darkOverlay;

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = _resolveSize(constraints, MediaQuery.sizeOf(context));
        final gradient = LinearGradient(
          colors: widget.colors,
          begin: widget.beginAlignment,
          end: widget.endAlignment,
        );

        return AnimatedBuilder(
          animation: _controller,
          child: widget.child,
          builder: (context, child) {
            final t = _controller.value;
            final wave1 = math.sin(2 * math.pi * t);
            final wave2 = math.cos(2 * math.pi * (t + 0.25));
            final wave3 = math.sin(2 * math.pi * (t + 0.5));
            return SizedBox(
              width: size.width,
              height: size.height,
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: gradient),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (widget.darkOverlay)
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.4),
                              Colors.black.withOpacity(0.65),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    Positioned(
                      top: 120 + wave1 * 40,
                      right: -60 + wave2 * 30,
                      child: _GlowingBlob(
                        size: 220,
                        color: Colors.white.withOpacity(widget.opacity),
                      ),
                    ),
                    Positioned(
                      bottom: 80 + wave2 * 50,
                      left: -40 + wave3 * 30,
                      child: _GlowingBlob(
                        size: 180,
                        color: Colors.white.withOpacity(widget.opacity),
                      ),
                    ),
                    Positioned(
                      top: 20 + wave3 * 30,
                      left: 80 + wave1 * 50,
                      child: _GlowingBlob(
                        size: 120,
                        color: Colors.white.withOpacity(widget.opacity * 0.8),
                      ),
                    ),
                    if (child != null) child!,
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

Size _resolveSize(BoxConstraints constraints, Size fallback) {
  final width = constraints.hasBoundedWidth ? constraints.maxWidth : fallback.width;
  final height = constraints.hasBoundedHeight ? constraints.maxHeight : fallback.height;
  return Size(width, height);
}

class _GlowingBlob extends StatelessWidget {
  const _GlowingBlob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withOpacity(0)],
          ),
        ),
      ),
    );
  }
}

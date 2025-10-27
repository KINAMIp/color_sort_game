import 'package:flutter/material.dart';

class AnimatedGradientText extends StatefulWidget {
  const AnimatedGradientText(
    this.text, {
    super.key,
    required this.gradient,
    this.style,
    this.duration = const Duration(seconds: 4),
  });

  final String text;
  final Gradient gradient;
  final TextStyle? style;
  final Duration duration;

  @override
  State<AnimatedGradientText> createState() => _AnimatedGradientTextState();
}

class _AnimatedGradientTextState extends State<AnimatedGradientText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    final duration = widget.duration.inMicroseconds <= 0
        ? const Duration(milliseconds: 16)
        : widget.duration;
    _controller = AnimationController(vsync: this, duration: duration)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final slide = Tween(begin: -1.0, end: 1.0).transform(_controller.value);
        return ShaderMask(
          shaderCallback: (bounds) {
            final rect = Rect.fromLTWH(0, 0, bounds.width, bounds.height);
            return widget.gradient
                .createShader(rect.shift(Offset(bounds.width * slide * 0.3, 0)));
          },
          child: child,
        );
      },
      child: Text(
        widget.text,
        textAlign: TextAlign.center,
        style: widget.style?.copyWith(color: Colors.white) ??
            TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
      ),
    );
  }
}

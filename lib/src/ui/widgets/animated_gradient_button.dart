import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AnimatedGradientButton extends StatefulWidget {
  const AnimatedGradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.colors,
    this.icon,
    this.padding = const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
  });

  final String text;
  final VoidCallback? onPressed;
  final List<Color> colors;
  final IconData? icon;
  final EdgeInsets padding;

  @override
  State<AnimatedGradientButton> createState() => _AnimatedGradientButtonState();
}

class _AnimatedGradientButtonState extends State<AnimatedGradientButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _hovering = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      lowerBound: 0.0,
      upperBound: 0.08,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(_) {
    _controller.forward();
  }

  void _onTapUp(_) {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return MouseRegion(
      onEnter: (_) {
        if (!enabled) {
          return;
        }
        setState(() => _hovering = true);
      },
      onExit: (_) {
        if (!enabled) {
          return;
        }
        setState(() => _hovering = false);
      },
      child: GestureDetector(
        onTapDown: enabled ? _onTapDown : null,
        onTapUp: enabled ? _onTapUp : null,
        onTapCancel: enabled ? () => _controller.reverse() : null,
        onTap: enabled
            ? () {
                HapticFeedback.lightImpact();
                widget.onPressed?.call();
              }
            : null,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final tapScale = 1 - _controller.value;
            final hoverScale = _hovering ? 1.05 : 1.0;
            return AnimatedScale(
              duration: const Duration(milliseconds: 180),
              scale: enabled ? tapScale * hoverScale : 1,
              curve: Curves.easeInOut,
              child: Opacity(
                opacity: enabled ? 1 : 0.6,
                child: child,
              ),
            );
          },
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: widget.colors),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: widget.colors.last.withOpacity(0.45),
                  blurRadius: 20,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Padding(
              padding: widget.padding,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, color: Colors.white),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    widget.text,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: Colors.white,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

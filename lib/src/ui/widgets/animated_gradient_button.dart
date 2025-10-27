import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';

class AnimatedGradientButton extends StatefulWidget {
  const AnimatedGradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.colors,
    this.icon,
    this.padding = const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
    this.textGradient,
  });

  final String text;
  final VoidCallback? onPressed;
  final List<Color> colors;
  final IconData? icon;
  final EdgeInsets padding;
  final Gradient? textGradient;

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

  AppState? _appState(BuildContext context) {
    if (!context.mounted) {
      return null;
    }

    try {
      return Provider.of<AppState>(context, listen: false);
    } on ProviderNotFoundException {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final brightenedColors = widget.colors
        .map((color) => Color.lerp(color, Colors.white, 0.2) ?? color)
        .toList(growable: false);
    final gradient = LinearGradient(colors: brightenedColors);
    final textGradient = widget.textGradient ??
        LinearGradient(
          colors: [
            brightenedColors.first,
            Color.lerp(brightenedColors.last, Colors.white, 0.3)!,
          ],
        );
    return MouseRegion(
      onEnter: (_) {
        if (!enabled) {
          return;
        }
        _appState(context)?.audioService.playButtonHover();
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
                _appState(context)?.audioService.playButtonTap();
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
              gradient: gradient,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: brightenedColors.last.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: AnimatedOpacity(
                    opacity: _hovering ? 0.28 : 0,
                    duration: const Duration(milliseconds: 260),
                    child: _BubblyOverlay(colors: brightenedColors),
                  ),
                ),
                Padding(
                  padding: widget.padding,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(
                          widget.icon,
                          color: Color.lerp(Colors.white, brightenedColors.last, 0.1) ?? Colors.white,
                        ),
                        const SizedBox(width: 12),
                      ],
                      ShaderMask(
                        shaderCallback: (bounds) =>
                            textGradient.createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                        blendMode: BlendMode.srcIn,
                        child: Text(
                          widget.text,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: Colors.white,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BubblyOverlay extends StatelessWidget {
  const _BubblyOverlay({required this.colors});

  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final bubbles = <Widget>[];
    final positions = const [
      Offset(0.2, 0.3),
      Offset(0.45, 0.65),
      Offset(0.7, 0.25),
      Offset(0.86, 0.6),
    ];
    for (var i = 0; i < positions.length; i++) {
      final offset = positions[i];
      bubbles.add(
        Positioned.fill(
          child: FractionallySizedBox(
            widthFactor: 0.08 + i * 0.02,
            heightFactor: 0.08 + i * 0.02,
            alignment: Alignment(offset.dx * 2 - 1, offset.dy * 2 - 1),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.85),
                    colors.first.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Stack(children: bubbles);
  }
}

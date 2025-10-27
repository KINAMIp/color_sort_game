import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../game/crayon_game.dart';
import '../widgets/animated_gradient_button.dart';
import '../widgets/animated_gradient_text.dart';
import '../widgets/glass_card.dart';

class OutOfMovesOverlay extends StatefulWidget {
  const OutOfMovesOverlay({
    super.key,
    required this.game,
    required this.onRetry,
    required this.onExit,
  });

  final CrayonGame game;
  final VoidCallback onRetry;
  final VoidCallback onExit;

  @override
  State<OutOfMovesOverlay> createState() => _OutOfMovesOverlayState();
}

class _OutOfMovesOverlayState extends State<OutOfMovesOverlay> {
  @override
  void initState() {
    super.initState();
    widget.game.audioService.playOutOfMoves();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF020621), Color(0xFF071539)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Center(
            child: GlassCard(
              borderRadius: 32,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              color: Colors.white.withOpacity(0.16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedGradientText(
                    'Out of moves',
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF7BAC), Color(0xFF9C6BFF), Color(0xFF7CF6F3)],
                    ),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 36,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'You have used every move available. Try the level again or exit to the menu.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white.withOpacity(0.85),
                          height: 1.4,
                        ),
                  ).animate().fadeIn(duration: const Duration(milliseconds: 360)),
                  const SizedBox(height: 26),
                  AnimatedGradientButton(
                    text: 'Restart the level',
                    colors: const [Color(0xFF7CF6F3), Color(0xFF7288FF)],
                    icon: Icons.restart_alt_rounded,
                    onPressed: () {
                      widget.onRetry();
                    },
                  ),
                  const SizedBox(height: 16),
                  AnimatedGradientButton(
                    text: 'Exit the game',
                    colors: const [Color(0xFFFF9A9E), Color(0xFFFF7BAC)],
                    icon: Icons.exit_to_app_rounded,
                    onPressed: widget.onExit,
                  ),
                ],
              ),
            )
                .animate()
                .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0), curve: Curves.easeOutBack)
                .fadeIn(duration: const Duration(milliseconds: 280)),
          ),
        ],
      ),
    );
  }
}

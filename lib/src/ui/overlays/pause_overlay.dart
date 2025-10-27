import 'package:flutter/material.dart';

import '../../game/crayon_game.dart';
import '../widgets/animated_gradient_button.dart';
import '../widgets/animated_gradient_text.dart';
import '../widgets/glass_card.dart';

class PauseOverlay extends StatelessWidget {
  const PauseOverlay({
    super.key,
    required this.game,
    required this.onExit,
  });

  final CrayonGame game;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.45),
            ),
          ),
          Center(
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
              borderRadius: 32,
              color: Colors.white.withOpacity(0.18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedGradientText(
                    'Paused',
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF7BAC), Color(0xFF9C6BFF)],
                    ),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 24),
                  AnimatedGradientButton(
                    text: 'Resume',
                    colors: const [Color(0xFF7CF6F3), Color(0xFF7288FF)],
                    onPressed: () {
                      game.resumeGame();
                    },
                  ),
                  const SizedBox(height: 16),
                  AnimatedGradientButton(
                    text: 'Restart Level',
                    colors: const [Color(0xFFFFCA7A), Color(0xFFFF7BAC)],
                    onPressed: () {
                      game.resetLevel();
                      game.resumeGame();
                    },
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: onExit,
                    child: const Text(
                      'Exit to Menu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

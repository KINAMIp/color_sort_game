import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../game/crayon_game.dart';
import '../widgets/animated_gradient_button.dart';
import '../widgets/animated_gradient_text.dart';
import '../widgets/glass_card.dart';

class LevelCompleteOverlay extends StatelessWidget {
  const LevelCompleteOverlay({
    super.key,
    required this.game,
    required this.onNextLevel,
    required this.onExit,
  });

  final CrayonGame game;
  final VoidCallback onNextLevel;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF111827)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: _ConfettiLayer(),
          ),
        ),
        Center(
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
            borderRadius: 36,
            color: Colors.white.withOpacity(0.18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedGradientText(
                  'Level Completed!',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF7BAC), Color(0xFFFFCA7A), Color(0xFF72E4A2)],
                  ),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Moves used: ${game.movesMade}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white.withOpacity(0.85),
                      ),
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        Icons.star_rounded,
                        color: Colors.amberAccent,
                        size: 34,
                      )
                          .animate(onComplete: (controller) => controller.repeat())
                          .scale(
                            curve: Curves.easeInOutBack,
                            duration: const Duration(milliseconds: 800),
                            begin: const Offset(0.85, 0.85),
                            end: const Offset(1.1, 1.1),
                          ),
                    );
                  }),
                ),
                const SizedBox(height: 28),
                AnimatedGradientButton(
                  text: 'Next Level',
                  colors: const [Color(0xFF7CF6F3), Color(0xFF7288FF)],
                  onPressed: onNextLevel,
                ),
                const SizedBox(height: 16),
                AnimatedGradientButton(
                  text: 'Replay Level',
                  colors: const [Color(0xFFFFCA7A), Color(0xFFFF7BAC)],
                  onPressed: () {
                    game.resetLevel();
                  },
                ),
                const SizedBox(height: 18),
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
    );
  }
}

class _ConfettiLayer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFFFF7BAC),
      const Color(0xFF7CF6F3),
      const Color(0xFFFFCA7A),
      const Color(0xFF9C6BFF),
      const Color(0xFF72E4A2),
    ];
    return Stack(
      children: List.generate(18, (index) {
        final alignment = Alignment(
          (-1 + (index % 6) * 0.4) + (index.isEven ? 0.1 : -0.1),
          -1 + (index ~/ 6) * 0.7,
        );
        final color = colors[index % colors.length];
        return Align(
          alignment: alignment,
          child: Icon(
            Icons.blur_on,
            color: color.withOpacity(0.75),
            size: 20 + (index % 4) * 6,
          )
              .animate(delay: Duration(milliseconds: index * 120))
              .moveY(
                begin: -80,
                end: 120,
                duration: const Duration(seconds: 3),
                curve: Curves.easeInOut,
              )
              .fadeOut(duration: const Duration(milliseconds: 600))
              .then()
              .fadeIn(duration: const Duration(milliseconds: 300))
              .then()
              .moveY(
                begin: -120,
                end: 140,
                duration: const Duration(seconds: 3),
                curve: Curves.easeInOut,
              )
              .then(delay: const Duration(milliseconds: 200))
              .animate(onComplete: (controller) => controller.repeat());
      }),
    );
  }
}

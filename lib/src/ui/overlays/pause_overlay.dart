import 'package:flutter/material.dart';

import '../../game/crayon_game.dart';
import '../widgets/dark_pattern_background.dart';
import '../widgets/filled_action_button.dart';

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
    final theme = Theme.of(context);
    return SizedBox.expand(
      child: Stack(
        children: [
          DarkPatternBackground(
            child: Container(color: Colors.black.withOpacity(0.6)),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                decoration: BoxDecoration(
                  color: const Color(0xFF18192B).withOpacity(0.94),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x6617182A),
                      blurRadius: 24,
                      offset: Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Paused',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Take a quick breather before diving back into the puzzle.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.72),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    FilledActionButton(
                      label: 'Resume',
                      colors: const [Color(0xFF68F5B4), Color(0xFF46DCD5)],
                      onPressed: () {
                        game.resumeGame();
                      },
                    ),
                    const SizedBox(height: 14),
                    FilledActionButton(
                      label: 'Restart',
                      colors: const [Color(0xFF586DFF), Color(0xFF8B55FF)],
                      onPressed: () {
                        game.resetLevel();
                        game.resumeGame();
                      },
                    ),
                    const SizedBox(height: 14),
                    TextButton(
                      onPressed: onExit,
                      child: const Text(
                        'Exit to menu',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

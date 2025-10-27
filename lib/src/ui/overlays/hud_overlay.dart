import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../game/crayon_game.dart';
import '../../state/app_state.dart';
import '../widgets/animated_gradient_button.dart';
import '../widgets/glass_card.dart';

class HudOverlay extends StatelessWidget {
  const HudOverlay({
    super.key,
    required this.game,
    required this.onPause,
  });

  final CrayonGame game;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final movesTextStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        );
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              borderRadius: 24,
              color: Colors.black.withOpacity(0.25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Level ${appState.selectedLevelId}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 6),
                  ValueListenableBuilder<int>(
                    valueListenable: game.movesNotifier,
                    builder: (context, value, _) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Color(0xFFFFCA7A), Color(0xFFFF7BAC)],
                              ),
                            ),
                            child: const Icon(
                              Icons.auto_awesome,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text('Moves: $value', style: movesTextStyle),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const Spacer(),
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              borderRadius: 22,
              color: Colors.black.withOpacity(0.22),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () {
                      appState.toggleSound();
                    },
                    icon: Icon(
                      appState.soundEnabled
                          ? Icons.volume_up_rounded
                          : Icons.volume_off_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedGradientButton(
                    text: 'Pause',
                    colors: const [Color(0xFF7CF6F3), Color(0xFF7288FF)],
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    onPressed: onPause,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../game/crayon_game.dart';
import '../widgets/dark_pattern_background.dart';
import '../widgets/filled_action_button.dart';

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
    final theme = Theme.of(context);
    return SizedBox.expand(
      child: Stack(
        children: [
          DarkPatternBackground(
            child: Container(color: Colors.black.withOpacity(0.6)),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 36),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1B30).withOpacity(0.95),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x6617182A),
                      blurRadius: 26,
                      offset: Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Out of moves',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "You've used every move available. Try reshuffling your strategy and go again!",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.74),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 30),
                    FilledActionButton(
                      label: 'Try again',
                      colors: const [Color(0xFF68F5B4), Color(0xFF46DCD5)],
                      onPressed: widget.onRetry,
                    ),
                    const SizedBox(height: 16),
                    FilledActionButton(
                      label: 'Exit to menu',
                      colors: const [Color(0xFFFF6F91), Color(0xFFFF9671)],
                      onPressed: widget.onExit,
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

import 'package:flutter/material.dart';

import '../../game/crayon_game.dart';

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
    return Center(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Level Complete!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text('Moves: ${game.movesMade}'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  return const Icon(Icons.star, color: Colors.amber, size: 28);
                }),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  onNextLevel();
                },
                child: const Text('Next Level'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  game.resetLevel();
                },
                child: const Text('Replay Level'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: onExit,
                child: const Text('Exit to Menu'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

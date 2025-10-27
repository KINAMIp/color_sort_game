import 'package:flutter/material.dart';

import '../../game/crayon_game.dart';

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
    return Center(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Paused',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  game.resumeGame();
                },
                child: const Text('Resume'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  game.resetLevel();
                  game.resumeGame();
                },
                child: const Text('Restart Level'),
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../game/crayon_game.dart';
import '../../state/app_state.dart';

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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Level ${appState.selectedLevelId}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                ValueListenableBuilder<int>(
                  valueListenable: game.movesNotifier,
                  builder: (context, value, _) {
                    return Text('Moves: $value');
                  },
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () {
                    appState.toggleSound();
                  },
                  icon: Icon(appState.soundEnabled ? Icons.volume_up : Icons.volume_off),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: onPause,
                  child: const Text('Pause'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

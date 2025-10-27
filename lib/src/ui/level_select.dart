import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/level_model.dart';
import '../state/app_state.dart';

class LevelSelectScreen extends StatelessWidget {
  const LevelSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Level')),
      body: FutureBuilder<LevelBundle>(
        future: LevelBundle.loadDefault(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final bundle = snapshot.data!;
          return Consumer<AppState>(
            builder: (context, appState, _) {
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: bundle.levels.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final level = bundle.levels[index];
                  final unlocked = appState.unlockedLevels.contains(level.id);
                  final stars = appState.levelStars[level.id] ?? 0;
                  return ListTile(
                    tileColor: unlocked ? Colors.white : Colors.grey.shade200,
                    title: Text(level.title),
                    subtitle: Text('Capacity: ${level.tubeCapacity}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < 3; i++)
                          Icon(
                            i < stars ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                          ),
                        const SizedBox(width: 8),
                        if (!unlocked)
                          const Icon(Icons.lock, color: Colors.grey),
                      ],
                    ),
                    onTap: unlocked
                        ? () {
                            context.read<AppState>().selectLevel(level.id);
                            Navigator.of(context).pop(level);
                          }
                        : null,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

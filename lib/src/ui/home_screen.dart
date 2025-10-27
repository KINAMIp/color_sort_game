import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/level_model.dart';
import '../state/app_state.dart';
import 'game_screen.dart';
import 'level_select.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return FutureBuilder<void>(
      future: appState.initialize(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return Scaffold(
          appBar: AppBar(title: const Text('Crayon')),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back!',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    final level = await LevelBundle.loadLevel(appState.selectedLevelId);
                    if (!context.mounted) return;
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => GameScreen(level: level),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  child: Text('Play Level ${appState.selectedLevelId}'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () async {
                    final selected = await Navigator.of(context).push<Level>(
                      MaterialPageRoute(builder: (_) => const LevelSelectScreen()),
                    );
                    if (selected != null) {
                      context.read<AppState>().selectLevel(selected.id);
                    }
                  },
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  child: const Text('Choose Level'),
                ),
                const SizedBox(height: 24),
                SwitchListTile(
                  value: appState.soundEnabled,
                  onChanged: (_) => appState.toggleSound(),
                  title: const Text('Sound'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

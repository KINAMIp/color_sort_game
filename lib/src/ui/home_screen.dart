import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/level_model.dart';
import '../state/app_state.dart';
import 'game_screen.dart';
import 'level_select.dart';
import 'widgets/animated_background.dart';
import 'widgets/animated_gradient_button.dart';
import 'widgets/animated_gradient_text.dart';
import 'widgets/sound_toggle.dart';

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
          body: AnimatedBackground(
            colors: const [Color(0xFF7CF6F3), Color(0xFF7288FF)],
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnimatedGradientText(
                                'Crayon',
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFF7BAC),
                                    Color(0xFFFFCA7A),
                                    Color(0xFF9C6BFF),
                                  ],
                                ),
                                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                      fontSize: 48,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Welcome back!',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: Colors.white.withOpacity(0.85),
                                      shadows: const [
                                        Shadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
                                      ],
                                    ),
                              ),
                            ],
                          ),
                        ),
                        GradientSoundToggle(
                          value: appState.soundEnabled,
                          onChanged: (_) => appState.toggleSound(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedGradientButton(
                              text: 'Play Level ${appState.selectedLevelId.padLeft(3, '0')}',
                              colors: const [Color(0xFFFF7BAC), Color(0xFF9C6BFF)],
                              icon: Icons.play_arrow_rounded,
                              onPressed: () async {
                                final level = await LevelBundle.loadLevel(appState.selectedLevelId);
                                if (!context.mounted) return;
                                await Navigator.of(context).push(
                                  PageRouteBuilder(
                                    pageBuilder: (_, animation, __) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: GameScreen(level: level),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 18),
                            AnimatedGradientButton(
                              text: 'Choose Level',
                              colors: const [Color(0xFF72E4A2), Color(0xFF6EC8FF)],
                              icon: Icons.auto_awesome_motion,
                              onPressed: () async {
                                final selected = await Navigator.of(context).push<Level>(
                                  PageRouteBuilder(
                                    pageBuilder: (_, animation, __) => FadeTransition(
                                      opacity: animation,
                                      child: const LevelSelectScreen(),
                                    ),
                                  ),
                                );
                                if (selected != null) {
                                  context.read<AppState>().selectLevel(selected.id);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        'Let\'s pour some color magic!',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white.withOpacity(0.8),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

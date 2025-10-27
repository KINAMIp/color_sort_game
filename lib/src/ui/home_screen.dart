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
            colors: const [Color(0xFF8EEBFF), Color(0xFF9FA8FF), Color(0xFFFFD6FF)],
            beginAlignment: Alignment.topCenter,
            endAlignment: Alignment.bottomCenter,
            opacity: 0.2,
            showWaterBalloons: true,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnimatedGradientText(
                                'Splash & Sort',
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF4CC9F0),
                                    Color(0xFF4361EE),
                                    Color(0xFFF72585),
                                  ],
                                ),
                                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                      fontSize: 52,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.2,
                                    ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Pour shimmering watercolors into glowing glasses across 300 whimsical levels.',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: Colors.white.withOpacity(0.86),
                                      height: 1.3,
                                      shadows: const [
                                        Shadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
                                      ],
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        GradientSoundToggle(
                          value: appState.soundEnabled,
                          onChanged: (_) => appState.toggleSound(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 36),
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedGradientButton(
                              text: 'Continue Level ${appState.selectedLevelId.padLeft(3, '0')}',
                              colors: const [Color(0xFFF72585), Color(0xFF7209B7)],
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
                            const SizedBox(height: 20),
                            AnimatedGradientButton(
                              text: 'Level Select',
                              colors: const [Color(0xFF4CC9F0), Color(0xFF3A86FF)],
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
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.18),
                              blurRadius: 18,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          child: Text(
                            'New glass shapes unlock every 10 levels!',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
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

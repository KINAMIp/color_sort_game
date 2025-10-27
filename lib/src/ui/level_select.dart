import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/level_model.dart';
import '../state/app_state.dart';
import 'widgets/animated_background.dart';
import 'widgets/animated_gradient_button.dart';
import 'widgets/animated_gradient_text.dart';
import 'widgets/glass_card.dart';

class LevelSelectScreen extends StatelessWidget {
  const LevelSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        colors: const [Color(0xFF7DE8FF), Color(0xFF8FA8FF), Color(0xFFFFD4FF)],
        beginAlignment: Alignment.topCenter,
        endAlignment: Alignment.bottomCenter,
        opacity: 0.2,
        showWaterBalloons: true,
        child: SafeArea(
          child: FutureBuilder<LevelBundle>(
            future: LevelBundle.loadDefault(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final bundle = snapshot.data!;
              return Consumer<AppState>(
                builder: (context, appState, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: AnimatedGradientText(
                                'Choose Your Adventure',
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF7CF6F3), Color(0xFF7288FF), Color(0xFFFFCA7A)],
                                ),
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 18,
                            crossAxisSpacing: 18,
                            childAspectRatio: 1,
                          ),
                          itemCount: bundle.levels.length,
                          itemBuilder: (context, index) {
                            final level = bundle.levels[index];
                            final unlocked = appState.unlockedLevels.contains(level.id);
                            final stars = appState.levelStars[level.id] ?? 0;
                            final colors = unlocked
                                ? const [Color(0xFF72E4A2), Color(0xFF6EC8FF)]
                                : const [Color(0xFFBDBDBD), Color(0xFF9E9E9E)];
                            return AnimatedOpacity(
                              duration: const Duration(milliseconds: 300),
                              opacity: unlocked ? 1 : 0.65,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(28),
                                onTap: unlocked
                                    ? () {
                                        context.read<AppState>().selectLevel(level.id);
                                        Navigator.of(context).pop(level);
                                      }
                                    : null,
                                child: GlassCard(
                                  borderRadius: 28,
                                  color: Colors.white.withOpacity(0.18),
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(colors: colors),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            level.title,
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.white,
                                                ),
                                          ),
                                          const Spacer(),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: List.generate(3, (i) {
                                                  return Padding(
                                                    padding: const EdgeInsets.only(right: 4),
                                                    child: Icon(
                                                      Icons.star_rounded,
                                                      color: i < stars
                                                          ? Colors.amberAccent
                                                          : Colors.white.withOpacity(0.4),
                                                      size: 22,
                                                    ),
                                                  );
                                                }),
                                              ),
                                              AnimatedGradientButton(
                                                text: unlocked ? 'Play' : 'Locked',
                                                colors: unlocked
                                                    ? const [Color(0xFFFF7BAC), Color(0xFF9C6BFF)]
                                                    : const [Color(0xFFBDBDBD), Color(0xFF9E9E9E)],
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 12,
                                                ),
                                                onPressed: unlocked
                                                    ? () {
                                                        context.read<AppState>().selectLevel(level.id);
                                                        Navigator.of(context).pop(level);
                                                      }
                                                    : null,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

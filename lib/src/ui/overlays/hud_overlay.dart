import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../game/crayon_game.dart';
import '../../state/app_state.dart';
import '../widgets/animated_gradient_button.dart';

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
    return SizedBox.expand(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _LevelCard(game: game, levelId: appState.selectedLevelId)),
                  const SizedBox(width: 16),
                  _ControlsCard(
                    soundEnabled: appState.soundEnabled,
                    onToggleSound: () => appState.toggleSound(),
                    onPause: onPause,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.game, required this.levelId});

  final CrayonGame game;
  final String levelId;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: const [Color(0xFF9AE7FF), Color(0xFF8C9EFF), Color(0xFFF9A8FF)],
          stops: const [0.0, 0.55, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7288FF).withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            game.level.title.isNotEmpty ? game.level.title : 'Level $levelId',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
          ),
          const SizedBox(height: 14),
          ValueListenableBuilder<int>(
            valueListenable: game.movesNotifier,
            builder: (context, value, _) {
              final hasLimit = game.hasMoveLimit;
              final remaining = hasLimit ? value : game.movesMade;
              final label = hasLimit ? 'Moves left' : 'Moves used';
              return Row(
                children: [
                  _MovesBubble(
                    remaining: remaining,
                    hasLimit: hasLimit,
                    total: game.movesLimit,
                    progress: game.movesProgress,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label.toUpperCase(),
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: Colors.white.withOpacity(0.82),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          hasLimit ? '$remaining of ${game.movesLimit}' : '${game.movesMade}',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MovesBubble extends StatelessWidget {
  const _MovesBubble({
    required this.remaining,
    required this.hasLimit,
    required this.total,
    required this.progress,
  });

  final int remaining;
  final bool hasLimit;
  final int total;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    return TweenAnimationBuilder<double>(
      key: ValueKey(clamped),
      tween: Tween<double>(begin: 0, end: clamped),
      duration: const Duration(milliseconds: 320),
      builder: (context, animatedValue, child) {
        return Container(
          width: 76,
          height: 76,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x881E3A8A),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                painter: _MovesRingPainter(progress: animatedValue),
                child: const SizedBox.expand(),
              ),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFB9F2FF), Color(0xFF6EC8FF)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  hasLimit ? '$remaining' : '∞',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: const Color(0xFF0F172A),
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              if (hasLimit)
                Positioned(
                  bottom: 6,
                  child: Text(
                    '${(animatedValue * 100).clamp(0, 100).round()}%',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _MovesRingPainter extends CustomPainter {
  const _MovesRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final gradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: 1.5 * math.pi,
      colors: const [Color(0xFF4CC9F0), Color(0xFF4361EE), Color(0xFF4CC9F0)],
      stops: const [0.0, 0.7, 1.0],
      transform: const GradientRotation(-math.pi / 2),
    );

    final backgroundPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = Colors.white.withOpacity(0.2);

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 6
      ..shader = gradient.createShader(rect);

    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 4;
    canvas.drawCircle(center, radius, backgroundPaint);
    final sweep = (progress.clamp(0.0, 1.0)) * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MovesRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _ControlsCard extends StatelessWidget {
  const _ControlsCard({
    required this.soundEnabled,
    required this.onToggleSound,
    required this.onPause,
  });

  final bool soundEnabled;
  final VoidCallback onToggleSound;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: Colors.black.withOpacity(0.22),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: onToggleSound,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: soundEnabled
                        ? const [Color(0xFF7CF6F3), Color(0xFF7288FF)]
                        : const [Color(0xFFFFA6C1), Color(0xFFFFC778)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  soundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            AnimatedGradientButton(
              text: 'Pause',
              colors: const [Color(0xFF84F3FF), Color(0xFF6E8CFF)],
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              onPressed: onPause,
            ),
          ],
        ),
      ),
    );
  }
}

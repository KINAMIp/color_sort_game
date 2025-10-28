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
    return SizedBox.expand(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CircularControlButton(
                    icon: Icons.pause_rounded,
                    label: 'Pause',
                    onPressed: onPause,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _LevelBadge(
                          levelId: appState.selectedLevelId,
                          title: game.level.title,
                        ),
                        const SizedBox(height: 12),
                        ValueListenableBuilder<int>(
                          valueListenable: game.movesNotifier,
                          builder: (context, value, _) {
                            return _MovesChip(
                              hasLimit: game.hasMoveLimit,
                              value: value,
                              total: game.movesLimit,
                              movesMade: game.movesMade,
                              progress: game.hasMoveLimit ? game.movesProgress : 1.0,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _CircularControlButton(
                        icon: appState.soundEnabled
                            ? Icons.volume_up_rounded
                            : Icons.volume_off_rounded,
                        label: appState.soundEnabled ? 'Sound on' : 'Sound off',
                        onPressed: () => appState.toggleSound(),
                        gradient: const [Color(0xFF3C3B8E), Color(0xFF6454F0)],
                      ),
                      const SizedBox(height: 12),
                      _CircularControlButton(
                        icon: Icons.restart_alt_rounded,
                        label: 'Restart',
                        onPressed: () {
                          game.resetLevel();
                        },
                        gradient: const [Color(0xFF2F3344), Color(0xFF464C62)],
                      ),
                    ],
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

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.levelId, required this.title});

  final String levelId;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parsed = int.tryParse(levelId) ?? levelId;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(42),
        gradient: const LinearGradient(
          colors: [Color(0xFF161728), Color(0xFF21233E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x6617182A),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'LEVEL $parsed',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          if (title.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withOpacity(0.72),
                letterSpacing: 0.6,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MovesChip extends StatelessWidget {
  const _MovesChip({
    required this.hasLimit,
    required this.value,
    required this.total,
    required this.movesMade,
    required this.progress,
  });

  final bool hasLimit;
  final int value;
  final int total;
  final int movesMade;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (hasLimit && total > 0) {
      final clamped = progress.clamp(0.0, 1.0);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: Colors.white.withOpacity(0.06),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MOVES LEFT',
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.white.withOpacity(0.72),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  '$value',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: const Color(0xFFFFC947),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  ' / $total',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white.withOpacity(0.64),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: clamped,
                      minHeight: 6,
                      backgroundColor: Colors.white.withOpacity(0.12),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFFFC947),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.white.withOpacity(0.06),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Text(
            'MOVES USED',
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.white.withOpacity(0.7),
              letterSpacing: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$movesMade',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircularControlButton extends StatelessWidget {
  const _CircularControlButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.gradient,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final List<Color>? gradient;

  @override
  Widget build(BuildContext context) {
    final colors = gradient ?? const [Color(0xFF5F36FF), Color(0xFF8E5CFF)];
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onPressed,
          child: Ink(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66171C3C),
                  blurRadius: 18,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../game/crayon_game.dart';
import '../widgets/dark_pattern_background.dart';
import '../widgets/filled_action_button.dart';

class LevelCompleteOverlay extends StatefulWidget {
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
  State<LevelCompleteOverlay> createState() => _LevelCompleteOverlayState();
}

class _LevelCompleteOverlayState extends State<LevelCompleteOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_ConfettiPiece> _pieces;

  @override
  void initState() {
    super.initState();
    widget.game.audioService.playConfetti();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    final random = math.Random(42);
    _pieces = List.generate(48, (index) {
      return _ConfettiPiece(
        origin: Offset(random.nextDouble(), random.nextDouble()),
        speed: lerpDouble(0.18, 0.5, random.nextDouble())!,
        sway: lerpDouble(-0.15, 0.15, random.nextDouble())!,
        color: _confettiPalette[index % _confettiPalette.length],
        size: lerpDouble(6, 16, random.nextDouble())!,
        rotationSpeed: lerpDouble(-1.6, 1.6, random.nextDouble())!,
        rotationOffset: random.nextDouble() * math.pi * 2,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final levelNumber = int.tryParse(widget.game.level.id) ?? widget.game.level.id;
    final hasLimit = widget.game.hasMoveLimit;
    final headline = hasLimit
        ? 'Moves left: ${widget.game.movesRemaining}/${widget.game.movesLimit}'
        : 'Moves used: ${widget.game.movesMade}';

    return SizedBox.expand(
      child: Stack(
        children: [
          DarkPatternBackground(
            child: Container(
              color: Colors.black.withOpacity(0.58),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _ConfettiPainter(
                      progress: _controller.value,
                      pieces: _pieces,
                    ),
                  );
                },
              ),
            ),
          ),
          Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = math.min(constraints.maxWidth * 0.88, 420.0);
                return ConstrainedBox(
                  constraints: BoxConstraints.tightFor(width: width),
                  child: _VictoryCard(
                    levelLabel: 'Level $levelNumber',
                    headline: headline,
                    onNextLevel: widget.onNextLevel,
                    onReplay: () {
                      widget.game.resetLevel();
                    },
                    onExit: widget.onExit,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _VictoryCard extends StatelessWidget {
  const _VictoryCard({
    required this.levelLabel,
    required this.headline,
    required this.onNextLevel,
    required this.onReplay,
    required this.onExit,
  });

  final String levelLabel;
  final String headline;
  final VoidCallback onNextLevel;
  final VoidCallback onReplay;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      decoration: BoxDecoration(
        color: const Color(0xFF17182A).withOpacity(0.92),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x6617182A),
            blurRadius: 24,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _VictoryHeader(levelLabel: levelLabel),
          const SizedBox(height: 22),
          Text(
            'AWESOME',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            headline,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white.withOpacity(0.78),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 26),
          FilledActionButton(
            label: 'Next',
            colors: const [Color(0xFFFFD149), Color(0xFFFF9738)],
            onPressed: onNextLevel,
            textColor: const Color(0xFF1F1400),
          ),
          const SizedBox(height: 14),
          FilledActionButton(
            label: 'Replay',
            colors: const [Color(0xFF586DFF), Color(0xFF8B55FF)],
            onPressed: onReplay,
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: onExit,
            child: const Text(
              'Exit to menu',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VictoryHeader extends StatelessWidget {
  const _VictoryHeader({required this.levelLabel});

  final String levelLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 74,
          width: 74,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF3B0), Color(0xFFFFC567)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x55FFD66B),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.workspace_premium_rounded,
            color: Color(0xFF8C622B),
            size: 42,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFF4555),
            borderRadius: BorderRadius.circular(32),
            boxShadow: const [
              BoxShadow(
                color: Color(0x44FF6C7C),
                blurRadius: 20,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Text(
            levelLabel.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _ConfettiPiece {
  _ConfettiPiece({
    required this.origin,
    required this.speed,
    required this.sway,
    required this.color,
    required this.size,
    required this.rotationSpeed,
    required this.rotationOffset,
  });

  final Offset origin;
  final double speed;
  final double sway;
  final Color color;
  final double size;
  final double rotationSpeed;
  final double rotationOffset;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.progress, required this.pieces});

  final double progress;
  final List<_ConfettiPiece> pieces;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final piece in pieces) {
      final baseY = (piece.origin.dy + progress * piece.speed) % 1.0;
      final y = baseY * size.height;
      final x = (piece.origin.dx + math.sin(progress * math.pi * 2 + piece.sway) * 0.1) % 1.0;
      final position = Offset(x * size.width, y);
      final rotation = piece.rotationOffset + progress * piece.rotationSpeed * math.pi;

      paint.color = piece.color.withOpacity(0.85);
      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(rotation);
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: piece.size,
        height: piece.size * 0.4,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(piece.size * 0.18)),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.pieces != pieces;
  }
}

const _confettiPalette = [
  Color(0xFFFF6F91),
  Color(0xFFFF9671),
  Color(0xFFFFC75F),
  Color(0xFF6A7EFF),
  Color(0xFF73E2A7),
  Color(0xFF40C4FF),
];

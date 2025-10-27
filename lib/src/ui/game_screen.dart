import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/level_model.dart';
import '../game/crayon_game.dart';
import '../state/app_state.dart';
import '../utils/constants.dart';
import '../ui/overlays/hud_overlay.dart';
import '../ui/overlays/level_complete.dart';
import '../ui/overlays/pause_overlay.dart';
import 'widgets/animated_background.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.level});

  final Level level;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late Level _currentLevel;
  late CrayonGame _game;
  bool _gameInitialized = false;

  @override
  void initState() {
    super.initState();
    _currentLevel = widget.level;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_gameInitialized) {
      final appState = context.read<AppState>();
      _game = CrayonGame(
        level: _currentLevel,
        appState: appState,
        audioService: appState.audioService,
        onShowOverlay: (_) => _scheduleRebuild(),
        onHideOverlay: (_) => _scheduleRebuild(),
      );
      _gameInitialized = true;
    }
  }

  @override
  void dispose() {
    _game.pauseEngine();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        colors: const [Color(0xFF0E0A2F), Color(0xFF1E1253), Color(0xFF3A1B8A)],
        beginAlignment: Alignment.topCenter,
        endAlignment: Alignment.bottomCenter,
        opacity: 0.18,
        darkOverlay: true,
        showWaterBalloons: true,
        child: Stack(
          children: [
            GameWidget(
              key: ValueKey(_currentLevel.id),
              game: _game,
              overlayBuilderMap: {
                CrayonGame.hudOverlay: (context, game) {
                  return HudOverlay(
                    game: game as CrayonGame,
                    onPause: () => _game.pauseGame(),
                  );
                },
                CrayonGame.pauseOverlay: (context, game) {
                  return PauseOverlay(
                    game: game as CrayonGame,
                    onExit: () {
                      Navigator.of(context).pop();
                    },
                  );
                },
                CrayonGame.levelCompleteOverlay: (context, game) {
                  return LevelCompleteOverlay(
                    game: game as CrayonGame,
                    onNextLevel: _advanceToNextLevel,
                    onExit: () {
                      Navigator.of(context).pop();
                    },
                  );
                },
              },
            ),
            Positioned(
              top: 32,
              left: 18,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF9AE7FF), Color(0xFF7288FF)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 14,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.arrow_back_rounded, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          'Menu',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _advanceToNextLevel() async {
    final ids = LevelSets.defaultLevelIds;
    final currentIndex = ids.indexOf(_currentLevel.id);
    if (currentIndex >= 0 && currentIndex < ids.length - 1) {
      final nextLevelId = ids[currentIndex + 1];
      final nextLevel = await LevelBundle.loadLevel(nextLevelId);
      if (!mounted) {
        return;
      }
      final appState = context.read<AppState>();
      appState.selectLevel(nextLevel.id);
      setState(() {
        _currentLevel = nextLevel;
        _game = CrayonGame(
          level: _currentLevel,
          appState: appState,
          audioService: appState.audioService,
          onShowOverlay: (_) => _scheduleRebuild(),
          onHideOverlay: (_) => _scheduleRebuild(),
        );
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  void _scheduleRebuild() {
    if (!mounted) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }
}

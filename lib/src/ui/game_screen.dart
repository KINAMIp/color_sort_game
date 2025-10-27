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
        onShowOverlay: (_) => setState(() {}),
        onHideOverlay: (_) => setState(() {}),
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
      body: Stack(
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
            top: 40,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
        ],
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
          onShowOverlay: (_) => setState(() {}),
          onHideOverlay: (_) => setState(() {}),
        );
      });
    } else {
      Navigator.of(context).pop();
    }
  }
}

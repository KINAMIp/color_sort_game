import 'package:audioplayers/audioplayers.dart';
import 'package:flame_audio/flame_audio.dart';

import '../utils/constants.dart';

class AudioService {
  bool _muted = false;
  bool _initialized = false;
  bool _ambientRequested = false;
  bool _ambientPlaying = false;
  bool _buttonSplashAvailable = false;
  bool _confettiAvailable = false;
  bool _outOfMovesAvailable = false;
  bool _ambientAvailable = false;
  AudioPlayer? _ambientPlayer;
  DateTime? _lastHoverSound;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    try {
      FlameAudio.audioCache.prefix = 'assets/audio/';
      await FlameAudio.audioCache.loadAll(const [
        AssetPaths.audioPour,
        AssetPaths.audioInvalid,
        AssetPaths.audioWin,
      ]);
      _buttonSplashAvailable = await _tryLoadOptional(AssetPaths.audioButtonSplash);
      _confettiAvailable = await _tryLoadOptional(AssetPaths.audioConfetti);
      _outOfMovesAvailable = await _tryLoadOptional(AssetPaths.audioOutOfMoves);
      _ambientAvailable = await _tryLoadOptional(AssetPaths.audioAmbient);
      _initialized = true;
    } catch (_) {
      // Audio is optional; failures should not block the game from starting.
      _initialized = false;
    }
  }

  void setMuted(bool value) {
    _muted = value;
    if (_muted) {
      _stopAmbientLoop();
    } else if (_ambientRequested) {
      _startAmbientLoop();
    }
  }

  void playPour() {
    if (_muted || !_initialized) {
      return;
    }
    FlameAudio.play(AssetPaths.audioPour, volume: 0.6);
  }

  void playInvalid() {
    if (_muted || !_initialized) {
      return;
    }
    FlameAudio.play(AssetPaths.audioInvalid, volume: 0.5);
  }

  void playWin() {
    if (_muted || !_initialized) {
      return;
    }
    FlameAudio.play(AssetPaths.audioWin, volume: 0.8);
  }

  void playConfetti() {
    if (_muted || !_initialized) {
      return;
    }
    if (_confettiAvailable) {
      FlameAudio.play(AssetPaths.audioConfetti, volume: 0.7);
    } else {
      FlameAudio.play(AssetPaths.audioWin, volume: 0.5);
    }
  }

  void playButtonHover() {
    if (_muted || !_initialized) {
      return;
    }
    final now = DateTime.now();
    if (_lastHoverSound != null && now.difference(_lastHoverSound!).inMilliseconds < 140) {
      return;
    }
    _lastHoverSound = now;
    if (_buttonSplashAvailable) {
      FlameAudio.play(AssetPaths.audioButtonSplash, volume: 0.24);
    } else {
      FlameAudio.play(AssetPaths.audioPour, volume: 0.16);
    }
  }

  void playButtonTap() {
    if (_muted || !_initialized) {
      return;
    }
    if (_buttonSplashAvailable) {
      FlameAudio.play(AssetPaths.audioButtonSplash, volume: 0.4);
    } else {
      FlameAudio.play(AssetPaths.audioPour, volume: 0.22);
    }
  }

  void playOutOfMoves() {
    if (_muted || !_initialized) {
      return;
    }
    if (_outOfMovesAvailable) {
      FlameAudio.play(AssetPaths.audioOutOfMoves, volume: 0.5);
    } else {
      playInvalid();
    }
  }

  Future<void> enableAmbientLoop() async {
    _ambientRequested = true;
    await _startAmbientLoop();
  }

  Future<void> disableAmbientLoop() async {
    _ambientRequested = false;
    await _stopAmbientLoop();
  }

  Future<void> _startAmbientLoop() async {
    if (_ambientPlaying || _muted || !_initialized || !_ambientAvailable) {
      return;
    }
    try {
      _ambientPlayer = await FlameAudio.loopLongAudio(
        AssetPaths.audioAmbient,
        volume: 0.28,
      );
      _ambientPlaying = true;
    } catch (_) {
      _ambientPlaying = false;
      _ambientPlayer = null;
    }
  }

  Future<void> _stopAmbientLoop() async {
    if (!_ambientPlaying) {
      return;
    }
    try {
      await _ambientPlayer?.stop();
      await _ambientPlayer?.release();
    } catch (_) {
      // ignore cleanup failures
    }
    _ambientPlayer = null;
    _ambientPlaying = false;
  }

  Future<bool> _tryLoadOptional(String asset) async {
    try {
      await FlameAudio.audioCache
          .load(asset)
          .timeout(const Duration(seconds: 2));
      return true;
    } catch (_) {
      return false;
    }
  }
}

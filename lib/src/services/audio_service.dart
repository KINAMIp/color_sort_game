import 'dart:async';
import 'dart:ui';

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
      final availability = <String, bool>{};
      for (final asset in AssetPaths.allAudioAssets) {
        availability[asset] = await _loadAudioAsset(asset);
      }
      final coreAssets = [
        AssetPaths.audioPour,
        AssetPaths.audioInvalid,
        AssetPaths.audioWin,
      ];
      final hasCoreAssets =
          coreAssets.every((asset) => availability[asset] ?? false);
      if (!hasCoreAssets) {
        _initialized = false;
        return;
      }
      _buttonSplashAvailable = availability[AssetPaths.audioButtonSplash] ?? false;
      _confettiAvailable = availability[AssetPaths.audioConfetti] ?? false;
      _outOfMovesAvailable = availability[AssetPaths.audioOutOfMoves] ?? false;
      _ambientAvailable = availability[AssetPaths.audioAmbient] ?? false;
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

  Future<void> playPourDynamic({
    double intensity = 0.6,
    double viscosity = 0.5,
  }) async {
    if (_muted || !_initialized) {
      return;
    }
    final clampedIntensity = intensity.clamp(0.0, 1.0);
    final clampedViscosity = viscosity.clamp(0.1, 1.0);
    final baseVolume = lerpDouble(0.32, 0.82, clampedIntensity)!;
    final viscosityAttenuation = lerpDouble(1.1, 0.7, clampedViscosity)!;
    final volume = (baseVolume * viscosityAttenuation).clamp(0.2, 1.0);
    final playbackRate = lerpDouble(1.18, 0.74, clampedViscosity)!;
    try {
      final player = await FlameAudio.play(AssetPaths.audioPour, volume: volume);
      await player.setPlaybackRate(playbackRate);
    } catch (_) {
      // Fall back to the default behaviour if the audio backend does not
      // support playback rate changes on the current platform.
      await FlameAudio.play(AssetPaths.audioPour, volume: volume);
    }
  }

  void playPour({
    double intensity = 0.6,
    double viscosity = 0.5,
  }) {
    unawaited(playPourDynamic(intensity: intensity, viscosity: viscosity));
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

  Future<bool> _loadAudioAsset(String asset) async {
    try {
      await FlameAudio.audioCache
          .load(asset)
          .timeout(const Duration(seconds: 4));
      return true;
    } catch (_) {
      return false;
    }
  }
}

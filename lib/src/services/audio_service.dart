import 'package:flame_audio/flame_audio.dart';

import '../utils/constants.dart';

class AudioService {
  bool _muted = false;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    try {
      await FlameAudio.audioCache.loadAll(const [
        AssetPaths.audioPour,
        AssetPaths.audioInvalid,
        AssetPaths.audioWin,
      ]);
      _initialized = true;
    } catch (_) {
      // Audio is optional; failures should not block the game from starting.
      _initialized = false;
    }
  }

  void setMuted(bool value) {
    _muted = value;
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
}

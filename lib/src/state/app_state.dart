import 'package:flutter/foundation.dart';

import '../services/audio_service.dart';
import '../services/firebase_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

class AppState extends ChangeNotifier {
  AppState({
    required this.storageService,
    required this.audioService,
    required this.firebaseService,
  });

  final StorageService storageService;
  final AudioService audioService;
  final FirebaseService firebaseService;

  bool initialized = false;
  bool soundEnabled = true;
  String selectedLevelId = LevelSets.defaultLevelIds.first;
  Set<String> unlockedLevels = {LevelSets.defaultLevelIds.first};
  Map<String, int> levelStars = <String, int>{};
  String? userId;

  Future<void> initialize() async {
    if (initialized) {
      return;
    }
    soundEnabled = await storageService.loadSoundEnabled();
    unlockedLevels = await storageService.loadUnlockedLevels();
    await audioService.initialize();
    audioService.setMuted(!soundEnabled);
    await firebaseService.initialize();
    if (firebaseService.isAvailable) {
      final credential = await firebaseService.signInAnonymously();
      userId = credential?.user?.uid;
    }
    initialized = true;
    notifyListeners();
  }

  void selectLevel(String levelId) {
    selectedLevelId = levelId;
    notifyListeners();
  }

  Future<void> toggleSound() async {
    soundEnabled = !soundEnabled;
    audioService.setMuted(!soundEnabled);
    await storageService.saveSoundEnabled(soundEnabled);
    notifyListeners();
  }

  Future<void> markLevelComplete(String levelId, int stars) async {
    levelStars[levelId] = stars;
    unlockedLevels.add(levelId);
    final index = LevelSets.defaultLevelIds.indexOf(levelId);
    if (index >= 0 && index < LevelSets.defaultLevelIds.length - 1) {
      unlockedLevels.add(LevelSets.defaultLevelIds[index + 1]);
    }
    await storageService.saveUnlockedLevels(unlockedLevels);
    if (userId != null) {
      await firebaseService.saveProgress(
        userId: userId!,
        levelId: levelId,
        stars: stars,
      );
    }
    notifyListeners();
  }
}

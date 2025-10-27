import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _unlockedKey = 'unlocked_levels';
  static const _soundKey = 'sound_enabled';

  Future<Set<String>> loadUnlockedLevels() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_unlockedKey);
    return list?.toSet() ?? <String>{'001'};
  }

  Future<void> saveUnlockedLevels(Set<String> levels) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_unlockedKey, levels.toList());
  }

  Future<bool> loadSoundEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_soundKey) ?? true;
  }

  Future<void> saveSoundEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundKey, enabled);
  }
}

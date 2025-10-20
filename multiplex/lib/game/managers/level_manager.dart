import 'package:get/get.dart';
import '../models/level.dart';

class LevelManager {
  LevelsData? _levelsData;
  int _currentLevelIndex = 0;

  // Reactive level index for UI updates
  final RxInt currentLevelIndexRx = 0.obs;

  LevelManager();

  Future<void> loadLevels() async {
    _levelsData = await LevelsData.loadFromAssets();
  }

  Level? get currentLevel {
    if (_levelsData == null || _currentLevelIndex >= _levelsData!.levels.length) {
      return null;
    }
    return _levelsData!.levels[_currentLevelIndex];
  }

  void nextLevel() {
    if (_levelsData != null && _currentLevelIndex < _levelsData!.levels.length - 1) {
      _currentLevelIndex++;
      currentLevelIndexRx.value = _currentLevelIndex;
    }
  }

  void resetLevel() {
    _currentLevelIndex = 0;
    currentLevelIndexRx.value = _currentLevelIndex;
  }

  void startNewGame() {
    _currentLevelIndex = 0;
    currentLevelIndexRx.value = _currentLevelIndex;
  }

  /// Set the current level by level number (1-indexed)
  void setLevel(int levelNumber) {
    final levelIndex = levelNumber - 1; // Convert to 0-indexed

    if (_levelsData != null && levelIndex >= 0 && levelIndex < _levelsData!.levels.length) {
      _currentLevelIndex = levelIndex;
      currentLevelIndexRx.value = _currentLevelIndex;
    }
  }

  bool get hasMoreLevels {
    if (_levelsData == null) return false;
    return _currentLevelIndex < _levelsData!.levels.length - 1;
  }

  int get totalLevels => _levelsData?.levels.length ?? 0;

  int get currentLevelNumber => _currentLevelIndex + 1;
}

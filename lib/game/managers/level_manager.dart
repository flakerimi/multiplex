import '../models/level.dart';

class LevelManager {
  LevelsData? _levelsData;
  int _currentLevelIndex = 0;

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
    }
  }

  void resetLevel() {
    _currentLevelIndex = 0;
  }

  void startNewGame() {
    _currentLevelIndex = 0;
  }

  bool get hasMoreLevels {
    if (_levelsData == null) return false;
    return _currentLevelIndex < _levelsData!.levels.length - 1;
  }

  int get totalLevels => _levelsData?.levels.length ?? 0;

  int get currentLevelNumber => _currentLevelIndex + 1;
}

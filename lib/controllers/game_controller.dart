import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:games_api/games_api.dart';
import 'package:get_storage/get_storage.dart';
import '../services/achievement_tracker.dart';
import '../services/notification_service.dart';

class GameController extends GetxController {
  final GamesApiClient api = GamesApiClient.development();
  final GetStorage storage = GetStorage();

  static const String gameSlug = 'multiplex';
  static const String localStorageKey = 'multiplex_local_progress';

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final Rx<Map<String, dynamic>?> currentProgress = Rx<Map<String, dynamic>?>(null);

  // Achievement tracking
  late final AchievementTracker achievementTracker;
  final NotificationService notificationService = NotificationService();
  bool _achievementsInitialized = false;

  // Auto-save timer
  Timer? _autoSaveTimer;
  bool _autoSaveEnabled = false;

  // Background sync
  bool _hasPendingSync = false;
  Timer? _syncTimer;

  // Game stats tracking
  final RxInt currentLevel = 1.obs;
  final RxInt totalScore = 0.obs;
  final RxInt tilesProcessed = 0.obs;
  final RxInt beltsPlaced = 0.obs;
  final RxInt operatorsPlaced = 0.obs;
  final RxInt extractorsPlaced = 0.obs;
  final RxInt levelsCompleted = 0.obs;
  final RxInt totalPlaytimeSeconds = 0.obs;
  final Rx<DateTime?> lastPlayed = Rx<DateTime?>(null);

  @override
  void onInit() {
    super.onInit();

    // Initialize achievement tracker
    achievementTracker = AchievementTracker(
      api: api,
      gameSlug: gameSlug,
      notificationService: notificationService,
    );
  }

  @override
  void onClose() {
    stopAutoSave();
    _stopBackgroundSync();
    achievementTracker.dispose();
    super.onClose();
  }

  /// Initialize achievements (load from API)
  Future<void> initializeAchievements() async {
    if (_achievementsInitialized) {
      return;
    }

    try {
      await achievementTracker.loadAchievements();
      _achievementsInitialized = true;
      debugPrint('GameController: Achievements initialized');
    } catch (e) {
      debugPrint('GameController: Failed to initialize achievements: $e');
      // Don't throw - game can still function without achievements
    }
  }

  /// Load game progress from API or local storage
  Future<Map<String, dynamic>?> loadProgress() async {
    isLoading.value = true;
    try {
      // Try to load from API first
      final progress = await api.games.getProgress(gameSlug);
      if (progress.hasProgress) {
        final data = progress.progressData;
        _updateStatsFromProgress(data);
        currentProgress.value = data;

        // Save to local storage as backup
        await storage.write(localStorageKey, jsonEncode(data));

        return data;
      }
    } catch (e) {
      debugPrint('Failed to load progress from API: $e');

      // Try to load from local storage as fallback
      try {
        final localData = storage.read(localStorageKey);
        if (localData != null) {
          final data = jsonDecode(localData) as Map<String, dynamic>;
          _updateStatsFromProgress(data);
          currentProgress.value = data;

          Get.snackbar(
            'Offline Mode',
            'Loaded from local storage. Will sync when online.',
            snackPosition: SnackPosition.BOTTOM,
          );

          return data;
        }
      } catch (localError) {
        debugPrint('Failed to load from local storage: $localError');
      }
    } finally {
      isLoading.value = false;
    }

    return null;
  }

  /// Save game progress locally and schedule background sync
  Future<bool> saveProgress({bool silent = false}) async {
    try {
      final progressData = _buildProgressData();

      // Save to local storage immediately (fast, always succeeds)
      await storage.write(localStorageKey, jsonEncode(progressData));
      currentProgress.value = progressData;

      // Schedule background sync to API
      _hasPendingSync = true;
      _scheduleBackgroundSync();

      if (!silent) {
        debugPrint('Progress saved locally');
      }

      return true;
    } catch (e) {
      debugPrint('Failed to save progress locally: $e');

      if (!silent) {
        Get.snackbar(
          'Save Failed',
          'Failed to save progress: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
        );
      }

      return false;
    }
  }

  /// Reset progress and start fresh
  Future<void> resetProgress() async {
    currentLevel.value = 1;
    totalScore.value = 0;
    tilesProcessed.value = 0;
    beltsPlaced.value = 0;
    operatorsPlaced.value = 0;
    extractorsPlaced.value = 0;
    levelsCompleted.value = 0;
    totalPlaytimeSeconds.value = 0;
    lastPlayed.value = null;
    currentProgress.value = null;

    // Clear local storage
    await storage.remove(localStorageKey);

    // Clear remote progress by saving empty data
    try {
      await api.games.saveProgress(gameSlug, {});
    } catch (e) {
      debugPrint('Failed to clear remote progress: $e');
    }
  }

  /// Start auto-save timer (saves every 30 seconds)
  void startAutoSave() {
    if (_autoSaveEnabled) {
      debugPrint('Auto-save already enabled');
      return;
    }

    _autoSaveEnabled = true;
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_autoSaveEnabled) {
        debugPrint('Auto-saving game progress...');
        saveProgress(silent: true);
      }
    });

    debugPrint('Auto-save started (every 30 seconds)');
  }

  /// Stop auto-save timer
  void stopAutoSave() {
    _autoSaveEnabled = false;
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
    debugPrint('Auto-save stopped');
  }

  /// Update stats from loaded progress data
  void _updateStatsFromProgress(Map<String, dynamic> data) {
    currentLevel.value = data['currentLevel'] ?? 1;
    totalScore.value = data['totalScore'] ?? 0;
    tilesProcessed.value = data['tilesProcessed'] ?? 0;
    beltsPlaced.value = data['beltsPlaced'] ?? 0;
    operatorsPlaced.value = data['operatorsPlaced'] ?? 0;
    extractorsPlaced.value = data['extractorsPlaced'] ?? 0;
    levelsCompleted.value = data['levelsCompleted'] ?? 0;
    totalPlaytimeSeconds.value = data['totalPlaytimeSeconds'] ?? 0;

    if (data['lastPlayed'] != null) {
      try {
        lastPlayed.value = DateTime.parse(data['lastPlayed']);
      } catch (e) {
        debugPrint('Failed to parse lastPlayed date: $e');
      }
    }
  }

  /// Build progress data object from current stats
  Map<String, dynamic> _buildProgressData() {
    return {
      'currentLevel': currentLevel.value,
      'totalScore': totalScore.value,
      'tilesProcessed': tilesProcessed.value,
      'beltsPlaced': beltsPlaced.value,
      'operatorsPlaced': operatorsPlaced.value,
      'extractorsPlaced': extractorsPlaced.value,
      'levelsCompleted': levelsCompleted.value,
      'totalPlaytimeSeconds': totalPlaytimeSeconds.value,
      'lastPlayed': DateTime.now().toIso8601String(),
    };
  }

  /// Update stats from game state
  void updateStats({
    int? currentLevel,
    int? totalScore,
    int? tilesProcessed,
    int? beltsPlaced,
    int? operatorsPlaced,
    int? extractorsPlaced,
    int? levelsCompleted,
    int? totalPlaytimeSeconds,
  }) {
    if (currentLevel != null) this.currentLevel.value = currentLevel;
    if (totalScore != null) this.totalScore.value = totalScore;
    if (tilesProcessed != null) this.tilesProcessed.value = tilesProcessed;
    if (beltsPlaced != null) this.beltsPlaced.value = beltsPlaced;
    if (operatorsPlaced != null) this.operatorsPlaced.value = operatorsPlaced;
    if (extractorsPlaced != null) this.extractorsPlaced.value = extractorsPlaced;
    if (levelsCompleted != null) this.levelsCompleted.value = levelsCompleted;
    if (totalPlaytimeSeconds != null) this.totalPlaytimeSeconds.value = totalPlaytimeSeconds;

    lastPlayed.value = DateTime.now();
  }

  /// Increment stats
  void incrementStat(String stat, [int amount = 1]) {
    switch (stat) {
      case 'tilesProcessed':
        tilesProcessed.value += amount;
        break;
      case 'beltsPlaced':
        beltsPlaced.value += amount;
        break;
      case 'operatorsPlaced':
        operatorsPlaced.value += amount;
        break;
      case 'extractorsPlaced':
        extractorsPlaced.value += amount;
        break;
      case 'levelsCompleted':
        levelsCompleted.value += amount;
        break;
      case 'totalScore':
        totalScore.value += amount;
        break;
    }
  }

  /// Increment playtime by seconds
  void addPlaytime(int seconds) {
    totalPlaytimeSeconds.value += seconds;
  }

  /// Get current stats as a map (for achievement checking and API updates)
  Map<String, dynamic> getCurrentStats() {
    return {
      'total_score': totalScore.value,
      'tiles_processed': tilesProcessed.value,
      'belts_placed': beltsPlaced.value,
      'operators_placed': operatorsPlaced.value,
      'extractors_placed': extractorsPlaced.value,
      'levels_completed': levelsCompleted.value,
      'total_playtime_seconds': totalPlaytimeSeconds.value,
      'max_level': currentLevel.value,
    };
  }

  /// Check achievements after a stat update
  Future<void> checkAchievements() async {
    if (!_achievementsInitialized) {
      return;
    }

    try {
      final currentStats = getCurrentStats();
      final unlockedAchievements = await achievementTracker.checkAchievements(currentStats);

      if (unlockedAchievements.isNotEmpty) {
        debugPrint('GameController: Unlocked ${unlockedAchievements.length} achievement(s)');

        // Sync stats to API after unlocking achievements
        await syncStatsToAPI();
      }
    } catch (e) {
      debugPrint('GameController: Error checking achievements: $e');
      // Don't throw - game continues even if achievement check fails
    }
  }

  /// Sync current stats to the API
  Future<void> syncStatsToAPI() async {
    try {
      final statsData = getCurrentStats();
      await api.games.updateStats(gameSlug, statsData);
      debugPrint('GameController: Stats synced to API');
    } catch (e) {
      debugPrint('GameController: Failed to sync stats to API: $e');
      // Don't throw - game continues even if sync fails
    }
  }

  /// Update stats from game and check achievements
  /// This should be called after every significant stat change
  Future<void> updateStatsAndCheck({
    int? currentLevel,
    int? totalScore,
    int? tilesProcessed,
    int? beltsPlaced,
    int? operatorsPlaced,
    int? extractorsPlaced,
    int? levelsCompleted,
    int? totalPlaytimeSeconds,
  }) async {
    // Update stats first
    updateStats(
      currentLevel: currentLevel,
      totalScore: totalScore,
      tilesProcessed: tilesProcessed,
      beltsPlaced: beltsPlaced,
      operatorsPlaced: operatorsPlaced,
      extractorsPlaced: extractorsPlaced,
      levelsCompleted: levelsCompleted,
      totalPlaytimeSeconds: totalPlaytimeSeconds,
    );

    // Check achievements after update
    await checkAchievements();
  }

  /// Increment stat and check achievements
  Future<void> incrementStatAndCheck(String stat, [int amount = 1]) async {
    incrementStat(stat, amount);
    await checkAchievements();
  }

  /// Schedule background sync to run soon
  void _scheduleBackgroundSync() {
    // Cancel existing timer
    _syncTimer?.cancel();

    // Sync after 2 seconds of inactivity
    _syncTimer = Timer(const Duration(seconds: 2), () {
      _performBackgroundSync();
    });
  }

  /// Perform background sync to API
  Future<void> _performBackgroundSync() async {
    if (!_hasPendingSync || currentProgress.value == null) {
      return;
    }

    try {
      debugPrint('Syncing progress to API...');
      await api.games.saveProgress(gameSlug, currentProgress.value!);
      _hasPendingSync = false;
      debugPrint('Progress synced to API successfully');
    } catch (e) {
      debugPrint('Failed to sync to API: $e');
      // Will retry on next save or auto-save
    }
  }

  /// Stop background sync timer
  void _stopBackgroundSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }
}
